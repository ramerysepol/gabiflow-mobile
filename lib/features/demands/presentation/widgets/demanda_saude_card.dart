import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/demanda_model.dart';
import '../../data/models/demanda_vocab.dart';

/// Card teal com os dados do pedido de saúde.
class DemandaSaudeCard extends StatelessWidget {
  const DemandaSaudeCard({super.key, required this.demanda});
  final DemandaDetalhe demanda;

  @override
  Widget build(BuildContext context) {
    final s = demanda.saude;
    if (s == null) return const SizedBox.shrink();
    final teal = DemandaVocab.corSaude(context);
    final tt = Theme.of(context).textTheme;
    final nasc = parseData(s.pacienteNascimento);
    final paciente = s.pacienteNome ?? demanda.municipe?.nome ?? '—';

    Widget linha(String k, String? v) => (v == null || v.isEmpty)
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    k,
                    style: tt.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: Text(v, style: tt.bodyMedium)),
              ],
            ),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: teal.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: teal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Saúde',
                style: tt.titleSmall?.copyWith(
                  color: teal,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          linha(
            'Paciente',
            s.pacienteParentesco != null
                ? '$paciente (${s.pacienteParentesco})'
                : paciente,
          ),
          linha(
            'Nascimento',
            nasc == null ? null : DateFormat('dd/MM/yyyy').format(nasc),
          ),
          linha('Cartão SUS', s.cartaoSus),
          linha('Pedido', DemandaVocab.tipoPedido(s.tipoPedido)),
          linha('Especialidade', s.especialidade),
          linha('Unidade', s.unidadeSaude),
          linha('Urgência', DemandaVocab.urgencia(s.urgenciaClinica)),
          linha('Obs. clínicas', s.observacoesClinicas),
        ],
      ),
    );
  }
}
