import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/tenant_theme_provider.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/tenant_provider.dart';

/// Tela de configuração inicial do tenant (gabinete).
class TenantSetupPage extends ConsumerStatefulWidget {
  const TenantSetupPage({super.key});

  @override
  ConsumerState<TenantSetupPage> createState() => _TenantSetupPageState();
}

class _TenantSetupPageState extends ConsumerState<TenantSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _subdomainController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _subdomainController.dispose();
    super.dispose();
  }

  String? _extractSubdomain(String input) {
    // Remove protocolo e espaços
    var clean = input.trim().replaceAll(RegExp(r'https?://'), '');
    clean = clean.replaceAll('www.', '').replaceAll(RegExp(r'/$'), '');

    if (clean.contains('gabiflow.com.br')) {
      final parts = clean.split('.');
      if (parts.length >= 3) return parts.first;
      return null;
    }

    // Assume que digitou apenas o subdomain
    if (!clean.contains('.')) return clean.isEmpty ? null : clean;
    return null;
  }

  Future<void> _continuar() async {
    if (!_formKey.currentState!.validate()) return;

    final subdomain = _extractSubdomain(_subdomainController.text);
    if (subdomain == null) {
      _showError('Endereço inválido. Use o formato: seu-gabinete');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final exists = await ref.read(checkTenantProvider(subdomain).future);

      if (!mounted) return;

      if (exists) {
        await StorageService.saveTenantConfig({
          'subdomain': subdomain,
          'url': '$subdomain.gabiflow.com.br',
        });
        // Aplica a identidade visual do gabinete antes de abrir o login
        // (silencioso em caso de falha — segue com a cor padrão).
        final seed = ref.read(tenantSeedProvider.notifier);
        seed.reset();
        await seed.refreshFromServer(subdomain);
        if (!mounted) return;
        context.go('/login/$subdomain');
      } else {
        _showError('Gabinete "$subdomain" não encontrado.');
      }
    } catch (e) {
      if (mounted) _showError('Erro ao verificar gabinete: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _abrirSite() async {
    final uri = Uri.parse('https://www.gabiflow.com.br');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _showError('Não foi possível abrir o site');
    } catch (_) {
      if (mounted) _showError('Não foi possível abrir o site');
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar gabinete'),
        leading: Navigator.canPop(context)
            ? const BackButton()
            : null,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH,
              vertical: AppSpacing.screenV,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                // Logotipo textual
                Text(
                  'GabiFlow',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ).animate().fadeIn(duration: 500.ms),

                const SizedBox(height: AppSpacing.xl),

                // Título
                Text(
                  'Bem-vindo ao GabiFlow',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

                const SizedBox(height: AppSpacing.sm),

                // Subtítulo
                Text(
                  'Informe o endereço do seu gabinete para começar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.neutral600Dark
                            : AppColors.neutral600Light,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

                const SizedBox(height: AppSpacing.xxl),

                // Campo subdomain com sufixo estático
                AppInputField(
                  label: 'Endereço do gabinete',
                  controller: _subdomainController,
                  hintText: 'seugabinete',
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _continuar(),
                  suffix: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        '.gabiflow.com.br',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.neutral600Dark
                                  : AppColors.neutral600Light,
                            ),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o endereço do gabinete';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 250.ms, duration: 500.ms).slideY(
                      begin: 0.1,
                      end: 0,
                    ),

                const SizedBox(height: AppSpacing.lg),

                PrimaryButton(
                  label: 'Continuar →',
                  onPressed: _isLoading ? null : _continuar,
                  isLoading: _isLoading,
                ).animate().fadeIn(delay: 350.ms, duration: 500.ms),

                const SizedBox(height: AppSpacing.md),

                // Sem acesso ainda → site institucional
                Center(
                  child: GestureDetector(
                    onTap: _abrirSite,
                    child: Text(
                      'Não tenho acesso ainda',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.underline,
                            color: cs.primary,
                          ),
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 500.ms),

                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
