import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/logger_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/models/dashboard_stats_model.dart';

/// Provider para o datasource do dashboard
final dashboardDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRemoteDataSourceImpl(apiClient);
});

/// Provider para buscar estatísticas do dashboard
final dashboardStatsProvider = FutureProvider<DashboardStatsModel>((ref) async {
  final authState = ref.watch(authProvider);
  final tenantId = authState.user?.tenant ?? authState.user?.tenantId;
  
  LoggerService.i('Dashboard provider - Auth state: isAuthenticated=${authState.isAuthenticated}, user=${authState.user?.name}, tenant=$tenantId');
  
  if (tenantId == null) {
    LoggerService.e('No tenant ID available for dashboard stats - User: ${authState.user?.toJson()}');
    throw Exception('Tenant ID not available');
  }
  
  LoggerService.i('Fetching dashboard stats for tenant: $tenantId');
  final dataSource = ref.watch(dashboardDataSourceProvider);
  return dataSource.getStats(tenantId);
});

/// Provider para atualizar estatísticas do dashboard
final dashboardRefreshProvider = Provider((ref) {
  return () {
    ref.invalidate(dashboardStatsProvider);
  };
});