import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissoes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Shell da Home — assinatura visual "Expediente": header de tinta tingido
/// pela cor do gabinete com a folha de conteúdo deslizando por cima.
///
/// - Abas raiz: header de tinta + dock.
/// - Sub-páginas (detalhe/formulário): tela cheia com o AppBar próprio,
///   sem barra duplicada.
/// - Eleitoral: mantém o AppBar próprio (chip de eleição + ações), só dock.
class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Aba "Atendimento" só existe para quem tem a permissão da central.
    final temCentral =
        ref.watch(temPermissaoProvider(Permissoes.whatsappCentral));

    final routes = [
      '/home',
      if (temCentral) '/home/atendimento',
      '/home/constituents',
      '/home/demands',
      '/home/agenda',
      '/home/eleitoral',
    ];
    final titles = [
      '',
      if (temCentral) 'Atendimento',
      'Munícipes',
      'Demandas',
      'Agenda',
      'Dados Eleitorais',
    ];
    final navItems = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home_rounded, 'Início'),
      if (temCentral)
        (Icons.chat_bubble_outline_rounded, Icons.chat_rounded, 'Chats'),
      (Icons.people_outline_rounded, Icons.people_rounded, 'Munícipes'),
      (Icons.inbox_outlined, Icons.inbox_rounded, 'Demandas'),
      (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Agenda'),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Eleitoral'),
    ];

    final location = GoRouterState.of(context).uri.path;

    // Sub-app Eleitoral: tela cheia com barra propria (EleitoralShell);
    // so o "X" da Visao Geral devolve ao GabiFlow.
    if (location.startsWith('/home/eleitoral')) return child;

    final rootIndex = routes.indexOf(location);

    // Sub-página (detalhe/formulário): tela cheia, sem header nem dock.
    if (rootIndex < 0) return child;

    final isHome = rootIndex == 0;
    final user = ref.watch(authProvider).user;
    final cs = Theme.of(context).colorScheme;
    final ink = AppColors.inkTinted(cs.primary);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ink,
        body: Column(
                children: [
                  _InkHeader(
                    ink: ink,
                    isHome: isHome,
                    title: titles[rootIndex],
                    userName: user?.name,
                    avatarData: user?.avatar,
                    onLogout: () => _confirmLogout(context, ref),
                  ),
                  // Folha de conteúdo sobre a tinta
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.sheet),
                      ),
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: AppBottomNav(
          items: navItems,
          selectedIndex: rootIndex,
          onTabSelected: (index) => context.go(routes[index]),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar saída'),
        content: const Text('Deseja realmente sair do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sair',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/');
    }
  }
}

// ── Header de tinta ─────────────────────────────────────────────────────────

class _InkHeader extends StatelessWidget {
  const _InkHeader({
    required this.ink,
    required this.isHome,
    required this.title,
    required this.userName,
    required this.avatarData,
    required this.onLogout,
  });

  final Color ink;
  final bool isHome;
  final String title;
  final String? userName;
  final String? avatarData;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(ink, cs.primary, 0.12)!, ink],
        ),
      ),
      child: Stack(
        children: [
          // Brilho sutil da cor do gabinete no canto superior direito
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.22),
                    cs.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md + (isHome ? AppSpacing.sm : 0),
              ),
              child: Row(
                children: [
                  _AvatarMenu(
                    userName: userName,
                    avatarData: avatarData,
                    onLogout: onLogout,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: isHome
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formattedDate().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _greeting(userName),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          )
                        : Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    color: Colors.white.withValues(alpha: 0.9),
                    tooltip: 'Notificações',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Em breve: Notificações'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(String? name) {
    final hour = DateTime.now().hour;
    final period = hour < 12
        ? 'Bom dia'
        : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';
    final firstName = name?.split(' ').first ?? 'Usuário';
    return '$period, $firstName';
  }

  String _formattedDate() {
    const weekdays = [
      'domingo',
      'segunda',
      'terça',
      'quarta',
      'quinta',
      'sexta',
      'sábado',
    ];
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday % 7]}, ${now.day} de ${months[now.month - 1]}';
  }
}

class _AvatarMenu extends StatelessWidget {
  const _AvatarMenu({
    required this.userName,
    required this.avatarData,
    required this.onLogout,
  });

  final String? userName;
  final String? avatarData;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      tooltip: 'Conta',
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: UserAvatar(
          avatarData: avatarData,
          userName: userName ?? 'Usuário',
          radius: 18,
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              const Text('Meu Perfil'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout,
                  size: 20, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 12),
              Text(
                'Sair',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') onLogout();
      },
    );
  }
}
