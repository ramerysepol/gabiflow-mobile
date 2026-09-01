import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../command_center/presentation/providers/command_center_providers.dart';
import '../providers/eleitoral_providers.dart';

/// Shell do sub-app Eleitoral: "war room" com barra de navegação própria.
///
/// Ao entrar na aba Eleitoral, o dock do GabiFlow some e esta barra assume:
/// Visão · Mapa · Candidatos · Rankings · IA. Só o "✕" (na Visão Geral)
/// devolve ao app normal — exatamente o comportamento de app-dentro-do-app.
class EleitoralShell extends ConsumerWidget {
  const EleitoralShell({super.key, required this.child});

  final Widget child;

  static const _abas = [
    ('/home/eleitoral', Icons.space_dashboard_outlined,
        Icons.space_dashboard_rounded, 'Visão'),
    ('/home/eleitoral/mapa', Icons.local_fire_department_outlined,
        Icons.local_fire_department_rounded, 'Mapa'),
    ('/home/eleitoral/candidatos', Icons.groups_outlined,
        Icons.groups_rounded, 'Candidatos'),
    ('/home/eleitoral/rankings', Icons.leaderboard_outlined,
        Icons.leaderboard_rounded, 'Rankings'),
    ('/home/eleitoral/ia', Icons.auto_awesome_outlined,
        Icons.auto_awesome_rounded, 'IA'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trocou a eleição? Limpa seleções que pertenciam à eleição anterior
    // (candidato do Command Center e filtro de cidade) — sem isso um
    // deputado de 2022 continuava "selecionado" na eleição de 2024.
    ref.listen(selectedElectionProvider, (prev, next) {
      if (prev == null || next == null || prev.label == next.label) return;
      ref.read(iaContextoProvider.notifier).clear();
      ref.read(cidadeFiltroProvider.notifier).state = '';
    });

    final location = GoRouterState.of(context).uri.path;
    final index = _abas.indexWhere((a) => a.$1 == location);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sub-rotas (detalhe de candidato, comparar...) rodam em tela cheia.
    if (index < 0) return child;

    final corBarra = isDark ? const Color(0xFF10151F) : const Color(0xFF16213E);

    // Voltar do sistema (botao/gesto) nunca deixa a pessoa presa: numa aba
    // secundaria volta pra Visao; na Visao sai do modulo e volta ao app.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (location != '/home/eleitoral') {
          context.go('/home/eleitoral');
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: corBarra,
          indicatorColor: cs.primary.withValues(alpha: 0.28),
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final ativo = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
              color: ativo ? Colors.white : Colors.white60,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final ativo = states.contains(WidgetState.selected);
            return IconThemeData(
              color: ativo ? Colors.white : Colors.white60,
              size: 24,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            context.go(_abas[i].$1);
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final (_, outline, filled, label) in _abas)
              NavigationDestination(
                icon: Icon(outline),
                selectedIcon: Icon(filled),
                label: label,
              ),
          ],
          ),
        ),
      ),
    );
  }
}
