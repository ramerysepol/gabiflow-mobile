import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/design_tokens.dart';

/// Card de KPI number-first: eyebrow com glifo discreto, numeral tabular
/// em Space Grotesk e linha de tendência.
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

    final successColor =
        isDark ? AppColors.successDark : AppColors.successLight;
    final dangerColor = isDark ? AppColors.dangerDark : AppColors.dangerLight;
    final trendColor = trendPositive ? successColor : dangerColor;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Eyebrow: glifo pequeno + label espaçado
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 15, color: cs.primary),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: AppTextStyles.eyebrow(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Numeral tabular
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark
                      ? AppColors.neutral900Dark
                      : AppColors.neutral900Light,
                ),
              ),
              // Tendência
              if (trendDelta != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendPositive
                          ? Icons.north_east_rounded
                          : Icons.south_east_rounded,
                      size: 13,
                      color: trendColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      trendDelta!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: trendColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (trendLabel != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          trendLabel!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
