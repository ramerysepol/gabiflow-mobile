import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/transferencia_models.dart';

/// Transferência de votos 2024 → 2026.
/// Endpoints: /api/mobile/eleitoral/transferencia/*
class TransferenciaRemoteDatasource {
  const TransferenciaRemoteDatasource(this._client);

  final ApiClient _client;
  static const _base = '/api/mobile/eleitoral/transferencia';

  Map<String, dynamic> _params({
    required String sequencial,
    required int ano,
    required String uf,
    required int anoApoio,
    String? municipio,
  }) =>
      {
        'sequencial': sequencial,
        'ano': ano,
        'uf': uf,
        'ano_apoio': anoApoio,
        if (municipio != null && municipio.trim().isNotEmpty)
          'municipio': municipio.trim(),
      };

  Future<List<ApoiadorModel>> buscarApoiadores({
    required String sequencial,
    required int ano,
    required String uf,
    required int anoApoio,
    required String termo,
    String? municipio,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '$_base/apoiadores',
      queryParameters: {
        ..._params(
            sequencial: sequencial,
            ano: ano,
            uf: uf,
            anoApoio: anoApoio,
            municipio: municipio),
        'termo': termo,
      },
    );
    final data = _data(res.data);
    return (data['apoiadores'] as List? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => ApoiadorModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<SugestaoApoiadorModel>> sugerir({
    required String sequencial,
    required int ano,
    required String uf,
    required int anoApoio,
    String? municipio,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '$_base/sugestoes',
      queryParameters: _params(
          sequencial: sequencial,
          ano: ano,
          uf: uf,
          anoApoio: anoApoio,
          municipio: municipio),
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    final data = _data(res.data);
    return (data['sugestoes'] as List? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => SugestaoApoiadorModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// [tipo]: simplificado | completo.
  Future<List<int>> baixarRelatorioPdf({
    required String sequencial,
    required int ano,
    required String uf,
    required int anoApoio,
    required List<String> apoiadores,
    required String tipo,
    String? municipio,
  }) async {
    final res = await _client.get<List<int>>(
      '$_base/relatorio-pdf',
      queryParameters: {
        ..._params(
            sequencial: sequencial,
            ano: ano,
            uf: uf,
            anoApoio: anoApoio,
            municipio: municipio),
        'apoiadores': apoiadores.join(','),
        'tipo': tipo,
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': 'application/pdf'},
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    final bytes = res.data;
    if (res.statusCode != 200 || bytes == null || bytes.isEmpty) {
      String motivo = 'Falha ao gerar o PDF (HTTP ${res.statusCode})';
      if (bytes != null && bytes.isNotEmpty) {
        try {
          final json = jsonDecode(utf8.decode(bytes));
          if (json is Map && json['error'] is String) {
            motivo = json['error'] as String;
          }
        } catch (_) {}
      }
      throw Exception(motivo);
    }
    return bytes;
  }

  Map<String, dynamic> _data(Map<String, dynamic>? json) {
    if (json == null) throw Exception('Resposta vazia do servidor');
    if (json['success'] == false) {
      throw Exception(json['error'] ?? 'Erro desconhecido');
    }
    return (json['data'] as Map).cast<String, dynamic>();
  }
}
