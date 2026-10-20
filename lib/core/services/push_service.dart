import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../network/api_client.dart';
import '../router/app_router.dart';
import 'logger_service.dart';
import 'notificacoes_locais_service.dart';

/// Handler de mensagens em segundo plano/encerrado. Precisa ser top-level.
/// Mensagens com `notification` são exibidas pelo próprio sistema, então aqui
/// só garantimos que o handler existe sem quebrar.
@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage mensagem) async {
  // Nada a fazer: o sistema exibe o push com `notification`.
}

/// Push FCM de novas mensagens de WhatsApp.
///
/// Firebase é inicializado por opções manuais lidas do `.env` (sem
/// google-services.json / GoogleService-Info.plist). Se faltar qualquer
/// chave, o push fica desligado silenciosamente e o app funciona normal.
abstract final class PushService {
  static const _rotaTokenApi = '/api/mobile/notificacoes/token';
  static const _rotaLista = '/home/atendimento';

  static bool _ativo = false;
  static bool _listenersConfigurados = false;
  static ApiClient? _api;
  static String? _tokenAtual;
  static bool _autenticado = false;
  static String? _conversaPendente;

  static bool get ativo => _ativo;

  static String _env(String chave) => (dotenv.maybeGet(chave) ?? '').trim();

  /// Monta as opções do Firebase para a plataforma, ou null se faltar algo.
  static FirebaseOptions? _opcoes() {
    final projectId = _env('FIREBASE_PROJECT_ID');
    final senderId = _env('FIREBASE_MESSAGING_SENDER_ID');
    final ios = Platform.isIOS;
    final apiKey = _env(ios ? 'FIREBASE_API_KEY_IOS' : 'FIREBASE_API_KEY_ANDROID');
    final appId = _env(ios ? 'FIREBASE_APP_ID_IOS' : 'FIREBASE_APP_ID_ANDROID');
    if (projectId.isEmpty ||
        senderId.isEmpty ||
        apiKey.isEmpty ||
        appId.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      iosBundleId: ios ? 'br.com.gabiflow.gabiflowMobile' : null,
    );
  }

  /// Inicializa o Firebase e os listeners. Chamar uma vez no boot (após o
  /// dotenv). Nunca lança.
  static Future<void> inicializar() async {
    if (_ativo) return;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return;
      final opcoes = _opcoes();
      if (opcoes == null) {
        LoggerService.i('Push desligado: chaves FIREBASE_* ausentes no .env');
        return;
      }
      await Firebase.initializeApp(options: opcoes);
      FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);
      _ativo = true;
      await _configurarListeners();
    } catch (e, st) {
      _ativo = false;
      LoggerService.e('Falha ao inicializar push', e, st);
    }
  }

  static Future<void> _configurarListeners() async {
    if (_listenersConfigurados) return;
    _listenersConfigurados = true;
    final fcm = FirebaseMessaging.instance;

    NotificacoesLocaisService.aoTocar = _aoTocarLocal;
    FirebaseMessaging.onMessage.listen(_aoReceberEmPrimeiroPlano);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => _abrirConversa(m.data['conversationId']?.toString()),
    );
    fcm.onTokenRefresh.listen((novo) {
      _tokenAtual = novo;
      if (_autenticado) unawaited(_enviarToken(novo));
    });

    final inicial = await fcm.getInitialMessage();
    final id = inicial?.data['conversationId']?.toString();
    if (id != null && id.isNotEmpty) _conversaPendente = id;
  }

  /// Chamar após login OK (ou boot já logado): pede permissão, obtém o token
  /// e registra no backend. Também abre a conversa pendente (cold start).
  static Future<void> registrar(ApiClient api) async {
    _api = api;
    _autenticado = true;
    if (!_ativo) return;
    try {
      final fcm = FirebaseMessaging.instance;
      final permissao = await fcm.requestPermission();
      if (permissao.authorizationStatus == AuthorizationStatus.denied) {
        LoggerService.i('Push: permissão de notificação negada');
      }
      final token = await fcm.getToken();
      if (token != null && token.isNotEmpty) {
        _tokenAtual = token;
        await _enviarToken(token);
      }
    } catch (e, st) {
      LoggerService.e('Falha ao registrar push', e, st);
    }
    _consumirPendente();
  }

  /// Chamar no logout, ANTES de limpar os tokens de sessão (o DELETE precisa
  /// estar autenticado).
  static Future<void> desregistrar() async {
    _autenticado = false;
    if (!_ativo) return;
    try {
      final token = _tokenAtual ?? await FirebaseMessaging.instance.getToken();
      if (token != null && _api != null) {
        await _api!.delete<dynamic>(_rotaTokenApi, data: {'token': token});
      }
    } catch (e, st) {
      LoggerService.e('Falha ao remover token de push no servidor', e, st);
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _tokenAtual = null;
  }

  static Future<void> _enviarToken(String token) async {
    final api = _api;
    if (api == null) return;
    try {
      await api.post<dynamic>(
        _rotaTokenApi,
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'deviceName': Platform.operatingSystem,
        },
      );
    } catch (e, st) {
      LoggerService.e('Falha ao registrar token de push', e, st);
    }
  }

  static void _aoReceberEmPrimeiroPlano(RemoteMessage m) {
    final n = m.notification;
    final titulo = n?.title ?? m.data['title']?.toString();
    final corpo = n?.body ?? m.data['body']?.toString();
    if (titulo == null && corpo == null) return;
    final id = m.data['conversationId']?.toString();
    unawaited(
      NotificacoesLocaisService.mostrarWhatsapp(
        id != null ? (int.tryParse(id) ?? id.hashCode) : m.hashCode,
        titulo ?? 'GabiFlow',
        corpo ?? '',
        payload: jsonEncode(m.data),
      ),
    );
  }

  static void _aoTocarLocal(String payload) {
    try {
      final dados = jsonDecode(payload);
      if (dados is Map) {
        _abrirConversa(dados['conversationId']?.toString());
        return;
      }
    } catch (_) {}
    _abrirConversa(null);
  }

  static void _consumirPendente() {
    final id = _conversaPendente;
    if (id == null) return;
    _conversaPendente = null;
    unawaited(_navegarAposBoot(id));
  }

  /// Espera o splash concluir seu go('/home') antes de empilhar o chat —
  /// um delay fixo disputava com o boot e o dashboard "roubava" a navegação.
  static Future<void> _navegarAposBoot(String id) async {
    for (var i = 0; i < 50; i++) {
      final rota = appRouter.routerDelegate.currentConfiguration.uri.path;
      if (rota.startsWith('/home')) break;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    // Um frame extra para o go('/home') do splash assentar na pilha.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _navegar(id);
  }

  static void _abrirConversa(String? id) {
    if (!_autenticado) {
      _conversaPendente = id ?? '';
      return;
    }
    _navegar(id);
  }

  static void _navegar(String? id) {
    final valido = id != null && int.tryParse(id) != null;
    appRouter.push(valido ? '$_rotaLista/chat/$id' : _rotaLista);
  }
}
