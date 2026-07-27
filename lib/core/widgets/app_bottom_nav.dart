import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/design_tokens.dart';

/// Dock de navegação com pill animada, 5 tabs e badge de demandas.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.demandsBadge = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  /// Mostra ponto no tab Demandas quando true.
  final bool demandsBadge;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Início'),
    (Icons.people_outline_rounded, Icons.people_rounded, 'Munícipes'),
    (Icons.inbox_outlined, Icons.inbox_rounded, 'Demandas'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Agenda'),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Eleitoral'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border =
        isDark ? AppColors.borderSubtleDark : AppColors.borderSubtleLight;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDefaultDark : Colors.white,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final (outline, filled, label) = _items[i];
              return Expanded(
                child: _DockItem(
                  icon: outline,
                  selectedIcon: filled,
                  label: label,
                  selected: i == selectedIndex,
                  showBadge: i == 2 && demandsBadge,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTabSelected(i);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.neutral600Dark : AppColors.neutral600Light;
    final color = selected ? cs.primary : mutedColor;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pill que envolve o ícone ativo
            AnimatedContainer(
              duration: AppMotion.emphasized,
              curve: AppMotion.emphasizedCurve,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary.withValues(alpha: isDark ? 0.24 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: AppMotion.standard,
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      selected ? selectedIcon : icon,
                      key: ValueKey(selected),
                      size: 24,
                      color: color,
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.dangerDark
                              : AppColors.dangerLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppMotion.standard,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 0.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
