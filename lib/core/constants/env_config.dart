/// Configuração de ambiente
/// Não utiliza arquivos .env - configurações diretas no código
class EnvConfig {
  /// Define o ambiente atual - sempre produção para o mobile
  static String get environment => 'production';
  
  static bool get isDevelopment => false;
  static bool get isProduction => true;
  
  /// URL base padrão do sistema
  static String get apiUrl => 'https://gabiflow.com.br';
  
  /// URL WebSocket padrão
  static String get wsUrl => 'wss://gabiflow.com.br';
  
  /// Constrói a URL para um tenant específico
  /// Sempre usa HTTPS mesmo em desenvolvimento
  static String getTenantUrl(String subdomain) {
    return 'https://$subdomain.gabiflow.com.br';
  }
  
  /// Constrói a URL WebSocket para um tenant específico
  static String getTenantWsUrl(String subdomain) {
    return 'wss://$subdomain.gabiflow.com.br';
  }
  
  /// Timeout de conexão - 30 segundos
  static Duration get connectionTimeout => const Duration(milliseconds: 30000);
  
  /// Timeout de recebimento - 30 segundos
  static Duration get receiveTimeout => const Duration(milliseconds: 30000);
}