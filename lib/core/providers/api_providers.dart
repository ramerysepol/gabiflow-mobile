import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

/// Provider para o ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});