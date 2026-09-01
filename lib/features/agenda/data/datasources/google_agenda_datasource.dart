// Integracao Google Calendar — consome as rotas maduras do web
// (/api/agenda/google/*), que aceitam Authorization Bearer.
// O OAuth em si acontece no navegador (authUrl); o servidor sincroniza
// bidirecionalmente e os eventos caem na mesma tabela que o app ja le.

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class GoogleAgendaStatus {
  final bool conectado;
  final String? calendario;
  final DateTime? ultimaSync;
  final String? erroSync;

  const GoogleAgendaStatus({
    required this.conectado,
    this.calendario,
    this.ultimaSync,
    this.erroSync,
  });

  factory GoogleAgendaStatus.fromJson(Map<String, dynamic> json) {
    final cal = json['calendar'] as Map<String, dynamic>?;
    return GoogleAgendaStatus(
      conectado: json['connected'] == true,
      calendario: cal?['summary'] as String?,
      ultimaSync: cal?['last_synced_at'] != null
          ? DateTime.tryParse(cal!['last_synced_at'].toString())
          : null,
      erroSync: cal?['last_sync_error'] as String?,
    );
  }
}

class GoogleAgendaDatasource {
  final ApiClient _client;

  GoogleAgendaDatasource(this._client);

  Map<String, dynamic> _data(dynamic raw, String contexto) {
    if (raw is Map<String, dynamic> && raw['success'] == true) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    final erro = raw is Map<String, dynamic> ? raw['error'] : null;
    throw Exception(erro?.toString() ?? 'Falha em $contexto');
  }

  Future<GoogleAgendaStatus> status() async {
    final res = await _client.get<dynamic>('/api/agenda/google/status');
    return GoogleAgendaStatus.fromJson(_data(res.data, 'status do Google'));
  }

  /// URL de autorizacao — abrir no navegador; o callback conclui no web.
  Future<String> authUrl() async {
    final res = await _client.get<dynamic>('/api/agenda/google/auth');
    final data = _data(res.data, 'conectar Google');
    final url = data['authUrl']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('Servidor nao retornou a URL de autorizacao');
    }
    return url;
  }

  /// Puxa os eventos do Google agora (sync manual).
  ///
  /// Um 500 aqui traz o motivo real no corpo (`error` vem de
  /// last_sync_error do servidor) — repassa-lo e' o que permite ao
  /// atendente distinguir "token do Google expirou" de "sem internet".
  Future<void> sincronizar() async {
    try {
      final res = await _client.post<dynamic>(
        '/api/agenda/google/sync',
        data: const <String, dynamic>{},
        // O sync completo pagina o Google e grava evento a evento — passa
        // facil dos 30s padrao, e o timeout virava um falso "sem conexao".
        options: Options(receiveTimeout: const Duration(minutes: 2)),
      );
      _data(res.data, 'sincronizar Google');
    } on DioException catch (e) {
      final body = e.response?.data;
      final motivo = body is Map<String, dynamic> ? body['error'] : null;
      if (motivo != null && motivo.toString().isNotEmpty) {
        throw Exception('sync falhou: $motivo');
      }
      rethrow;
    }
  }
}
