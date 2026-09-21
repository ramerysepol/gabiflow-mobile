import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/env_config.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';

/// Interceptor de autenticação com auto-refresh de token.
///
/// - onRequest: injeta Bearer token + headers de tenant (X-Tenant-ID/Origin).
/// - 401: tenta renovar via POST /api/mobile/auth/refresh (single-flight —
///   várias requisições simultâneas compartilham a mesma renovação) e refaz
///   a requisição original com o novo token.
/// - Refresh falhou: limpa a sessão; o 401 segue adiante e o app deve
///   redirecionar para o login.
///
/// Atenção: o ApiClient usa validateStatus < 500, então um 401 chega como
/// RESPOSTA normal (onResponse), não como erro — por isso o tratamento
/// precisa existir nos dois callbacks.
class AuthInterceptor extends Interceptor {
  /// Single-flight: renovação em andamento compartilhada entre requisições.
  static Future<_RefreshResult>? _refreshInFlight;

  /// Avisa o app quando a sessão foi encerrada por refresh NEGADO (token
  /// expirado/revogado). Quem escuta (GabiFlowApp) leva o usuário ao login —
  /// antes disso o app ficava "logado" com sessão morta e toda tela mostrava
  /// erro de conexão (visto na central de atendimento após tempo parado).
  static final _sessaoExpiradaCtrl = StreamController<void>.broadcast();
  static Stream<void> get onSessaoExpirada => _sessaoExpiradaCtrl.stream;

  static void _avisarSessaoExpirada() {
    SessaoExpiradaAviso.pendente = true;
    if (!_sessaoExpiradaCtrl.isClosed) _sessaoExpiradaCtrl.add(null);
  }

  /// Renovação proativa, chamada ao voltar do background: se o access token
  /// (1h) já venceu ou vence em menos de [margem], renova ANTES de as telas
  /// dispararem várias requisições com token vencido (cada uma tomaria 401 e
  /// entraria na fila do refresh). Retorna false só se a sessão morreu.
  static Future<bool> renovarSeNecessario({
    Duration margem = const Duration(minutes: 5),
  }) async {
    final token = await StorageService.getAccessToken();
    if (token == null || token.isEmpty) return false;
    final exp = expiracaoDoJwt(token);
    if (exp != null && exp.difference(DateTime.now()) > margem) return true;

    LoggerService.i('Token vencido/perto de vencer ao retomar — renovando');
    final r = await _refreshTokens();
    if (r == _RefreshResult.denied) {
      final atual = await StorageService.getAccessToken();
      if (atual != null && atual != token) return true; // sessão trocada
      await StorageService.clearAuthDataOnly();
      _avisarSessaoExpirada();
      return false;
    }
    return true;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Adiciona o token de acesso se existir
    final accessToken = await StorageService.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    // Adiciona o tenant ID + Origin (backend exige Origin header por CSRF)
    final tenantConfig = await StorageService.getTenantConfig();
    if (tenantConfig != null && tenantConfig['subdomain'] != null) {
      final subdomain = tenantConfig['subdomain'] as String;
      options.headers['X-Tenant-ID'] = subdomain;
      options.headers['Origin'] = 'https://$subdomain.gabiflow.com.br';
      options.headers['Referer'] = 'https://$subdomain.gabiflow.com.br/';

      // Garante que a requisição vá para o tenant ATUAL.
      // Existem múltiplas instâncias de ApiClient no app e cada uma congela a
      // baseUrl na construção — após trocar de tenant, instâncias antigas
      // continuariam apontando para o subdomínio anterior (tenant mismatch
      // no backend). Reescrever aqui elimina o problema na raiz.
      final tenantUrl = EnvConfig.getTenantUrl(subdomain);
      if (options.baseUrl.contains('gabiflow') &&
          options.baseUrl != tenantUrl) {
        LoggerService.w(
            'baseUrl desatualizada (${options.baseUrl}) → $tenantUrl');
        options.baseUrl = tenantUrl;
      }
    }

    LoggerService.d('Request: ${options.method} ${options.path}');

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    LoggerService.d('Response: ${response.statusCode} ${response.realUri}');

    if (response.statusCode == 401 &&
        !_isAuthEndpoint(response.requestOptions.path)) {
      final retried = await _handle401(response.requestOptions);
      if (retried != null) {
        return handler.resolve(retried);
      }
    }
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    LoggerService.e('Error: ${err.type} - ${err.message}');

    if (err.response?.statusCode == 401 &&
        !_isAuthEndpoint(err.requestOptions.path)) {
      final retried = await _handle401(err.requestOptions);
      if (retried != null) {
        return handler.resolve(retried);
      }
    }
    handler.next(err);
  }

  /// Endpoints de auth não devem disparar refresh (evita loop).
  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/logout');
  }

  /// Tenta renovar o token e refazer a requisição original.
  /// Retorna a resposta do retry ou null (mantém o 401 original).
  Future<Response<dynamic>?> _handle401(RequestOptions original) async {
    LoggerService.w('401 em ${original.path} — tentando renovar token...');

    // Guarda contra corrida com login/refresh concorrente: se o token salvo
    // já é DIFERENTE do usado na requisição que tomou 401, a sessão foi
    // renovada por outro fluxo (ex.: login recém-concluído). Nesse caso,
    // basta refazer com o token atual — sem refresh e sem limpar nada.
    final tokenUsado =
        (original.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '');
    final tokenAtual = await StorageService.getAccessToken();
    if (tokenAtual != null && tokenAtual != tokenUsado) {
      LoggerService.i('Token já renovado por outro fluxo — refazendo direto');
      return _retryComTokenAtual(original);
    }

    final result = await _refreshTokens();
    if (result != _RefreshResult.ok) {
      // Só limpa a sessão quando o servidor NEGOU o refresh (token expirado
      // ou revogado). Erro de rede/transiente não pode derrubar a sessão.
      if (result == _RefreshResult.denied) {
        // Revalida a guarda: se um login aconteceu ENQUANTO o refresh rodava,
        // os tokens novos não podem ser apagados.
        final tokenPosRefresh = await StorageService.getAccessToken();
        if (tokenPosRefresh != null && tokenPosRefresh != tokenUsado) {
          LoggerService.i('Sessão trocada durante o refresh — preservando');
          return _retryComTokenAtual(original);
        }
        LoggerService.w('Refresh negado pelo servidor — limpando sessão');
        await StorageService.clearAuthDataOnly();
        _avisarSessaoExpirada();
      }
      return null;
    }

    return _retryComTokenAtual(original);
  }

  /// Refaz a requisição original com o access token atualmente salvo.
  Future<Response<dynamic>?> _retryComTokenAtual(RequestOptions original) async {
    try {
      final newToken = await StorageService.getAccessToken();
      if (newToken == null) return null;
      original.headers['Authorization'] = 'Bearer $newToken';
      // fetch() reexecuta preservando baseUrl/path/responseType/validateStatus
      final retry = await Dio().fetch<dynamic>(original);
      LoggerService.i('Retry pós-refresh: ${retry.statusCode} ${original.path}');
      return retry;
    } catch (e) {
      LoggerService.e('Retry pós-refresh falhou', e);
      return null;
    }
  }

  /// Renovação single-flight: a primeira requisição dispara o refresh,
  /// as demais aguardam o mesmo Future.
  static Future<_RefreshResult> _refreshTokens() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  static Future<_RefreshResult> _doRefresh() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return _RefreshResult.denied;
      }

      final tenantConfig = await StorageService.getTenantConfig();
      final subdomain = tenantConfig?['subdomain'] as String?;
      if (subdomain == null) return _RefreshResult.denied;

      // Dio "cru" (sem interceptors) para evitar recursão
      final dio = Dio(
        BaseOptions(
          baseUrl: EnvConfig.getTenantUrl(subdomain),
          connectTimeout: EnvConfig.connectionTimeout,
          receiveTimeout: EnvConfig.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Tenant-ID': subdomain,
            'Origin': 'https://$subdomain.gabiflow.com.br',
            'Referer': 'https://$subdomain.gabiflow.com.br/',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final res = await dio.post<dynamic>(
        '/api/mobile/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      dynamic data = res.data;
      if (data is String && data.isNotEmpty) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          return _RefreshResult.error;
        }
      }

      if (res.statusCode == 200 &&
          data is Map &&
          data['success'] == true &&
          data['tokens'] is Map) {
        final tokens = (data['tokens'] as Map).cast<String, dynamic>();
        final newAccess = tokens['accessToken']?.toString();
        final newRefresh = tokens['refreshToken']?.toString();
        if (newAccess == null || newAccess.isEmpty) {
          return _RefreshResult.error;
        }

        await StorageService.saveAccessToken(newAccess);
        // Rotação: o backend revoga o refresh antigo — salvar o novo é obrigatório
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await StorageService.saveRefreshToken(newRefresh);
        }
        LoggerService.i('Token renovado com sucesso');
        return _RefreshResult.ok;
      }

      LoggerService.w(
          'Refresh recusado: HTTP ${res.statusCode} ${data is Map ? data['code'] : ''}');
      // 400/401 = negado definitivamente; qualquer outra coisa é transiente
      final denied = res.statusCode == 400 || res.statusCode == 401;
      return denied ? _RefreshResult.denied : _RefreshResult.error;
    } catch (e) {
      LoggerService.e('Erro ao renovar token', e);
      return _RefreshResult.error;
    }
  }
}

/// Lê o claim `exp` de um JWT sem validar assinatura (uso exclusivo para
/// decidir renovação proativa). Retorna null se não conseguir decodificar.
DateTime? expiracaoDoJwt(String token) {
  try {
    final partes = token.split('.');
    if (partes.length != 3) return null;
    final payload =
        utf8.decode(base64Url.decode(base64Url.normalize(partes[1])));
    final map = jsonDecode(payload);
    final exp = map is Map ? map['exp'] : null;
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    }
  } catch (_) {
    // token malformado: trata como "sem exp"
  }
  return null;
}

/// Aviso "sua sessão expirou", consumido pela tela de login ao abrir.
class SessaoExpiradaAviso {
  static bool pendente = false;

  static bool consumir() {
    final p = pendente;
    pendente = false;
    return p;
  }
}

/// Resultado da tentativa de refresh.
enum _RefreshResult {
  /// Token renovado com sucesso.
  ok,

  /// Servidor negou (token expirado/revogado/ausente) — sessão morta.
  denied,

  /// Falha transiente (rede/servidor) — manter sessão.
  error,
}
