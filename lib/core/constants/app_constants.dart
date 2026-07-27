/// Constantes globais da aplicação
class AppConstants {
  // App Info
  static const String appName = 'GabiFlow';
  static const String appVersion = '1.0.0';
  
  // API Endpoints
  static const String devApiUrl = 'http://192.168.40.50:3001';
  static const String prodApiUrl = 'https://gabiflow.com.br';
  
  // Storage Keys
  static const String tenantConfigKey = 'tenant_config';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Cache
  static const Duration cacheValidDuration = Duration(minutes: 10);
}