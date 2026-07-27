import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/logger_service.dart';
import '../models/user_model.dart';

abstract class AuthValidationDataSource {
  /// Valida o token atual e retorna os dados do usuário
  Future<UserModel?> validateToken(String token, String tenantId);
}

class AuthValidationDataSourceImpl implements AuthValidationDataSource {
  final ApiClient _apiClient;

  AuthValidationDataSourceImpl(this._apiClient);

  @override
  Future<UserModel?> validateToken(String token, String tenantId) async {
    try {
      LoggerService.i('Validating token for tenant: $tenantId');

      // Endpoint MOBILE (isento do middleware web — o /api/auth/me legado é
      // interceptado pelo middleware e redireciona para a página de login,
      // o que invalidava sessões válidas no cold start).
      // Em caso de 401, o AuthInterceptor renova o token e refaz sozinho.
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/mobile/auth/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-Tenant-ID': tenantId,
          },
        ),
      );

      final data = response.data;
      if (response.statusCode == 200 &&
          data != null &&
          data['success'] == true &&
          data['user'] is Map) {
        LoggerService.i('Token is valid, user data retrieved');

        final userData =
            Map<String, dynamic>.from(data['user'] as Map<dynamic, dynamic>);
        if (!userData.containsKey('tenant')) {
          userData['tenant'] = tenantId;
        }

        return UserModel.fromJson(userData);
      }

      LoggerService.w(
          'Token validation failed — HTTP ${response.statusCode} ${data?['code'] ?? ''}');
      // null = sessão negada de fato (401 mesmo após auto-refresh)
      return null;
    } catch (e) {
      LoggerService.e('Token validation error (transporte)', e);
      // Erro de rede/transporte NÃO significa sessão inválida — relança para
      // o chamador decidir (manter sessão local em vez de limpar).
      rethrow;
    }
  }
}
