import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_validation_datasource.dart';
import '../../data/models/user_model.dart';

/// Provider para o AuthRemoteDataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
});

/// Provider para o AuthValidationDataSource
final authValidationDataSourceProvider = Provider<AuthValidationDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthValidationDataSourceImpl(apiClient);
});

/// Estado de autenticação
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? error;
  
  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
  });
  
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

/// Provider de autenticação
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRemoteDataSource _authDataSource;
  final AuthValidationDataSource _authValidationDataSource;
  
  AuthNotifier(this._authDataSource, this._authValidationDataSource) : super(const AuthState()) {
    _checkAuthStatus();
  }
  
  /// Verifica se o usuário já está autenticado
  Future<void> _checkAuthStatus() async {
    final token = await StorageService.getAccessToken();
    final userData = await StorageService.getUserData();
    final tenantConfig = await StorageService.getTenantConfig();
    
    if (token != null && userData != null && tenantConfig != null) {
      // Valida o token no backend
      final tenantId = tenantConfig['subdomain'] as String?;
      if (tenantId != null) {
        UserModel? validUser;
        var erroTransporte = false;
        try {
          validUser =
              await _authValidationDataSource.validateToken(token, tenantId);
        } catch (_) {
          // Rede indisponível: mantém a sessão local em vez de limpar
          erroTransporte = true;
        }

        if (erroTransporte) {
          state = state.copyWith(
            isAuthenticated: true,
            user: UserModel.fromJson(userData),
          );
        } else if (validUser != null) {
          // Garantir que o tenant está definido no usuário
          final userJson = validUser.toJson();
          if (userJson['tenant'] == null || userJson['tenant'].toString().isEmpty) {
            userJson['tenant'] = tenantId;
          }
          if (userJson['tenant_id'] == null || userJson['tenant_id'].toString().isEmpty) {
            userJson['tenant_id'] = tenantId;
          }
          
          // Token válido, atualiza os dados do usuário
          await StorageService.saveUserData(userJson);
          final updatedUser = UserModel.fromJson(userJson);
          
          state = state.copyWith(
            isAuthenticated: true,
            user: updatedUser,
          );
        } else {
          // Token inválido, limpa tudo
          await _clearAuthData();
        }
      } else {
        await _clearAuthData();
      }
    }
  }
  
  /// Limpa dados de autenticação (preserva tenant)
  Future<void> _clearAuthData() async {
    await StorageService.clearAuthDataOnly();
    state = const AuthState();
  }
  
  /// Faz login
  Future<bool> login({
    required String email,
    required String password,
    required String tenantId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authDataSource.login(
        email: email,
        password: password,
        tenantId: tenantId,
      );
      
      // Salva os tokens
      await StorageService.saveAccessToken(response.accessToken);
      await StorageService.saveRefreshToken(response.refreshToken);
      
      // Salva dados do usuário
      await StorageService.saveUserData(response.user.toJson());
      
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: response.user,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
  
  /// Faz logout
  Future<void> logout() async {
    try {
      await _authDataSource.logout();
    } catch (_) {
      // Ignora erros de logout no servidor
    }
    
    // Limpa dados locais
    await _clearAuthData();
  }
  
  /// Limpa erro
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider global de autenticação
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authDataSource = ref.watch(authRemoteDataSourceProvider);
  final authValidationDataSource = ref.watch(authValidationDataSourceProvider);
  return AuthNotifier(authDataSource, authValidationDataSource);
});