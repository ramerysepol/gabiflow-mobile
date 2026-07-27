import '../../../../core/network/api_client.dart';
import '../../../../core/services/logger_service.dart';
import '../models/tenant_model.dart';

abstract class TenantRemoteDataSource {
  /// Verifica se o tenant existe pelo subdomínio
  Future<TenantModel?> checkTenant(String subdomain);
}

class TenantRemoteDataSourceImpl implements TenantRemoteDataSource {
  final ApiClient _apiClient;
  
  TenantRemoteDataSourceImpl(this._apiClient);
  
  @override
  Future<TenantModel?> checkTenant(String subdomain) async {
    try {
      LoggerService.i('Checking tenant: $subdomain');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/check-tenant',
        queryParameters: {'subdomain': subdomain},
      );
      
      LoggerService.i('Tenant check response: ${response.data}');
      
      if (response.data != null && response.data!['exists'] == true) {
        LoggerService.i('Tenant exists: $subdomain');
        // Por enquanto, vamos retornar um modelo básico com o subdomain
        // já que a API só retorna exists e tenantId
        return TenantModel(
          id: 1, // TODO: usar o tenantId real quando a API retornar mais dados
          nome: subdomain,
          subdomain: subdomain,
          razaoSocial: subdomain,
          cnpj: '00.000.000/0000-00',
          ativo: true,
          createdAt: DateTime.now(),
        );
      }
      
      LoggerService.w('Tenant not found: $subdomain');
      return null;
    } catch (e) {
      LoggerService.e('Error checking tenant: $subdomain', e);
      rethrow;
    }
  }
}