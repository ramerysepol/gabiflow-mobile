import 'package:logger/logger.dart';

/// Serviço de logging customizado
class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.trace,
  );
  
  /// Log de debug
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log de informação
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log de warning
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log de erro
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log de erro fatal
  static void f(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log de trace (muito detalhado)
  static void t(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }
}