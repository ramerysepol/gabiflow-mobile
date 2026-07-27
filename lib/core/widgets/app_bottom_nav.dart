import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom navigation com 5 tabs e suporte a badge de notificações.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.demandsBadge = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  /// Mostra ponto vermelho no tab Demandas quando true.
  final bool demandsBadge;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        HapticFeedback.selectionClick();
        onTabSelected(index);
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: 'Munícipes',
        ),
        NavigationDestination(
          icon: _BadgedIcon(
            icon: Icons.inbox_outlined,
            showBadge: demandsBadge,
          ),
          selectedIcon: _BadgedIcon(
            icon: Icons.inbox_rounded,
            showBadge: demandsBadge,
          ),
          label: 'Demandas',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Agenda',
        ),
        const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Eleitoral',
        ),
      ],
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, this.showBadge = false});

  final IconData icon;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showBadge)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
