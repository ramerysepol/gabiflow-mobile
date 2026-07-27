import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/design_tokens.dart';
import 'primary_button.dart';

/// Empty state centralizado com Lottie opcional e ação primária.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.lottiePath,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? lottiePath;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Scrollável: em áreas com pouca altura (abaixo de headers/banners),
    // o conteúdo rola em vez de estourar o layout.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ilustração
            SizedBox(
              width: 160,
              height: 160,
              child: lottiePath != null
                  ? Lottie.asset(lottiePath!, repeat: true)
                  : _FallbackIllustration(isDark: isDark),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Título
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Subtítulo
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.neutral600Dark
                        : AppColors.neutral600Light,
                  ),
              textAlign: TextAlign.center,
            ),
            // Ação opcional
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FallbackIllustration extends StatelessWidget {
  const _FallbackIllustration({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.inbox_outlined,
        size: 64,
        color: cs.primary.withValues(alpha: 0.7),
      ),
    );
  }
}
