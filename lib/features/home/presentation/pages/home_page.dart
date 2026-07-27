import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Shell da tela Home: AppBar global + bottom nav + conteúdo via ShellRoute.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  static const _routes = [
    '/home',
    '/home/constituents',
    '/home/demands',
    '/home/agenda',
    '/home/eleitoral',
  ];

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Avatar do usuário com menu
            PopupMenuButton<String>(
              offset: const Offset(0, 44),
              child: UserAvatar(
                avatarData: user?.avatar,
                userName: user?.name ?? 'Usuário',
                radius: 18,
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
                          size: 20,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 12),
                      Text(
                        'Sair',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'logout') {
                  await _confirmLogout();
                }
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(user?.name),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _formattedDate(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Badge(
              isLabelVisible: true,
              label: Text('3'),
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Em breve: Notificações')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }

  Future<void> _confirmLogout() async {
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
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/');
    }
  }

  String _greeting(String? name) {
    final hour = DateTime.now().hour;
    final period = hour < 12
        ? 'Bom dia'
        : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';
    final firstName = name?.split(' ').first ?? 'Usuário';
    return '$period, $firstName!';
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
