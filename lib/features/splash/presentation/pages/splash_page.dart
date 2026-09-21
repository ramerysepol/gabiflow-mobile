import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/tenant_theme_provider.dart';

/// Splash Screen com animações premium e roteamento inicial.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  // Uma unica timeline (0,3 s de espera + 2,2 s = roteamento): fundo, marca
  // descendo + nome subindo ate' formar a logo, brilho e progresso.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final Animation<double> _fundo = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
  );
  // Marca desce e nome sobe ao mesmo tempo, encontrando-se na logo completa.
  late final Animation<double> _encontro = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.05, 0.62, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _brilho = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.62, 0.90, curve: Curves.easeInOut),
  );
  late final Animation<double> _rodape = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.58, 0.78, curve: Curves.easeOut),
  );

  // A logo so' entra no ShaderMask na hora do brilho: o ShaderMask recorta ao
  // proprio tamanho e esconderia as partes vindo de fora. A GlobalKey
  // reparenta o subtree sem recriar as imagens.
  final _logoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Pequena espera antes de animar: garante que o primeiro quadro ja' foi
    // exibido (o splash do sistema Android so' sai depois dele), para o
    // encontro marca + nome nao acontecer "escondido".
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
    _checkInitialSetup();
  }

  @override
  void dispose() {
    _controller.dispose();
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

    // Sincroniza a cor do gabinete em segundo plano (mudanças feitas no
    // desktop chegam aqui a cada abertura do app).
    ref.read(tenantSeedProvider.notifier).refreshFromServer(subdomain);

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
      final res = await client.get<Map<String, dynamic>>('/api/mobile/auth/me');
      final data = res.data;
      final ok =
          res.statusCode == 200 &&
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

  /// Circulo suave de fundo que cresce e aparece junto com a marca.
  Widget _blob(double diametro, Color cor) {
    return Transform.scale(
      scale: 0.7 + 0.3 * _fundo.value,
      child: Opacity(
        opacity: _fundo.value,
        child: Container(
          width: diametro,
          height: diametro,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bg = isDark
        ? AppColors.surfaceDefaultDark
        : AppColors.surfaceDefaultLight;
    final corTexto = isDark
        ? AppColors.neutral600Dark
        : AppColors.neutral600Light;

    // Logo oficial (marca em cima, nome embaixo). A mesma imagem e' recortada
    // em duas partes para animar marca e nome separadamente.
    const proporcao = 2708 / 3907; // altura/largura do PNG
    const corteMarca = 0.69; // fracao superior da imagem = marca "G"
    final largura = math.min(MediaQuery.sizeOf(context).width * 0.66, 280.0);
    final altura = largura * proporcao;

    Widget parte({required bool marca}) {
      return ClipRect(
        child: Align(
          alignment: marca ? Alignment.topCenter : Alignment.bottomCenter,
          heightFactor: marca ? corteMarca : 1 - corteMarca,
          child: Image.asset(
            'assets/images/gabiflow-hd.png',
            width: largura,
            height: altura,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final v = _encontro.value; // 0 = separados, 1 = logo formada
          // Ambas as partes comecam VISIVEIS: a marca perto do topo da tela e
          // o nome perto da base, e percorrem o mesmo caminho ate' se encaixar.
          final alturaTela = MediaQuery.sizeOf(context).height;
          final percurso = ((alturaTela - altura) / 2 - 96).clamp(120.0, 360.0);

          final logo = SizedBox(
            key: _logoKey,
            width: largura,
            height: altura,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Marca "G": desce de cima ate' a posicao final
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, -percurso * (1 - v)),
                    child: parte(marca: true),
                  ),
                ),
                // Nome "GabiFlow": sobe de baixo ate' encaixar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, percurso * (1 - v)),
                    child: parte(marca: false),
                  ),
                ),
              ],
            ),
          );

          return Stack(
            children: [
              // Fundo: dois circulos nas cores do gabinete
              Positioned(
                top: -80,
                left: -70,
                child: _blob(
                  250,
                  cs.primary.withValues(alpha: isDark ? 0.22 : 0.14),
                ),
              ),
              Positioned(
                bottom: -110,
                right: -60,
                child: _blob(
                  300,
                  cs.tertiary.withValues(alpha: isDark ? 0.20 : 0.13),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo (marca + nome), com brilho diagonal no final
                      if (_brilho.value > 0)
                        ShaderMask(
                          blendMode: BlendMode.srcATop,
                          shaderCallback: (rect) {
                            final dx = (_brilho.value * 2.4 - 1.2) * rect.width;
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.55),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0.38, 0.5, 0.62],
                            ).createShader(rect.translate(dx, 0));
                          },
                          child: logo,
                        )
                      else
                        logo,
                      const SizedBox(height: AppSpacing.xl),
                      Opacity(
                        opacity: _rodape.value,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                value: _controller.value,
                                backgroundColor: cs.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Carregando...',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(color: corTexto),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
