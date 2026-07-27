import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/design_tokens.dart';

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

  runApp(
    const ProviderScope(
      child: GabiFlowApp(),
    ),
  );
}

class GabiFlowApp extends ConsumerWidget {
  const GabiFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A cor semente poderá ser alterada dinamicamente via provider de tenant.
    const seedColor = AppColors.defaultSeed;

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
      routerConfig: appRouter,
    );
  }
}
