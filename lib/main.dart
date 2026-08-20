import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tenant_theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Variáveis de ambiente
  await dotenv.load(fileName: '.env');

  // Cache local
  await Hive.initFlutter();
  // Abre boxes necessários antes do ProviderScope
  await Hive.openBox<dynamic>('electoral_selection');
  await Hive.openBox<dynamic>('command_center');

  // Secure storage + preferências
  await StorageService.init();

  // Cor do gabinete salva — semeia o tema sem flash da cor padrão
  final initialSeed = await loadSavedSeedColor();

  runApp(
    ProviderScope(
      overrides: [
        tenantSeedProvider
            .overrideWith((ref) => TenantSeedNotifier(initialSeed)),
      ],
      child: const GabiFlowApp(),
    ),
  );
}

class GabiFlowApp extends ConsumerWidget {
  const GabiFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
      routerConfig: appRouter,
    );
  }
}
