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
  Future<List<DemandAttachment>> getAttachments(String demandId);
  Future<DemandAttachment> uploadAttachment(String demandId, String filePath);
  Future<void> deleteDemand(String id);
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

  @override
  Future<void> deleteDemand(String id) async {
    final opts = await _authOptions();
    await _apiClient.delete<Map<String, dynamic>>(
      '/api/mobile/demands/$id',
      options: opts,
    );
  }

  @override
  Future<List<DemandAttachment>> getAttachments(String demandId) async {
    final opts = await _authOptions();
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/demands/$demandId/attachments',
      options: opts,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List?) ?? const [];
    return items
        .map((e) => DemandAttachment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DemandAttachment> uploadAttachment(
      String demandId, String filePath) async {
    final opts = await _authOptions();

    // O MIME precisa ir explicito: sem isto o Dio manda application/octet-stream
    // e o servidor recusa por tipo invalido — mesmo problema ja corrigido no
    // upload de midia do WhatsApp (commit 29de49f).
    final nome = filePath.split('/').last;
    final ext = nome.contains('.') ? nome.split('.').last.toLowerCase() : '';
    final mime = switch (ext) {
      'png' => DioMediaType('image', 'png'),
      'heic' => DioMediaType('image', 'heic'),
      'heif' => DioMediaType('image', 'heif'),
      'webp' => DioMediaType('image', 'webp'),
      'pdf' => DioMediaType('application', 'pdf'),
      _ => DioMediaType('image', 'jpeg'),
    };

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: nome,
        contentType: mime,
      ),
    });

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/mobile/demands/$demandId/attachments',
      data: form,
      options: opts,
    );
    return DemandAttachment.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? {});
  }
}
