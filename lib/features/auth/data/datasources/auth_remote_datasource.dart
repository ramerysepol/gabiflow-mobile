import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/logger_service.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// Faz login com email e senha
  Future<AuthResponseModel> login({
    required String email,
    required String password,
    required String tenantId,
  });
  
  /// Faz logout
  Future<void> logout();
  
  /// Renova o token
  Future<AuthResponseModel> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;
  
  AuthRemoteDataSourceImpl(this._apiClient);
  
  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
    required String tenantId,
  }) async {
    try {
      LoggerService.i('Attempting login for: $email on tenant: $tenantId');
      
      // Endpoint mobile-específico (sem Turnstile, sem cookies)
      final response = await _apiClient.post<Map<String, dynamic>>(
        'https://$tenantId.gabiflow.com.br/api/mobile/auth/login',
        data: {
          'email': email,
          'password': password,
          'rememberMe': true,
        },
      );
      
      LoggerService.i('Login response received');
      
      if (response.data != null) {
        // A resposta tem uma estrutura específica
        final data = response.data!;
        LoggerService.i('Login response data: $data');
        
        if (data['success'] == true && data['tokens'] != null) {
          // Log detalhado dos tokens
          LoggerService.i('Tokens data: ${data['tokens']}');
          LoggerService.i('User data: ${data['user']}');
          
          // Converter expiresIn para int com verificação mais robusta
          final expiresInValue = data['tokens']['expiresIn'];
          int expiresInInt;
          
          if (expiresInValue == null) {
            expiresInInt = 86400; // Default 1 dia
          } else if (expiresInValue is int) {
            expiresInInt = expiresInValue;
          } else if (expiresInValue is String) {
            expiresInInt = int.tryParse(expiresInValue) ?? 86400;
          } else if (expiresInValue is double) {
            expiresInInt = expiresInValue.toInt();
          } else {
            LoggerService.w('Unexpected expiresIn type: ${expiresInValue.runtimeType}');
            expiresInInt = 86400;
          }
          
          // Adicionar o tenant do contexto ao user data se não vier da API
          final userData = Map<String, dynamic>.from(data['user'] as Map<String, dynamic>);
          // Sempre garantir que o tenant está presente
          if (userData['tenant'] == null || userData['tenant'].toString().isEmpty) {
            userData['tenant'] = tenantId;
          }
          // Também adicionar tenant_id para compatibilidade
          if (userData['tenant_id'] == null || userData['tenant_id'].toString().isEmpty) {
            userData['tenant_id'] = tenantId;
          }
          LoggerService.i('User data with tenant: $userData');
          
          return AuthResponseModel(
            accessToken: data['tokens']['accessToken']?.toString() ?? '',
            refreshToken: data['tokens']['refreshToken']?.toString() ?? '',
            expiresIn: expiresInInt,
            tokenType: data['tokens']['tokenType']?.toString() ?? 'Bearer',
            user: UserModel.fromJson(userData),
          );
        } else {
          throw Exception(data['error'] ?? 'Login failed');
        }
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      LoggerService.e('Login error', e);
      
      // Tratar erros específicos do Dio
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          // Credenciais inválidas
          throw Exception('Email ou senha incorretos');
        } else if (e.response?.statusCode == 400) {
          // Bad request
          final errorData = e.response?.data;
          if (errorData != null && errorData['error'] != null) {
            throw Exception(errorData['error']);
          }
        }
      }
      
      rethrow;
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      await _apiClient.post<void>('/api/mobile/auth/logout');
    } catch (e) {
      LoggerService.e('Logout error', e);
      // Não propaga erro de logout
    }
  }

  @override
  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/mobile/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
      );
      
      if (response.data != null) {
        return AuthResponseModel.fromJson(response.data!);
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      LoggerService.e('Refresh token error', e);
      rethrow;
    }
  }
}