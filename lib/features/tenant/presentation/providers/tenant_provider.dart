import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/api_providers.dart';
import '../../data/datasources/tenant_remote_datasource.dart';

final tenantRemoteDataSourceProvider = Provider<TenantRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TenantRemoteDataSourceImpl(apiClient);
});

final checkTenantProvider = FutureProvider.family<bool, String>((ref, subdomain) async {
  final dataSource = ref.watch(tenantRemoteDataSourceProvider);
  final tenant = await dataSource.checkTenant(subdomain);
  return tenant != null;
});