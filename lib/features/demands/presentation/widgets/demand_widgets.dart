import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Badge de prioridade da demanda.
class DemandPriorityBadge extends StatelessWidget {
  const DemandPriorityBadge({super.key, required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, color) = switch (priority) {
      'high' || 'alta' => (
          'Alta',
          isDark ? AppColors.dangerDark : AppColors.dangerLight
        ),
      'low' || 'baixa' => (
          'Baixa',
          isDark ? AppColors.successDark : AppColors.successLight
        ),
      _ => (
          'Média',
          isDark ? AppColors.warningDark : AppColors.warningLight
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Chip de status da demanda.
class DemandStatusChip extends StatelessWidget {
  const DemandStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, bg, fg) = switch (status) {
      'pending' => ('Pendente', cs.errorContainer, cs.onErrorContainer),
      'in_progress' => (
          'Em andamento',
          cs.secondaryContainer,
          cs.onSecondaryContainer
        ),
      'completed' => (
          'Concluída',
          AppColors.successContainerLight,
          AppColors.successLight
        ),
      'cancelled' => (
          'Cancelada',
          cs.surfaceContainerHighest,
          cs.onSurfaceVariant
        ),
      _ => (status, cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
