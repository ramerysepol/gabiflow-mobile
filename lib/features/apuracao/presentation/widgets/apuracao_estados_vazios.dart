import 'package:flutter/material.dart';

/// Antes do TSE publicar os primeiros boletins (o polling continua rodando).
class AguardandoApuracao extends StatelessWidget {
  const AguardandoApuracao({super.key, required this.intervaloSegundos});

  final int intervaloSegundos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.sensors_rounded, size: 30, color: cs.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Aguardando o início da apuração',
            textAlign: TextAlign.center,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'A coleta começa assim que o TSE publicar os primeiros boletins. '
            'Esta tela se atualiza sozinha a cada $intervaloSegundos segundos.',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Erro de carga com botão de tentar novamente.
class ApuracaoErro extends StatelessWidget {
  const ApuracaoErro({super.key, required this.mensagem, required this.onRetry});

  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 36, color: cs.error),
          const SizedBox(height: 12),
          Text(mensagem, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
