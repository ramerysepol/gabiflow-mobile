import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/ia_chat_models.dart';
import '../models/ia_models.dart';

/// Datasource do Command Center IA.
/// Endpoints exclusivos mobile: /api/mobile/eleitoral/ia/*
class IaRemoteDatasource {
  const IaRemoteDatasource(this._client);

  final ApiClient _client;

  Future<IaInsightModel> getInsightDia({
    required String sequencial,
    required int ano,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/ia/insight-dia',
      queryParameters: {'sequencial': sequencial, 'ano': ano},
    );
    return IaInsightModel.fromJson(
        _extractData(res.data) as Map<String, dynamic>);
  }

  Future<List<IaAlertaModel>> getAlertas({
    required String sequencial,
    required int ano,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/ia/alertas',
      queryParameters: {'sequencial': sequencial, 'ano': ano},
    );
    final data = _extractData(res.data) as Map<String, dynamic>;
    return (data['alertas'] as List? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => IaAlertaModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<IaBriefingModel> getBriefing({
    required String sequencial,
    required int ano,
    required String uf,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/ia/briefing',
      queryParameters: {'sequencial': sequencial, 'ano': ano, 'uf': uf},
    );
    return IaBriefingModel.fromJson(
        _extractData(res.data) as Map<String, dynamic>);
  }

  Future<IaRadarModel> getRadarTerritorial({
    required String sequencial,
    required int ano,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/ia/radar-territorial',
      queryParameters: {'sequencial': sequencial, 'ano': ano},
    );
    return IaRadarModel.fromJson(
        _extractData(res.data) as Map<String, dynamic>);
  }

  /// Abre o chat SSE e emite os eventos conforme chegam.
  /// O stream fecha quando o servidor envia `done`/`error` ou a conexão cai.
  Stream<IaChatEvent> chatStream({
    required String pergunta,
    required Map<String, dynamic> contexto,
    List<Map<String, String>> historico = const [],
    CancelToken? cancelToken,
  }) async* {
    final res = await _client.postStream(
      '/api/mobile/eleitoral/ia/chat',
      data: {
        'pergunta': pergunta,
        'contexto': contexto,
        'historico': historico,
      },
      cancelToken: cancelToken,
    );

    final body = res.data;
    if (body == null) {
      throw Exception('Resposta vazia do servidor');
    }

    // Status != 200 → corpo é um JSON de erro, não um stream SSE
    if (res.statusCode != 200) {
      final bytes = await body.stream
          .fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
      String message = 'Erro ${res.statusCode}';
      try {
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is Map && decoded['error'] != null) {
          message = decoded['error'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }

    // Parser SSE: linhas "data: {json}" separadas por linha em branco.
    // Linhas começando com ":" são keepalive e devem ser ignoradas.
    final lines = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    var dataBuffer = StringBuffer();
    await for (final line in lines) {
      if (line.isEmpty) {
        if (dataBuffer.isNotEmpty) {
          final payload = dataBuffer.toString();
          dataBuffer = StringBuffer();
          try {
            final json = jsonDecode(payload) as Map<String, dynamic>;
            final event = IaChatEvent.fromJson(json);
            yield event;
            if (event.type == 'done') return;
          } catch (_) {
            // payload malformado — ignora e segue o stream
          }
        }
        continue;
      }
      if (line.startsWith(':')) continue; // keepalive
      if (line.startsWith('data:')) {
        dataBuffer.write(line.substring(5).trimLeft());
      }
    }
  }

  dynamic _extractData(Map<String, dynamic>? json) {
    if (json == null) throw Exception('Resposta vazia do servidor');
    if (json['success'] == false) {
      throw Exception(json['error'] ?? 'Erro desconhecido');
    }
    return json['data'];
  }
}
