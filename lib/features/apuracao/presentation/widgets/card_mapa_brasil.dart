import 'package:flutter/material.dart';

import '../../data/models/apuracao_mapa_uf_model.dart';
import '../apuracao_format.dart';
import '../cores_duelo.dart';
import 'mapa_brasil_widget.dart';

/// Card do dashboard com o mapa do Brasil e a legenda do duelo.
class CardMapaBrasil extends StatelessWidget {
  const CardMapaBrasil({super.key, required this.dados});

  final ApuracaoMapaUfModel dados;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final itens = dados.itens;
    Color cor(String sq) => CoresDuelo.doCandidato(sq, itens);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Mapa do Brasil',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Cor = candidato na liderança · intensidade = tamanho da vantagem',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          MapaBrasilWidget(estados: dados.estados, corDe: cor, escuro: escuro),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final c in itens.take(2))
                _Legenda(
                  cor: cor(c.sqcand),
                  texto: '${c.nomeUrna} ${formatarPct1Apuracao(c.pct)}',
                ),
              _Legenda(
                cor: CoresDuelo.semDados(escuro: escuro),
                texto: 'Sem dados',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto});

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          texto,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
