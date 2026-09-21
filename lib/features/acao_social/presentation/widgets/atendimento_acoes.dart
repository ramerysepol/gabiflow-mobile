import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/acao_social_models.dart';
import '../providers/acao_social_providers.dart';
import 'acao_social_widgets.dart';

/// Acoes possiveis sobre UM atendimento (paciente x especialidade).
///
/// Regras de vaga do servidor: cancelar DEVOLVE a vaga; nao existe
/// "descancelar" (a vaga nao seria reservada de novo). Por isso um
/// cancelado so volta pelo fluxo "Atender", que cria outro atendimento.
enum AcaoAtendimento { reabrir, concluir, cancelar }

/// Abre o menu de acoes do atendimento e executa a escolhida.
/// Reutilizado pela aba Atendimentos e pela Ficha.
Future<void> editarAtendimento(
  BuildContext context,
  WidgetRef ref,
  Atendimento a,
) async {
  final acao = await showModalBottomSheet<AcaoAtendimento>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _AcoesSheet(atendimento: a),
  );
  if (acao == null || !context.mounted) return;

  final nomeEsp = a.especialidadeNome ?? 'esta especialidade';
  if (acao == AcaoAtendimento.cancelar) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar atendimento'),
        content: Text(
            'Cancelar $nomeEsp de ${a.pacienteNome ?? 'paciente'}? A vaga volta a ficar disponível.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Voltar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancelar atendimento'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }

  HapticFeedback.lightImpact();
  final novoStatus = switch (acao) {
    AcaoAtendimento.reabrir => 'em_atendimento',
    AcaoAtendimento.concluir => 'concluido',
    AcaoAtendimento.cancelar => 'cancelado',
  };
  final sucesso = await ref
      .read(acaoSocialAcoesProvider.notifier)
      .alterarStatus(a, novoStatus);
  if (!context.mounted) return;
  final erro = ref.read(acaoSocialAcoesProvider).error;
  final msgOk = switch (acao) {
    AcaoAtendimento.reabrir => '$nomeEsp reaberto (em atendimento).',
    AcaoAtendimento.concluir => '$nomeEsp concluído.',
    AcaoAtendimento.cancelar => '$nomeEsp cancelado. Vaga devolvida.',
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(sucesso ? msgOk : (erro ?? 'Não foi possível alterar.')),
  ));
}

class _AcoesSheet extends StatelessWidget {
  const _AcoesSheet({required this.atendimento});

  final Atendimento atendimento;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final a = atendimento;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.especialidadeNome ?? a.especialidadeSlug ?? 'Atendimento',
                    style: tt.titleLarge),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusChip(
                      rotulo: rotuloStatusAtendimento(a.status),
                      cor: corStatusAtendimento(a.status),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.pacienteNome ?? '',
                        style: tt.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (a.concluido)
            ListTile(
              leading: const Icon(Icons.undo_rounded, color: Color(0xFF1976D2)),
              title: const Text('Reabrir atendimento'),
              subtitle: const Text('Volta para "em atendimento". A vaga continua reservada.'),
              onTap: () => Navigator.of(context).pop(AcaoAtendimento.reabrir),
            ),
          if (a.emAtendimento)
            ListTile(
              leading:
                  const Icon(Icons.task_alt_rounded, color: Color(0xFF2E7D32)),
              title: const Text('Marcar como concluído'),
              onTap: () => Navigator.of(context).pop(AcaoAtendimento.concluir),
            ),
          if (!a.cancelado)
            ListTile(
              leading: Icon(Icons.cancel_rounded, color: cs.error),
              title: Text('Cancelar atendimento',
                  style: TextStyle(color: cs.error)),
              subtitle: const Text('Devolve a vaga desta especialidade.'),
              onTap: () => Navigator.of(context).pop(AcaoAtendimento.cancelar),
            ),
          if (a.cancelado)
            ListTile(
              leading: Icon(Icons.info_outline_rounded, color: cs.onSurfaceVariant),
              title: const Text('Atendimento cancelado'),
              subtitle: const Text(
                  'A vaga já foi devolvida. Para atender de novo, use "Atender" na aba Cadastrados (reserva uma nova vaga).'),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
