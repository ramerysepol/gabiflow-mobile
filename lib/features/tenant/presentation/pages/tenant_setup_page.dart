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
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/tenant_provider.dart';

/// Tela de entrada do app — a primeira impressão do produto.
/// Hero escuro "war room" com logo animada, vitrine do que o GabiFlow faz
/// e o cartão de acesso ao gabinete.
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
                vertical: AppSpacing.screenV,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                  // ── Logo animada: entrada suave + pulso contínuo ─────────
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3949AB)
                                .withValues(alpha: 0.35),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const AppLogo(height: 64)
                          .animate(
                            onPlay: (c) => c.repeat(reverse: true),
                          )
                          .scaleXY(
                            begin: 0.97,
                            end: 1.05,
                            duration: 2200.ms,
                            curve: Curves.easeInOut,
                          ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 700.ms)
                      .scale(begin: const Offset(0.7, 0.7)),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Marca + tagline ──────────────────────────────────────
                  Text(
                    'GabiFlow',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

                  const SizedBox(height: 6),

                  Text(
                    'O gabinete inteiro no seu bolso',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ).animate().fadeIn(delay: 250.ms, duration: 500.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Vitrine (como no login web) ──────────────────────────
                  const _Destaque(
                    icone: Icons.chat_rounded,
                    cor: Color(0xFF25D366),
                    titulo: 'Central de Atendimento',
                    texto: 'WhatsApp do gabinete com sua equipe',
                  ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.08),
                  const SizedBox(height: 10),
                  const _Destaque(
                    icone: Icons.local_fire_department_rounded,
                    cor: Color(0xFFEF6C00),
                    titulo: 'Dados Eleitorais',
                    texto: 'Mapa de calor e análises com dados do TSE',
                  ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.08),
                  const SizedBox(height: 10),
                  const _Destaque(
                    icone: Icons.people_rounded,
                    cor: Color(0xFF42A5F5),
                    titulo: 'Munícipes e Demandas',
                    texto: 'Sua base organizada, do contato à entrega',
                  ).animate().fadeIn(delay: 550.ms).slideX(begin: -0.08),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Cartão de acesso ─────────────────────────────────────
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
                        Text(
                          'Acesse seu gabinete',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppInputField(
                          label: 'Endereço do gabinete',
                          controller: _subdomainController,
                          hintText: 'seugabinete',
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _continuar(),
                          suffix: Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.sm),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                '.gabiflow.com.br',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.outline),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o endereço do gabinete';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        PrimaryButton(
                          label: 'Continuar →',
                          onPressed: _isLoading ? null : _continuar,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 650.ms, duration: 500.ms)
                      .slideY(begin: 0.08, end: 0),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Sem acesso ainda → site institucional ────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _abrirSite,
                      child: Text.rich(
                        TextSpan(
                          text: 'Ainda não tem GabiFlow?  ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          children: const [
                            TextSpan(
                              text: 'Conheça o produto',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms, duration: 500.ms),

                  SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom + 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Linha de destaque da vitrine: ícone colorido + título + texto curto.
class _Destaque extends StatelessWidget {
  const _Destaque({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.texto,
  });

  final IconData icone;
  final Color cor;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, size: 20, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  texto,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
