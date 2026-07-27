import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import 'auth_provider.dart';

/// Provider que observa mudanças na autenticação e atualiza o dashboard
final authRefreshProvider = Provider<void>((ref) {
  // Observa mudanças no estado de autenticação
  ref.listen<AuthState>(
    authProvider,
    (previous, next) {
      // Se o usuário acabou de fazer login (não estava autenticado e agora está)
      if (previous?.isAuthenticated == false && next.isAuthenticated == true) {
        // Invalida o provider do dashboard para forçar atualização
        ref.invalidate(dashboardStatsProvider);
      }
    },
  );
});