// GET /api/mobile/constituents?page=&limit=&search=&cidade=&tag=&nivel_apoio=&aniversariantes=&sort=
// retorna {success, data: {items, total, page, limit, hasMore}}
// POST/PUT aceitam campos PT-BR (nome, observacoes, nivel_apoio, ...)

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/constituent_extras.dart';
import '../models/constituent_model.dart';

abstract class ConstituentRemoteDataSource {
  Future<ConstituentListResponse> getConstituents({
    int page = 1,
    int limit = 20,
    String? search,
    ConstituentFilters filters = ConstituentFilters.vazios,
  });
  Future<ConstituentModel> getConstituentById(String id);
  Future<ConstituentModel> createConstituent(Map<String, dynamic> body);
  Future<ConstituentModel> updateConstituent(
      String id, Map<String, dynamic> body);
  Future<void> deleteConstituent(String id);
  Future<ConstituentFacets> getFacets();
  Future<List<InteracaoModel>> getInteracoes(String constituentId);
  Future<InteracaoModel> createInteracao(
      String constituentId, Map<String, dynamic> body);
}

class ConstituentRemoteDataSourceImpl implements ConstituentRemoteDataSource {
  final ApiClient _apiClient;

  ConstituentRemoteDataSourceImpl(this._apiClient);

  Future<Options> _authOptions() async {
    final token = await StorageService.getAccessToken();
    final tenantConfig = await StorageService.getTenantConfig();
    final tenantId = tenantConfig?['subdomain'] as String? ?? '';
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
      'X-Tenant-ID': tenantId,
    });
  }

  /// Desembrulha {success, data} e converte falhas em exceções com a
  /// mensagem do backend (nunca retorna model vazio silencioso).
  Map<String, dynamic> _extractData(Map<String, dynamic>? body) {
    if (body == null) throw Exception('Resposta vazia do servidor');
    if (body['success'] == false) {
      throw Exception(body['error']?.toString() ?? 'Erro desconhecido');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inesperada do servidor');
    }
    return data;
  }

  @override
  Future<ConstituentListResponse> getConstituents({
    int page = 1,
    int limit = 20,
    String? search,
    ConstituentFilters filters = ConstituentFilters.vazios,
  }) async {
    final opts = await _authOptions();
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (filters.cidade != null) 'cidade': filters.cidade,
      if (filters.tag != null) 'tag': filters.tag,
      if (filters.nivelApoio != null) 'nivel_apoio': filters.nivelApoio,
      if (filters.aniversariantes != null)
        'aniversariantes': filters.aniversariantes,
      if (filters.sort != 'recentes') 'sort': filters.sort,
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/constituents',
      queryParameters: params,
      options: opts,
    );

    final data = _extractData(response.data);
    LoggerService.i('constituents list: total=${data['total']}');
    return ConstituentListResponse.fromJson(data);
  }

  @override
  Future<ConstituentModel> getConstituentById(String id) async {
    final opts = await _authOptions();
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/constituents/$id',
      options: opts,
    );
    return ConstituentModel.fromJson(_extractData(response.data));
  }

  @override
  Future<ConstituentModel> createConstituent(
      Map<String, dynamic> body) async {
    final opts = await _authOptions();
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/mobile/constituents',
      data: body,
      options: opts,
    );
    return ConstituentModel.fromJson(_extractData(response.data));
  }

  @override
  Future<ConstituentModel> updateConstituent(
      String id, Map<String, dynamic> body) async {
    final opts = await _authOptions();
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/api/mobile/constituents/$id',
      data: body,
      options: opts,
    );
    return ConstituentModel.fromJson(_extractData(response.data));
  }

  @override
  Future<void> deleteConstituent(String id) async {
    final opts = await _authOptions();
    final response = await _apiClient.delete<Map<String, dynamic>>(
      '/api/mobile/constituents/$id',
      options: opts,
    );
    _extractData(response.data);
  }

  @override
  Future<ConstituentFacets> getFacets() async {
    final opts = await _authOptions();
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/constituents/facets',
      options: opts,
    );
    return ConstituentFacets.fromJson(_extractData(response.data));
  }

  @override
  Future<List<InteracaoModel>> getInteracoes(String constituentId) async {
    final opts = await _authOptions();
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/constituents/$constituentId/interacoes',
      options: opts,
    );
    final data = _extractData(response.data);
    return (data['items'] as List? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => InteracaoModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<InteracaoModel> createInteracao(
      String constituentId, Map<String, dynamic> body) async {
    final opts = await _authOptions();
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/mobile/constituents/$constituentId/interacoes',
      data: body,
      options: opts,
    );
    return InteracaoModel.fromJson(_extractData(response.data));
  }
}
