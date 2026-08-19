import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/tenant_theme_provider.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_refresh_provider.dart';

/// Tela de Login — hero escuro no padrão do sistema, lógica de auth preservada.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, required this.tenantSubdomain});

  final String tenantSubdomain;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    ref.read(authRefreshProvider);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final supported = await BiometricService.isDeviceSupported();
    final canCheck = await BiometricService.canCheckBiometrics();
    final enabled = await BiometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = supported && canCheck;
        _biometricEnabled = enabled;
      });
    }
  }

  // ----- handlers (lógica original preservada) -----

  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await BiometricService.loginWithBiometric();
      if (!mounted) return;

      if (result.success && result.email != null && result.password != null) {
        final ok = await ref.read(authProvider.notifier).login(
              email: result.email!,
              password: result.password!,
              tenantId: widget.tenantSubdomain,
            );
        if (!mounted) return;
        if (ok) {
          // Aplica a preferência de tema do usuário em segundo plano
          ref
              .read(tenantSeedProvider.notifier)
              .refreshFromServer(widget.tenantSubdomain);
          context.go('/home');
        } else {
          _showError(ref.read(authProvider).error ?? 'Erro ao fazer login');
        }
      } else {
        _showError(result.error ?? 'Erro na autenticação biométrica');
      }
    } catch (e) {
      LoggerService.e('Erro no login biométrico', e);
      if (mounted) _showError('Erro ao fazer login com biometria');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final ok = await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            tenantId: widget.tenantSubdomain,
          );
      if (!mounted) return;

      if (ok) {
        // Oferece configurar biometria se não habilitada
        if (_biometricAvailable && !_biometricEnabled) {
          final setup = await _showBiometricDialog();
          if (setup == true) {
            await BiometricService.setupBiometricAfterLogin(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
          }
        }
        if (!mounted) return;
        // Aplica a preferência de tema do usuário em segundo plano
        ref
            .read(tenantSeedProvider.notifier)
            .refreshFromServer(widget.tenantSubdomain);
        context.go('/home');
      } else {
        final error = ref.read(authProvider).error;
        _showError(_parseError(error));
      }
    } catch (e) {
      if (mounted) _showError(_parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String? error) {
    if (error == null) return 'Erro ao fazer login';
    if (error.contains('Email ou senha incorretos') || error.contains('401')) {
      return 'E-mail ou senha incorretos';
    }
    return error;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.dangerDark
            : AppColors.dangerLight,
      ),
    );
  }

  Future<bool?> _showBiometricDialog() => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Configurar Biometria'),
          content: const Text(
            'Deseja usar sua biometria para fazer login mais rapidamente nas próximas vezes?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Agora não'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Configurar'),
            ),
          ],
        ),
      );

  Future<void> _trocarGabinete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trocar de Gabinete'),
        content: const Text(
          'Ao trocar de gabinete, você será desconectado. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await StorageService.clearSecureStorage();
      if (mounted) context.go('/tenant-setup');
    }
  }

  // ----- UI -----

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F17), Color(0xFF16213E), Color(0xFF1B2B4D)],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Voltar
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/tenant-setup'),
                    ),
                  ),

                  // Monograma do gabinete tingido pela cor do tenant
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.modal),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(cs.primary, Colors.white, 0.15)!,
                            cs.primary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.45),
                            blurRadius: 36,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.tenantSubdomain.isNotEmpty
                              ? widget.tenantSubdomain[0].toUpperCase()
                              : 'G',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms).scale(
                        begin: const Offset(0.85, 0.85),
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: AppSpacing.lg),

                  // Identificação do gabinete
                  Text(
                    widget.tenantSubdomain.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: AppSpacing.xs),

                  const Text(
                    'Bem-vindo de volta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 130.ms, duration: 400.ms),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    'Acesse sua conta para continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Cartão do formulário ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppInputField(
                          label: 'E-mail',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe seu e-mail';
                            }
                            if (!v.contains('@')) return 'E-mail inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppInputField(
                          label: 'Senha',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          onFieldSubmitted: (_) => _handleLogin(),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe sua senha';
                            }
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: implementar recuperação de senha
                            },
                            child: const Text('Esqueci minha senha'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        PrimaryButton(
                          label: 'Entrar',
                          onPressed: _isLoading ? null : _handleLogin,
                          isLoading: _isLoading,
                        ),
                        if (_biometricAvailable && _biometricEnabled) ...[
                          const SizedBox(height: AppSpacing.md),
                          _Divider(),
                          const SizedBox(height: AppSpacing.md),
                          PrimaryButton(
                            label: 'Entrar com biometria',
                            icon: Icons.fingerprint,
                            variant: PrimaryButtonVariant.secondary,
                            onPressed:
                                _isLoading ? null : _handleBiometricLogin,
                            isLoading: _isLoading,
                          ),
                        ],
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 500.ms)
                      .slideY(begin: 0.08, end: 0),

                  const SizedBox(height: AppSpacing.lg),

                  Center(
                    child: GestureDetector(
                      onTap: _trocarGabinete,
                      child: Text(
                        'Trocar gabinete',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white38,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                  SizedBox(
                      height:
                          MediaQuery.of(context).viewInsets.bottom + 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'OU',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
