import 'package:flutter/material.dart';

/// Estado de erro compacto e amigável — nunca exibe a exceção crua
/// (DioException/stacktrace) para o usuário.
class ErroInline extends StatelessWidget {
  const ErroInline({
    super.key,
    this.mensagem = 'Não foi possível carregar os dados',
    this.onRetry,
  });

  final String mensagem;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 36, color: cs.error),
            const SizedBox(height: 12),
            Text(
              mensagem,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Verifique sua conexão e tente novamente.',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
