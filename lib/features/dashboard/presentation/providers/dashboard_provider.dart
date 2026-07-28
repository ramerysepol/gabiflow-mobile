import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/models/dashboard_stats_model.dart';

/// Provider para o datasource do dashboard
final dashboardDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRemoteDataSourceImpl(apiClient);
});

/// Provider para buscar estatísticas do dashboard.
/// O tenant vem do estado de auth OU do storage — no cold start o splash já
/// validou a sessão, mas o authProvider pode ainda não ter hidratado
/// (evita o flash de erro antes do dashboard carregar).
final dashboardStatsProvider = FutureProvider<DashboardStatsModel>((ref) async {
  final authState = ref.watch(authProvider);
  var tenantId = authState.user?.tenant ?? authState.user?.tenantId;

  if (tenantId == null) {
    final config = await StorageService.getTenantConfig();
    tenantId = config?['subdomain'] as String?;
  }

  if (tenantId == null) {
    LoggerService.e('Dashboard: sem tenant no auth nem no storage');
    throw Exception('Configuração do gabinete não encontrada');
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