import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

/// Provider para ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Incrementado toda vez que o app volta do background (resumed), depois de
/// o token ter sido renovado se necessario. Notifiers com conexao viva
/// (SSE/polling da central) escutam para reconectar e recarregar na hora.
final appRetomadoProvider = StateProvider<int>((_) => 0);
