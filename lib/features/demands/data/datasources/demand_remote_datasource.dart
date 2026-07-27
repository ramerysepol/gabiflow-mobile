// Contrato assumido: GET /api/mobile/demands?page=&limit=&status=&priority=&constituent_id=&search=
// retorna {success, data: {items, total, page, limit, hasMore, statusCounts}}
// POST /api/mobile/demands/{id}/notes — body {content}

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../models/demand_model.dart';

abstract class DemandRemoteDataSource {
  Future<DemandListResponse> getDemands({
    int page = 1,
    int limit = 20,
    String? status,
    String? priority,
    String? constituentId,
    String? search,
  });
  Future<DemandModel> getDemandById(String id);
  Future<DemandModel> createDemand(Map<String, dynamic> body);
  Future<DemandModel> updateDemand(String id, Map<String, dynamic> body);
  Future<void> addNote(String demandId, String content);
}

class DemandRemoteDataSourceImpl implements DemandRemoteDataSource {
  final ApiClient _apiClient;

  DemandRemoteDataSourceImpl(this._apiClient);

  Future<Options> _authOptions() async {
    final token = await StorageService.getAccessToken();
    final tenantConfig = await StorageService.getTenantConfig();
    final tenantId = tenantConfig?['subdomain'] as String? ?? '';
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
      'X-Tenant-ID': tenantId,
    });
  }

  @override
  Future<DemandListResponse> getDemands({
    int page = 1,
    int limit = 20,
    String? status,
    String? priority,
    String? constituentId,
    String? search,
  }) async {
    final opts = await _authOptions();
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status != 'all') params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (constituentId != null) params['constituent_id'] = constituentId;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/demands',
      queryParameters: params,
      options: opts,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return DemandListResponse.fromJson(data);
  }

  @override
  Future<DemandModel> getDemandById(String id) async {
    final opts = await _authOptions();
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/demands/$id',
      options: opts,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return DemandModel.fromJson(data);
  }

  @override
  Future<DemandModel> createDemand(Map<String, dynamic> body) async {
    final opts = await _authOptions();
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/mobile/demands',
      data: body,
      options: opts,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return DemandModel.fromJson(data);
  }

  @override
  Future<DemandModel> updateDemand(
      String id, Map<String, dynamic> body) async {
    final opts = await _authOptions();
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/api/mobile/demands/$id',
      data: body,
      options: opts,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return DemandModel.fromJson(data);
  }

  @override
  Future<void> addNote(String demandId, String content) async {
    final opts = await _authOptions();
    await _apiClient.post<Map<String, dynamic>>(
      '/api/mobile/demands/$demandId/notes',
      data: {'content': content},
      options: opts,
    );
  }
}
