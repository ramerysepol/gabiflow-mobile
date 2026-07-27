import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/design_tokens.dart';

/// Card de KPI com valor em Space Grotesk, label uppercase e trend opcional.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.trendDelta,
    this.trendLabel,
    this.trendPositive = true,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final String? trendDelta;
  final String? trendLabel;
  final bool trendPositive;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final successColor = isDark ? AppColors.successDark : AppColors.successLight;
    final dangerColor = isDark ? AppColors.dangerDark : AppColors.dangerLight;
    final trendColor = trendPositive ? successColor : dangerColor;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Stack(
            children: [
              // Ícone decorativo no canto superior direito
              if (icon != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, color: cs.primary, size: 22),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label uppercase
                  Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.8,
                          color: isDark
                              ? AppColors.neutral600Dark
                              : AppColors.neutral600Light,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Valor principal em Space Grotesk
                  Text(
                    value,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.neutral900Dark
                          : AppColors.neutral900Light,
                      height: 1,
                    ),
                  ),
                  // Trend
                  if (trendDelta != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendPositive
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 14,
                          color: trendColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          trendDelta!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: trendColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (trendLabel != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            trendLabel!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
