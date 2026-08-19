import '../../../../core/network/api_client.dart';
import '../models/candidato_model.dart';
import '../models/candidato_stats_model.dart';
import '../models/coligacao_detalhe_model.dart';
import '../models/comparacao_model.dart';
import '../models/estatisticas_model.dart';
import '../models/filtros_model.dart';
import '../models/hierarquia_nivel_model.dart';
import '../models/municipio_eleitos_model.dart';
import '../models/municipio_voto_model.dart';
import '../models/partido_detalhe_model.dart';
import '../models/ranking_model.dart';

class EleitoralRemoteDatasource {
  const EleitoralRemoteDatasource(this._client);

  final ApiClient _client;

  Future<FiltrosModel> getFiltros() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/filtros',
    );
    final data = _extractData(res.data);
    return FiltrosModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CandidatosPage> getCandidatos({
    required int ano,
    required String estado,
    required String cargo,
    String search = '',
    String municipio = '',
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/candidatos',
      queryParameters: {
        'ano': ano,
        'estado': estado,
        'cargo': cargo,
        if (search.isNotEmpty) 'search': search,
        if (municipio.isNotEmpty) 'municipio': municipio,
        'page': page,
        'limit': limit,
      },
    );
    final data = _extractData(res.data);
    return CandidatosPage.fromJson(data as Map<String, dynamic>);
  }

  Future<CandidatoFullModel> getCandidatoDetalhe({
    required String sequencial,
    required int ano,
    required String estado,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/candidato/$sequencial',
      queryParameters: {'ano': ano, 'estado': estado},
    );
    final data = _extractData(res.data);
    return CandidatoFullModel.fromJson(data as Map<String, dynamic>);
  }

  Future<MapaMunicipiosData> getMapaCandidato({
    required String sequencial,
    required int ano,
    required String estado,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/candidato/$sequencial/mapa',
      queryParameters: {'ano': ano, 'estado': estado},
    );
    final data = _extractData(res.data);
    return MapaMunicipiosData.fromJson(data as Map<String, dynamic>);
  }

  Future<HierarquiaNivelModel> getHierarquia({
    required String sequencial,
    required int ano,
    required String estado,
    required String nivel,
    String? paiId,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/candidato/$sequencial/hierarquia',
      queryParameters: {
        'ano': ano,
        'estado': estado,
        'nivel': nivel,
        if (paiId != null) 'pai_id': paiId,
      },
    );
    final data = _extractData(res.data);
    return HierarquiaNivelModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ComparacaoModel> comparar({
    required List<String> sequenciais,
    required int ano,
    required String estado,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/comparar',
      queryParameters: {
        'sequenciais': sequenciais.join(','),
        'ano': ano,
        'estado': estado,
      },
    );
    final data = _extractData(res.data);
    return ComparacaoModel.fromJson(data as Map<String, dynamic>);
  }

  Future<RankingModel> getRanking({
    required String tipo,
    required int ano,
    required String estado,
    required String cargo,
    int limit = 50,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/rankings',
      queryParameters: {
        'tipo': tipo,
        'ano': ano,
        'estado': estado,
        'cargo': cargo,
        'limit': limit,
      },
    );
    final data = _extractData(res.data);
    return RankingModel.fromJson(data as Map<String, dynamic>);
  }

  Future<MunicipioEleitosModel> getEleitosDoMunicipio({
    required String idMunicipio,
    required int ano,
    required String estado,
    required String cargo,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/municipio/$idMunicipio/eleitos',
      queryParameters: {
        'ano': ano,
        'estado': estado,
        if (cargo.isNotEmpty) 'cargo': cargo,
      },
    );
    final data = _extractData(res.data);
    return MunicipioEleitosModel.fromJson(data as Map<String, dynamic>);
  }

  Future<EstatisticasModel> getEstatisticas({
    required int ano,
    required String estado,
    String cargo = '',
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/estatisticas',
      queryParameters: {
        'ano': ano,
        'estado': estado,
        if (cargo.isNotEmpty) 'cargo': cargo,
      },
    );
    final data = _extractData(res.data);
    return EstatisticasModel.fromJson(data as Map<String, dynamic>);
  }

  Future<PartidoDetalheModel> getPartidoDetalhe({
    required String sigla,
    required int ano,
    required String estado,
    String cargo = '',
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/partido/${Uri.encodeComponent(sigla)}',
      queryParameters: {
        'ano': ano,
        'estado': estado,
        if (cargo.isNotEmpty) 'cargo': cargo,
      },
    );
    final data = _extractData(res.data);
    return PartidoDetalheModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ColigacaoDetalheModel> getColigacaoDetalhe({
    required String nome,
    required int ano,
    required String estado,
    String cargo = '',
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/eleitoral/coligacao',
      queryParameters: {
        'nome': nome,
        'ano': ano,
        'estado': estado,
        if (cargo.isNotEmpty) 'cargo': cargo,
      },
    );
    final data = _extractData(res.data);
    return ColigacaoDetalheModel.fromJson(data as Map<String, dynamic>);
  }

  dynamic _extractData(Map<String, dynamic>? json) {
    if (json == null) throw Exception('Resposta vazia do servidor');
    if (json['success'] == false) {
      throw Exception(json['error'] ?? 'Erro desconhecido');
    }
    return json['data'];
  }
}
