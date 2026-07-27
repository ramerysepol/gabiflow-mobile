import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/design_tokens.dart';

/// Splash Screen com animações premium e roteamento inicial.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  );

  @override
  void initState() {
    super.initState();
    _progressController.forward();
    _checkInitialSetup();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialSetup() async {
    await Future<void>.delayed(const Duration(milliseconds: 2500));

    final tenantConfig = await StorageService.getTenantConfig();
    LoggerService.i('Splash — tenant config: $tenantConfig');

    if (!mounted) return;

    if (tenantConfig == null) {
      context.go('/tenant-setup');
      return;
    }

    final subdomain = tenantConfig['subdomain'] as String?;
    if (subdomain == null) {
      context.go('/tenant-setup');
      return;
    }

    final token = await StorageService.getAccessToken();
    final refreshToken = await StorageService.getRefreshToken();
    if (!mounted) return;

    if (token == null && (refreshToken == null || refreshToken.isEmpty)) {
      context.go('/login/$subdomain');
      return;
    }

    // Valida a sessão de verdade: chama /auth/me. Se o access token expirou,
    // o AuthInterceptor renova via refresh token e refaz a chamada sozinho.
    final sessaoValida = await _validarSessao(subdomain);
    if (!mounted) return;

    if (sessaoValida) {
      context.go('/home');
    } else {
      // Sessão irrecuperável (refresh expirado/revogado) → login
      await StorageService.clearAuthDataOnly();
      if (!mounted) return;
      context.go('/login/$subdomain');
    }
  }

  Future<bool> _validarSessao(String subdomain) async {
    try {
      final client = ApiClient();
      client.updateBaseUrl(subdomain);
      final res = await client.get<Map<String, dynamic>>(
        '/api/mobile/auth/me',
      );
      final data = res.data;
      final ok = res.statusCode == 200 &&
          data != null &&
          data['success'] == true &&
          data['user'] is Map;
      if (ok) {
        // Atualiza os dados do usuário salvos (nome/avatar no header da home)
        await StorageService.saveUserData(
          (data['user'] as Map).cast<String, dynamic>(),
        );
      }
      LoggerService.i('Splash — sessão válida: $ok');
      return ok;
    } catch (e) {
      LoggerService.e('Splash — erro ao validar sessão', e);
      // Erro de rede (offline): deixa entrar com o token existente para não
      // bloquear o uso; as telas mostram seus próprios estados de erro.
      final token = await StorageService.getAccessToken();
      return token != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDefaultDark : AppColors.surfaceDefaultLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo 3D oficial GabiFlow
              Image.asset(
                'assets/images/gabiflow-hd.png',
                width: 260,
                fit: BoxFit.contain,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 700.ms)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1.0, 1.0),
                    duration: 700.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .then(delay: 200.ms)
                  .shimmer(
                    duration: 1400.ms,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 200,
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (_, __) => LinearProgressIndicator(
                    value: _progressController.value,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Carregando...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.neutral600Dark
                          : AppColors.neutral600Light,
                    ),
              ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

