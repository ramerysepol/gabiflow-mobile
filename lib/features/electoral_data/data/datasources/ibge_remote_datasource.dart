import '../../../../core/network/api_client.dart';
import '../models/ibge_municipio_model.dart';

class IbgeRemoteDatasource {
  const IbgeRemoteDatasource(this._client);

  final ApiClient _client;

  Future<IbgeMunicipioModel> getMunicipio({
    required String id,
    String uf = 'BA',
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/ibge/municipio',
      queryParameters: {'id': id, 'uf': uf},
    );
    final data = _extractData(res.data);
    return IbgeMunicipioModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<IbgeMicrorregiao>> getMicrorregioes({String uf = 'BA'}) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/ibge/microrregioes',
      queryParameters: {'uf': uf},
    );
    final data = _extractData(res.data);
    final list = data as List? ?? [];
    return list
        .map((e) => IbgeMicrorregiao.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  dynamic _extractData(Map<String, dynamic>? json) {
    if (json == null) throw Exception('Resposta IBGE vazia');
    if (json['success'] == false) throw Exception(json['error'] ?? 'Erro IBGE');
    return json['data'];
  }
}
