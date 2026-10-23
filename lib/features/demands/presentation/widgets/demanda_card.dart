import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/demanda_model.dart';
import '../../data/models/demanda_vocab.dart';
import 'demanda_chips.dart';

/// Card compacto da Mesa: protocolo, título, munícipe, chips, prazo e dono.
class DemandaCard extends StatelessWidget {
  const DemandaCard({super.key, required this.demanda, required this.onTap});

  final DemandaResumo demanda;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final d = demanda;
    final acento = d.ehSaude ? DemandaVocab.corSaude(context) : null;

    return Semantics(
      button: true,
      label:
          'Demanda ${d.protocolo}, ${d.titulo}, '
          '${DemandaVocab.status(d.status)}',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: acento?.withValues(alpha: 0.45) ?? cs.outlineVariant,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      d.protocolo,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (d.ehSaude) ...[
                      const DemandaSaudeChip(),
                      const SizedBox(width: 6),
                    ],
                    DemandaPrioridadeChip(d.prioridade),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  d.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (d.municipe != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    d.municipe!.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    DemandaStatusChip(d.status),
                    const SizedBox(width: 8),
                    Expanded(child: DemandaPrazoLabel(d)),
                    if (d.responsavel != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 90),
                        child: Text(
                          d.responsavel!.nome.split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
