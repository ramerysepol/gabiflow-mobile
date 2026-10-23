import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/demanda_model.dart';
import '../../data/models/demanda_vocab.dart';
import 'demanda_chips.dart';

/// Encaminhamentos a órgãos, com status e resposta.
class DemandaEncaminhamentos extends StatelessWidget {
  const DemandaEncaminhamentos({super.key, required this.itens});
  final List<DemandaEncaminhamento> itens;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    String data(String? s) {
      final d = parseData(s);
      return d == null ? '' : DateFormat('dd/MM/yy').format(d);
    }

    return Column(
      children: [
        for (final e in itens)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.orgao.nome,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    DemandaChip(
                      rotulo: DemandaVocab.encaminhamento(e.status),
                      cor: switch (e.status) {
                        'respondido' => const Color(0xFF059669),
                        'sem_resposta' => const Color(0xFFDC2626),
                        _ => cs.primary,
                      },
                    ),
                  ],
                ),
                Text(
                  [
                    if (data(e.enviadoEm).isNotEmpty)
                      'Enviado em ${data(e.enviadoEm)}',
                    if (e.oficioNumero != null) 'Ofício ${e.oficioNumero}',
                    if (data(e.prazoResposta).isNotEmpty)
                      'Resposta até ${data(e.prazoResposta)}',
                  ].join(' · '),
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (e.respostaTexto != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(e.respostaTexto!, style: tt.bodySmall),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
