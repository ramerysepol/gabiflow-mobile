import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../electoral_data/presentation/providers/eleitoral_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Card de entrada para a transferência de votos no Command Center.
class TransferenciaCard extends ConsumerWidget {
  const TransferenciaCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ano = ref.watch(filtrosSelecionadosProvider).ano;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/home/eleitoral/ia/transferencia'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Icon(Icons.swap_horiz_rounded, size: 22, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transferência de votos ${ano - 2} → $ano',
                      style:
                          tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    'Cruze os votos dos seus apoiadores com os seus, por bairro e seção.',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
