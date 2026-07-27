import 'package:dio/dio.dart';

import '../services/logger_service.dart';

/// Interceptor para lidar com redirecionamentos HTTPS
class RedirectInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Se for erro de redirect limit exceeded
    if (err.error.toString().contains('RedirectException') || 
        err.error.toString().contains('Redirect limit exceeded')) {
      LoggerService.w('Redirect detected, trying HTTPS directly');
      
      final options = err.requestOptions;
      
      // Se a URL já é HTTPS, não tenta novamente
      if (options.uri.scheme == 'https') {
        handler.next(err);
        return;
      }
      
      // Converte HTTP para HTTPS
      final httpsUri = options.uri.replace(scheme: 'https');
      
      LoggerService.i('Retrying with HTTPS: $httpsUri');
      
      // Cria nova requisição com HTTPS
      final newOptions = options.copyWith(
        path: httpsUri.toString(),
      );
      
      // Tenta novamente com HTTPS
      handler.resolve(
        Response(
          requestOptions: newOptions,
          statusCode: 301,
          statusMessage: 'Redirect to HTTPS',
        ),
      );
    } else {
      handler.next(err);
    }
  }
}