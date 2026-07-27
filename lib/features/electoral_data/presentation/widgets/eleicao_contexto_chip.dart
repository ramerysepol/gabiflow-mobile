import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/eleitoral_providers.dart';

/// Chip compacto que exibe o contexto da eleição selecionada e permite trocar.
///
/// Usado no AppBar e em subtítulos das subtelas (detalhe, mapa, rankings).
class EleicaoContextoChip extends ConsumerWidget {
  const EleicaoContextoChip({super.key, this.onTrocar});

  /// Callback opcional ao trocar. Se nulo, navega para o seletor.
  final VoidCallback? onTrocar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final election = ref.watch(selectedElectionProvider);
    if (election == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (onTrocar != null) {
          onTrocar!();
        } else {
          _trocarEleicao(context, ref);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.how_to_vote_outlined,
              size: 14,
              color: cs.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              election.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.swap_horiz_rounded,
              size: 14,
              color: cs.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  void _trocarEleicao(BuildContext context, WidgetRef ref) {
    // Limpa estado de microrregião e busca mas mantém seleção até confirmar nova
    ref.read(microrregiaoSelecionadaProvider.notifier).state = null;
    ref.read(filtrosSelecionadosProvider.notifier).setSearch('');
    context.go('/home/eleitoral/selecionar');
  }
}

/// Versão inline (sem borda) para usar como subtitle no AppBar.
class EleicaoContextoSubtitulo extends ConsumerWidget {
  const EleicaoContextoSubtitulo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final election = ref.watch(selectedElectionProvider);
    if (election == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Text(
      election.label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
    );
  }
}
