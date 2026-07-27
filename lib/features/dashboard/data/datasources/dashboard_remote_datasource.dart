import '../../../../core/network/api_client.dart';
import '../../../../core/services/logger_service.dart';
import '../models/dashboard_stats_model.dart';
import '../models/recent_activity_model.dart';

abstract class DashboardRemoteDataSource {
  /// Busca estatísticas do dashboard
  Future<DashboardStatsModel> getStats(String tenantId);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSourceImpl(this._apiClient);

  /// Busca do endpoint mobile consolidado (/api/mobile/dashboard).
  ///
  /// Nota: os antigos fallbacks para /api/constituents, /api/demands e
  /// /api/events foram removidos — são rotas web interceptadas pelo
  /// middleware (redirecionam para a página de login em HTML) e nunca
  /// funcionariam no app. Dados de demonstração também foram removidos
  /// (regra do projeto: nunca usar mock). Em caso de falha, a exceção
  /// sobe e a UI mostra o estado de erro com "Tentar novamente".
  @override
  Future<DashboardStatsModel> getStats(String tenantId) async {
    LoggerService.i('Fetching dashboard stats for tenant: $tenantId');

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/dashboard',
    );

    final raw = response.data;
    if (raw == null) {
      throw Exception('Resposta vazia do servidor');
    }
    if (raw['success'] == false) {
      throw Exception(raw['error'] ?? 'Erro ao carregar dashboard');
    }

    // O backend envolve a resposta em { success: true, data: {...} }
    final data = (raw['data'] as Map<String, dynamic>?) ?? raw;

    final activitiesList = data['recentActivities'] as List<dynamic>? ?? [];
    final activities = activitiesList.map((activity) {
      final a = activity as Map<String, dynamic>;
      return RecentActivityModel(
        type: a['type']?.toString() ?? 'info',
        title: a['title']?.toString() ?? '',
        action: a['subtitle']?.toString() ?? '',
        createdAt: _parseDateTime(a['timestamp']),
        referenceId: a['id']?.toString(),
      );
    }).toList();

    return DashboardStatsModel(
      totalConstituents: _parseIntFromData(data['totalConstituents']),
      newConstituentsToday: _parseIntFromData(data['newConstituentsToday']),
      totalDemands: _parseIntFromData(data['totalDemands']),
      openDemands: _parseIntFromData(data['openDemands']),
      resolvedDemandsToday: _parseIntFromData(data['resolvedDemandsToday']),
      upcomingEvents: _parseIntFromData(data['upcomingEvents']),
      eventsThisWeek: _parseIntFromData(data['eventsThisWeek']),
      messagestoday: _parseIntFromData(data['messagestoday']),
      messagesSent: _parseIntFromData(data['messagesSent']),
      recentActivities: activities,
    );
  }

  int _parseIntFromData(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}
