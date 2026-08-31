import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/env_config.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';
import 'auth_interceptor.dart';

/// Cliente HTTP base para todas as requisições
class ApiClient {
  late final Dio _dio;
  String? _currentTenantSubdomain;
  
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiUrl, // URL padrão inicial
        connectTimeout: EnvConfig.connectionTimeout,
        receiveTimeout: EnvConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Habilita redirecionamento automático
        followRedirects: true,
        maxRedirects: 5, // Permite até 5 redirecionamentos
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );
    
    LoggerService.i('ApiClient initialized with default baseUrl: ${EnvConfig.apiUrl}');
    
    // Adiciona interceptors
    _dio.interceptors.addAll([
      AuthInterceptor(),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    ]);
    
    // Carrega configuração do tenant ao inicializar
    _loadTenantConfig();
  }
  
  /// Carrega e atualiza a URL baseada no tenant configurado
  Future<void> _loadTenantConfig() async {
    final tenantConfig = await StorageService.getTenantConfig();
    if (tenantConfig != null && tenantConfig['subdomain'] != null) {
      final subdomain = tenantConfig['subdomain'] as String;
      updateBaseUrl(subdomain);
    }
  }
  
  /// Atualiza a baseUrl quando o tenant muda
  void updateBaseUrl(String subdomain) {
    _currentTenantSubdomain = subdomain;
    final newBaseUrl = EnvConfig.getTenantUrl(subdomain);
    _dio.options.baseUrl = newBaseUrl;
    LoggerService.i('ApiClient baseUrl updated to: $newBaseUrl');
  }
  
  /// Normaliza a resposta: se vier como String (content-type mal servido),
  /// faz jsonDecode manualmente. Detecta HTML (proxy/erro 5xx servido como HTML).
  /// Sempre constrói uma nova Response<T> para evitar cast entre generics.
  Response<T> _normalizeResponse<T>(Response response, String path) {
    dynamic data = response.data;

    if (data is String) {
      if (data.contains('<!DOCTYPE') || data.contains('<html')) {
        LoggerService.e('Received HTML response instead of JSON for: $path');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Received HTML instead of JSON',
        );
      }
      if (data.isEmpty) {
        data = null;
      } else {
        try {
          data = jsonDecode(data);
        } catch (jsonError) {
          LoggerService.e('Failed to parse JSON response: $jsonError');
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Invalid JSON response',
          );
        }
      }
    }

    return Response<T>(
      data: data as T?,
      headers: response.headers,
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      extra: response.extra,
    );
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      LoggerService.i('Request: GET $path');
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      LoggerService.i('Response status: ${response.statusCode} | type: ${response.data.runtimeType}');
      return _normalizeResponse<T>(response, path);
    } on DioException catch (e) {
      LoggerService.e('GET Error: $path', e);
      rethrow;
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      LoggerService.i('Request: POST $path');
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      LoggerService.i('Response status: ${response.statusCode} | type: ${response.data.runtimeType}');
      return _normalizeResponse<T>(response, path);
    } on DioException catch (e) {
      LoggerService.e('POST Error: $path', e);
      rethrow;
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _normalizeResponse<T>(response, path);
    } on DioException catch (e) {
      LoggerService.e('PUT Error: $path', e);
      rethrow;
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _normalizeResponse<T>(response, path);
    } on DioException catch (e) {
      LoggerService.e('DELETE Error: $path', e);
      rethrow;
    }
  }

  /// POST com resposta em streaming (SSE).
  /// Retorna o corpo bruto como [ResponseBody] para o chamador consumir
  /// o stream de bytes (ex.: chat da IA com text/event-stream).
  Future<Response<ResponseBody>> postStream(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    try {
      LoggerService.i('Request: POST (stream) $path');
      return await _dio.post<ResponseBody>(
        path,
        data: data,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
          // Streams longos: sem timeout entre chunks (o servidor manda keepalive)
          receiveTimeout: Duration.zero,
        ),
      );
    } on DioException catch (e) {
      LoggerService.e('POST Stream Error: $path', e);
      rethrow;
    }
  }

  /// GET com resposta em streaming (SSE) — ex.: /api/whatsapp/sse.
  /// Retorna o corpo bruto como [ResponseBody] para o chamador ler os bytes.
  Future<Response<ResponseBody>> getStream(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      LoggerService.i('Request: GET (stream) $path');
      final base = options ?? Options();
      return await _dio.get<ResponseBody>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: base.copyWith(
          responseType: ResponseType.stream,
          headers: {...?base.headers, 'Accept': 'text/event-stream'},
          receiveTimeout: Duration.zero,
        ),
      );
    } on DioException catch (e) {
      LoggerService.e('GET Stream Error: $path', e);
      rethrow;
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _normalizeResponse<T>(response, path);
    } on DioException catch (e) {
      LoggerService.e('PATCH Error: $path', e);
      rethrow;
    }
  }
}