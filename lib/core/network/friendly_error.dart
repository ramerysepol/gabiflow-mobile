import 'package:dio/dio.dart';

/// Converte exceções técnicas em uma frase curta e humana para SnackBars e
/// telas de erro. Nunca mostrar `$e`/`e.toString()` direto ao usuário — um
/// DioException de 522 vira um "tijolo" técnico ilegível (visto em produção
/// na queda do servidor de 02/09/2026).
String mensagemAmigavel(Object erro) {
  if (erro is DioException) {
    switch (erro.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'A conexão demorou demais. Verifique sua internet e tente de novo.';
      case DioExceptionType.connectionError:
        return 'Sem conexão com a internet.';
      case DioExceptionType.badCertificate:
        return 'Falha de segurança na conexão. Tente novamente.';
      case DioExceptionType.cancel:
        return 'Operação cancelada.';
      case DioExceptionType.badResponse:
        final code = erro.response?.statusCode ?? 0;
        if (code >= 500) {
          return 'O servidor está indisponível no momento. Tente de novo em instantes.';
        }
        if (code == 401 || code == 403) {
          return 'Acesso não autorizado. Entre novamente.';
        }
        if (code == 429) {
          return 'Muitas tentativas seguidas. Aguarde um pouco.';
        }
        // 4xx com mensagem legível vinda do backend (ex.: {error: '...'}).
        final data = erro.response?.data;
        if (data is Map) {
          final msg = data['error'] ?? data['message'];
          if (msg is String && msg.trim().isNotEmpty && msg.length <= 200) {
            return msg;
          }
        }
        return 'Não foi possível concluir (erro $code).';
      case DioExceptionType.unknown:
        return 'Falha de rede. Verifique sua internet e tente novamente.';
    }
  }
  return 'Algo deu errado. Tente novamente.';
}
