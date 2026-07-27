// Contrato: GET /api/mobile/events?start_date=&end_date=
// retorna {success, data: {items: [...]}}
// POST /api/mobile/events — {titulo, descricao, start_date, end_date, location, type, participant_ids}

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../models/event_model.dart';

abstract class EventRemoteDataSource {
  Future<EventListResponse> getEvents({String? startDate, String? endDate});
  Future<EventModel> getEventById(String id);
  Future<EventModel> createEvent(Map<String, dynamic> body);
  Future<EventModel> updateEvent(String id, Map<String, dynamic> body);
  Future<void> deleteEvent(String id);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final ApiClient _apiClient;

  EventRemoteDataSourceImpl(this._apiClient);

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
  Future<EventListResponse> getEvents(
      {String? startDate, String? endDate}) async {
    final opts = await _authOptions();
    final params = <String, dynamic>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/events',
      queryParameters: params.isNotEmpty ? params : null,
      options: opts,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return EventListResponse.fromJson(data);
  }

  @override
  Future<EventModel> getEventById(String id) async {
    final opts = await _authOptions();
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/events/$id',
      options: opts,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return EventModel.fromJson(data);
  }

  @override
  Future<EventModel> createEvent(Map<String, dynamic> body) async {
    final opts = await _authOptions();
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/mobile/events',
      data: body,
      options: opts,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return EventModel.fromJson(data);
  }

  @override
  Future<EventModel> updateEvent(
      String id, Map<String, dynamic> body) async {
    final opts = await _authOptions();
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/api/mobile/events/$id',
      data: body,
      options: opts,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return EventModel.fromJson(data);
  }

  @override
  Future<void> deleteEvent(String id) async {
    final opts = await _authOptions();
    await _apiClient.delete<Map<String, dynamic>>(
      '/api/mobile/events/$id',
      options: opts,
    );
  }
}
