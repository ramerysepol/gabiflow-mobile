import 'package:local_auth/local_auth.dart';

import '../services/logger_service.dart';
import '../services/storage_service.dart';

/// Serviço para gerenciar autenticação biométrica
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  
  /// Verifica se o dispositivo suporta biometria
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      LoggerService.e('Error checking biometric support', e);
      return false;
    }
  }
  
  /// Verifica se existe biometria cadastrada no dispositivo
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      LoggerService.e('Error checking biometrics availability', e);
      return false;
    }
  }
  
  /// Lista os tipos de biometria disponíveis
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      LoggerService.e('Error getting available biometrics', e);
      return [];
    }
  }
  
  /// Verifica se a biometria está habilitada para o app
  static Future<bool> isBiometricEnabled() async {
    final enabled = StorageService.getBool('biometric_enabled') ?? false;
    
    // Verifica também se ainda está disponível no dispositivo
    if (enabled) {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        // Se não está mais disponível, desabilita
        await setBiometricEnabled(false);
        return false;
      }
    }
    
    return enabled;
  }
  
  /// Habilita ou desabilita a biometria
  static Future<void> setBiometricEnabled(bool enabled) async {
    await StorageService.saveBool('biometric_enabled', enabled);
    
    if (!enabled) {
      // Se desabilitou, remove as credenciais biométricas
      await StorageService.clearBiometricCredentials();
    }
  }
  
  /// Autentica usando biometria
  static Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        LoggerService.w('Biometric authentication not supported');
        return false;
      }
      
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        LoggerService.w('No biometrics enrolled');
        return false;
      }
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      
      return authenticated;
    } catch (e) {
      LoggerService.e('Error during biometric authentication', e);
      return false;
    }
  }
  
  /// Solicita permissão e configura biometria após o primeiro login
  static Future<bool> setupBiometricAfterLogin({
    required String email,
    required String password,
    String? tenant,
  }) async {
    try {
      // Verifica se o dispositivo suporta
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;
      
      // Verifica se tem biometria cadastrada
      final canCheck = await canCheckBiometrics();
      if (!canCheck) return false;
      
      // Autentica para confirmar que é o usuário
      final authenticated = await authenticate(
        reason: 'Configure a biometria para acessar o GabiFlow mais rapidamente',
      );
      
      if (authenticated) {
        // Salva as credenciais de forma segura (por usuário + tenant)
        await StorageService.saveBiometricCredentials(email, password,
            tenant: tenant);
        await setBiometricEnabled(true);
        
        LoggerService.i('Biometric authentication configured successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      LoggerService.e('Error setting up biometric authentication', e);
      return false;
    }
  }
  
  /// Faz login usando biometria
  static Future<BiometricLoginResult> loginWithBiometric() async {
    try {
      // Verifica se está habilitada
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        return BiometricLoginResult(
          success: false,
          error: 'Biometria não está habilitada',
        );
      }
      
      // Autentica
      final authenticated = await authenticate(
        reason: 'Use sua biometria para entrar no GabiFlow',
      );
      
      if (!authenticated) {
        return BiometricLoginResult(
          success: false,
          error: 'Autenticação biométrica falhou',
        );
      }
      
      // Recupera as credenciais
      final credentials = await StorageService.getBiometricCredentials();
      if (credentials == null) {
        // Se não tem credenciais, desabilita a biometria
        await setBiometricEnabled(false);
        return BiometricLoginResult(
          success: false,
          error: 'Credenciais não encontradas. Configure a biometria novamente.',
        );
      }
      
      return BiometricLoginResult(
        success: true,
        email: credentials['email'],
        password: credentials['password'],
      );
    } catch (e) {
      LoggerService.e('Error during biometric login', e);
      return BiometricLoginResult(
        success: false,
        error: 'Erro ao fazer login com biometria',
      );
    }
  }
}

/// Resultado do login biométrico
class BiometricLoginResult {
  final bool success;
  final String? email;
  final String? password;
  final String? error;
  
  BiometricLoginResult({
    required this.success,
    this.email,
    this.password,
    this.error,
  });
}