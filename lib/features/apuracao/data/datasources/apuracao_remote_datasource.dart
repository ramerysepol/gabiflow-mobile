import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/apuracao_busca_model.dart';
import '../models/apuracao_candidato_model.dart';
import '../models/apuracao_evento_model.dart';
import '../models/apuracao_mapa_uf_model.dart';
import '../models/apuracao_municipio_model.dart';
import '../models/apuracao_ranking_model.dart';
import '../models/apuracao_resumo_model.dart';
import '../models/apuracao_seguir_model.dart';
import '../models/apuracao_status_model.dart';
import '../models/apuracao_territorio_model.dart';

/// Datasource da "Apuração ao vivo" (resultados oficiais do TSE).
class ApuracaoRemoteDatasource {
  const ApuracaoRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApuracaoStatusModel> getStatus() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/apuracao/status',
    );
    final data = _extractData(res.data);
    return ApuracaoStatusModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ApuracaoSeguirModel> getSeguir() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/apuracao/seguir',
    );
    final data = _extractData(res.data);
    return ApuracaoSeguirModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ApuracaoSeguirModel> seguir({
    required String sqcand,
    required bool principal,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/apuracao/seguir',
      data: {'sqcand': sqcand, 'principal': principal},
    );
    final data = _extractData(res.data);
    return ApuracaoSeguirModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ApuracaoSeguirModel> deixarDeSeguir(String sqcand) async {
    final res = await _client.delete<Map<String, dynamic>>(
      '/api/mobile/apuracao/seguir',
      queryParameters: {'sqcand': sqcand},
    );
    final data = _extractData(res.data);
    return ApuracaoSeguirModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ApuracaoRankingModel> getRanking({
    required int cargo,
    String? uf,
    int limit = 50,
    int offset = 0,
    String q = '',
    String? municipio,
    String projecao = '',
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/apuracao/ranking',
      queryParameters: {
        'cargo': cargo,
        if (uf != null && uf.isNotEmpty) 'uf': uf,
        'limit': limit,
        'offset': offset,
        if (q.isNotEmpty) 'q': q,
        if (municipio != null && municipio.isNotEmpty) 'municipio': municipio,
        if (projecao.isNotEmpty && projecao != 'todos') 'projecao': projecao,
      },
    );
    final data = _extractData(res.data);
    return ApuracaoRankingModel.fromJson(data as Map<String, dynamic>);
  }

  /// Relatório em PDF (bytes) de eleitos / suplentes / não eleitos pelo
  /// quociente eleitoral, o mesmo do painel web.
  /// [projecao]: todos | eleito | suplente | nao_eleito.
  Future<List<int>> baixarRelatorioPdf({
    required int cargo,
    String? uf,
    String projecao = 'todos',
  }) async {
    final res = await _client.get<List<int>>(
      '/api/mobile/apuracao/relatorio',
      queryParameters: {
        'cargo': cargo,
        if (uf != null && uf.isNotEmpty) 'uf': uf,
        'projecao': projecao.isEmpty ? 'todos' : projecao,
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': 'application/pdf'},
        receiveTimeout: const Duration(seconds: 90),
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
        } catch (_) {
          // corpo não é JSON: mantém a mensagem genérica
        }
      }
      throw Exception(motivo);
    }
    return bytes;
  }

  Future<ApuracaoResumoDetalheModel> getResumo({
    required int cargo,
    String? uf,
    String? municipio,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/apuracao/resumo',
      queryParameters: {
        'cargo': cargo,
        if (uf != null && uf.isNotEmpty) 'uf': uf,
        if (municipio != null && municipio.isNotEmpty) 'municipio': municipio,
      },
    );
    final data = _extractData(res.data);
    return ApuracaoResumoDetalheModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ApuracaoCandidatoModel> getCandidato(String sqcand) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/apuracao/candidato/$sqcand',
    );
    final data = _extractData(res.data);
    return ApuracaoCandidatoModel.fromJson(data as Map<String, dynamic>);
  }

  /// "Onde está o voto que falta": projeção final do candidato e o
  /// comparativo município a município com a eleição de 2022.
  Future<ApuracaoTerritorioModel> getTerritorio(String sqcand) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/apuracao/candidato/$sqcand/territorio',
    );
    final data = _extractData(res.data);
    return ApuracaoTerritorioModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ApuracaoBuscaModel> busca({
    required String q,
    String? uf,
    int? cargo,
    int limit = 20,
  }) async {
    if (q.trim().isEmpty) return const ApuracaoBuscaModel();
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/apuracao/busca',
      queryParameters: {
        'q': q,
        if (uf != null && uf.isNotEmpty) 'uf': uf,
        if (cargo != null) 'cargo': cargo,
        'limit': limit,
      },
    );
    final data = _extractData(res.data);
    return ApuracaoBuscaModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ApuracaoMunicipiosModel> getMunicipios({
    String? uf,
    int? cargo,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/apuracao/municipios',
      queryParameters: {
        if (uf != null && uf.isNotEmpty) 'uf': uf,
        if (cargo != null) 'cargo': cargo,
      },
    );
    final data = _extractData(res.data);
    return ApuracaoMunicipiosModel.fromJson(data as Map<String, dynamic>);
  }

  /// Feed "Acontecendo agora": marcos recentes da apuração dos candidatos
  /// acompanhados. [desde] busca só os eventos novos a partir daquele
  /// instante (usado pelo poll); omitido, traz a carga inicial.
  Future<ApuracaoEventosModel> getEventos({
    DateTime? desde,
    int limit = 50,
    String? sqcand,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/apuracao/eventos',
      queryParameters: {
        if (desde != null) 'desde': desde.toUtc().toIso8601String(),
        'limit': limit,
        if (sqcand != null && sqcand.isNotEmpty) 'sqcand': sqcand,
      },
    );
    final data = _extractData(res.data);
    return ApuracaoEventosModel.fromJson(data as Map<String, dynamic>);
  }

  /// Painel nacional por estados (mapa do Brasil + duelo): GET /apuracao/mapa-uf.
  Future<ApuracaoMapaUfModel> getMapaUf({
    int cargo = 1,
    int limit = 8,
    int top = 4,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/apuracao/mapa-uf',
      queryParameters: {'cargo': cargo, 'limit': limit, 'top': top},
    );
    final data = _extractData(res.data);
    return ApuracaoMapaUfModel.fromJson(data as Map<String, dynamic>);
  }

  dynamic _extractData(Map<String, dynamic>? json) {
    if (json == null) throw Exception('Resposta vazia do servidor');
    if (json['success'] == false) {
      throw Exception(json['error'] ?? 'Erro desconhecido');
    }
    return json['data'];
  }
}
