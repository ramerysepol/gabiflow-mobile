import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Serviço de armazenamento seguro
class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  static SharedPreferences? _prefs;
  
  /// Inicializa o SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // ===== Secure Storage (para dados sensíveis) =====
  
  /// Salva o token de acesso
  static Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: AppConstants.accessTokenKey, value: token);
  }
  
  /// Recupera o token de acesso
  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.accessTokenKey);
  }
  
  /// Salva o refresh token
  static Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: token);
  }
  
  /// Recupera o refresh token
  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.refreshTokenKey);
  }
  
  /// Salva a configuração do tenant
  static Future<void> saveTenantConfig(Map<String, dynamic> config) async {
    final jsonString = jsonEncode(config);
    await _secureStorage.write(key: AppConstants.tenantConfigKey, value: jsonString);
  }
  
  /// Recupera a configuração do tenant
  static Future<Map<String, dynamic>?> getTenantConfig() async {
    final jsonString = await _secureStorage.read(key: AppConstants.tenantConfigKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }
  
  /// Salva dados do usuário
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _secureStorage.write(key: AppConstants.userDataKey, value: jsonString);
  }
  
  /// Recupera dados do usuário
  static Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _secureStorage.read(key: AppConstants.userDataKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }
  
  /// Limpa as configurações do tenant
  static Future<void> clearTenantConfig() async {
    await _secureStorage.delete(key: AppConstants.tenantConfigKey);
  }
  
  /// Limpa apenas dados de autenticação (preserva tenant)
  static Future<void> clearAuthDataOnly() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _secureStorage.delete(key: AppConstants.userDataKey);
  }
  
  /// Salva credenciais para login biométrico (por usuário + tenant).
  static Future<void> saveBiometricCredentials(
    String email,
    String password, {
    String? tenant,
  }) async {
    final credentials = {
      'email': email,
      'password': password,
      if (tenant != null) 'tenant': tenant,
    };
    await _secureStorage.write(
      key: 'biometric_credentials',
      value: jsonEncode(credentials),
    );
  }

  /// Recupera credenciais biométricas (email, password e tenant quando houver)
  static Future<Map<String, String>?> getBiometricCredentials() async {
    final jsonString = await _secureStorage.read(key: 'biometric_credentials');
    if (jsonString != null) {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return {
        'email': data['email'] as String,
        'password': data['password'] as String,
        if (data['tenant'] != null) 'tenant': data['tenant'] as String,
      };
    }
    return null;
  }
  
  /// Limpa credenciais biométricas
  static Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: 'biometric_credentials');
  }
  
  /// Limpa todos os dados seguros (logout/reset)
  /// USAR APENAS quando o usuário clicar em "Mudar Gabinete"
  static Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }
  
  // ===== SharedPreferences (para dados não sensíveis) =====
  
  /// Salva o tema selecionado
  static Future<void> saveThemeMode(String mode) async {
    await _prefs?.setString(AppConstants.themeKey, mode);
  }
  
  /// Recupera o tema selecionado
  static String? getThemeMode() {
    return _prefs?.getString(AppConstants.themeKey);
  }
  
  /// Salva uma preferência string
  static Future<void> saveString(String key, String value) async {
    await _prefs?.setString(key, value);
  }
  
  /// Recupera uma preferência string
  static String? getString(String key) {
    return _prefs?.getString(key);
  }
  
  /// Salva uma preferência bool
  static Future<void> saveBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }
  
  /// Recupera uma preferência bool
  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }
  
  /// Limpa todas as preferências
  static Future<void> clearPreferences() async {
    await _prefs?.clear();
  }
  
  /// Limpa todos os dados (secure + preferences)
  static Future<void> clearAll() async {
    await clearSecureStorage();
    await clearPreferences();
  }
}