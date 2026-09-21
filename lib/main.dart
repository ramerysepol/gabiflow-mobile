import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:upgrader/upgrader.dart';

import 'core/network/auth_interceptor.dart';
import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tenant_theme_provider.dart';
import 'features/agenda/presentation/providers/event_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/constituents/presentation/providers/constituent_provider.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/demands/presentation/providers/demand_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Exibicao de ponta a ponta (edge-to-edge) em todas as versoes do Android,
  // como o Android 15+ ja faz por padrao com targetSdk 35+. Barras do sistema
  // transparentes; cada tela cuida dos insets com AppBar/SafeArea.
  // No iOS nao muda nada. Recomendacao do Google Play Console.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Startup blindado: uma falha em qualquer init (dotenv, Hive, storage) NUNCA
  // pode travar o app no splash — cada passo degrada com segurança e o app
  // sempre chega até a UI (login). Requisito para passar na revisão das lojas.

  // Variáveis de ambiente
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Cache local
  try {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>('electoral_selection');
    await Hive.openBox<dynamic>('command_center');
  } catch (_) {}

  // Secure storage + preferências
  try {
    await StorageService.init();
  } catch (_) {}

  // Cor do gabinete salva — semeia o tema sem flash da cor padrão
  Color? initialSeed;
  try {
    initialSeed = await loadSavedSeedColor();
  } catch (_) {
    initialSeed = null;
  }

  final seed = initialSeed;
  runApp(
    ProviderScope(
      overrides: [
        // Só sobrescreve se conseguimos ler o seed salvo; senão o provider
        // usa o default (evita erro caso a leitura tenha falhado).
        if (seed != null)
          tenantSeedProvider.overrideWith((ref) => TenantSeedNotifier(seed)),
      ],
      child: const GabiFlowApp(),
    ),
  );
}

class GabiFlowApp extends ConsumerStatefulWidget {
  const GabiFlowApp({super.key});

  @override
  ConsumerState<GabiFlowApp> createState() => _GabiFlowAppState();
}

class _GabiFlowAppState extends ConsumerState<GabiFlowApp>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _sessaoSub;

  /// Verificador de versão (mesmo padrão do PagMeia): consulta a Play Store /
  /// App Store pela versão publicada deste pacote e avisa o usuário para
  /// atualizar. Para FORÇAR uma versão mínima sem publicar app novo, basta
  /// incluir a tag `[:mav: 1.2.0]` na descrição do app nas lojas — o
  /// upgrader lê de lá e bloqueia versões abaixo dela.
  final _upgrader = Upgrader(
    durationUntilAlertAgain: const Duration(hours: 12),
    countryCode: 'BR',
    languageCode: 'pt',
    messages: UpgraderMessages(code: 'pt'),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Sessão encerrada pelo servidor (refresh negado): leva ao login. Sem
    // isto o app ficava "logado" com sessão morta e toda tela dava erro.
    _sessaoSub = AuthInterceptor.onSessaoExpirada.listen((_) => _irParaLogin());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessaoSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _aoRetomar();
  }

  Future<void> _aoRetomar() async {
    // 1) Access token (1h) vencido ou perto de vencer: renova ANTES de as
    //    telas dispararem requisições (evita N 401 + refresh em cascata).
    await AuthInterceptor.renovarSeNecessario();
    if (!mounted) return;
    // 2) Avisa quem mantém conexão viva (SSE/polling da central) para
    //    reconectar e recarregar na hora, em vez de esperar o backoff.
    ref.read(appRetomadoProvider.notifier).state++;
  }

  Future<void> _irParaLogin() async {
    ref.read(authProvider.notifier).marcarSessaoExpirada();
    final tenant = await StorageService.getTenantConfig();
    final sub = tenant?['subdomain'] as String?;
    final atual = appRouter.routerDelegate.currentConfiguration.uri.path;
    // Splash/login/setup já cuidam do próprio fluxo.
    if (atual == '/' || atual == '/tenant-setup' || atual.startsWith('/login')) {
      return;
    }
    appRouter.go(sub == null || sub.isEmpty ? '/' : '/login/$sub');
  }

  /// Listas que NAO sao autoDispose (sobrevivem a troca de aba) guardam
  /// dados do gabinete. Ao encerrar a sessao (logout ou sessao expirada)
  /// elas precisam morrer, senao o proximo login em OUTRO tenant mostra
  /// demandas/municipes/agenda do gabinete anterior — e abrir um item da 404.
  void _descartarDadosDaSessao() {
    ref.invalidate(demandListProvider);
    ref.invalidate(constituentListProvider);
    ref.invalidate(eventListProvider);
    ref.invalidate(dashboardStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (anterior, atual) {
      if ((anterior?.isAuthenticated ?? false) && !atual.isAuthenticated) {
        _descartarDadosDaSessao();
      }
    });

    // Cor semente do gabinete (theme_primary_color do desktop),
    // atualizada no setup do tenant e a cada abertura do app.
    final seedColor = ref.watch(tenantSeedProvider);

    return MaterialApp.router(
      title: 'GabiFlow',
      theme: AppTheme.light(seedColor: seedColor),
      darkTheme: AppTheme.dark(seedColor: seedColor),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // App 100% PT-BR: date pickers, textos de componentes Material etc.
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Toque em qualquer área fora de um campo de texto esconde o teclado
      // (comportamento esperado no iOS; no Android também ajuda).
      builder: (context, child) => UpgradeAlert(
        upgrader: _upgrader,
        // Com go_router o alerta precisa do navigator do router para abrir.
        navigatorKey: appRouter.routerDelegate.navigatorKey,
        showIgnore: false,
        // Bloqueado (abaixo da versão mínima): não deixa fechar com "voltar".
        shouldPopScope: () => !_upgrader.blocked(),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
