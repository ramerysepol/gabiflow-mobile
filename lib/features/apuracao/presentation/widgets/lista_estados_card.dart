import 'package:flutter/material.dart';

import '../../data/models/apuracao_mapa_uf_model.dart';
import '../../data/models/apuracao_ranking_model.dart';
import '../apuracao_format.dart';
import '../cores_duelo.dart';

const _ufNomes = <String, String>{
  'AC': 'Acre', 'AL': 'Alagoas', 'AP': 'Amapá', 'AM': 'Amazonas',
  'BA': 'Bahia', 'CE': 'Ceará', 'DF': 'Distrito Federal',
  'ES': 'Espírito Santo', 'GO': 'Goiás', 'MA': 'Maranhão',
  'MT': 'Mato Grosso', 'MS': 'Mato Grosso do Sul', 'MG': 'Minas Gerais',
  'PA': 'Pará', 'PB': 'Paraíba', 'PR': 'Paraná', 'PE': 'Pernambuco',
  'PI': 'Piauí', 'RJ': 'Rio de Janeiro', 'RN': 'Rio Grande do Norte',
  'RS': 'Rio Grande do Sul', 'RO': 'Rondônia', 'RR': 'Roraima',
  'SC': 'Santa Catarina', 'SP': 'São Paulo', 'SE': 'Sergipe',
  'TO': 'Tocantins',
};

/// Lista "Apuração por estado": líder, % do líder e seções apuradas.
class ListaEstadosCard extends StatelessWidget {
  const ListaEstadosCard({
    super.key,
    required this.estados,
    required this.itens,
  });

  final List<ApuracaoEstadoUf> estados;
  final List<ApuracaoCandVoto> itens;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ordenados = [...estados]
      ..sort((a, b) => (b.pctSecoes ?? 0).compareTo(a.pctSecoes ?? 0));

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apuração por estado',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final e in ordenados)
            _LinhaEstado(
              estado: e,
              cor: e.lider == null
                  ? null
                  : CoresDuelo.doCandidato(e.lider!.sqcand, itens),
            ),
        ],
      ),
    );
  }
}

class _LinhaEstado extends StatelessWidget {
  const _LinhaEstado({required this.estado, required this.cor});

  final ApuracaoEstadoUf estado;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lider = estado.lider;
    final pctSecoes = (estado.pctSecoes ?? 0).toDouble().clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              estado.uf,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (cor != null)
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: cor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        lider?.nomeUrna ??
                            'sem dados · ${_ufNomes[estado.uf] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: lider == null
                              ? FontWeight.w400
                              : FontWeight.w700,
                          color: lider == null ? cs.onSurfaceVariant : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pctSecoes / 100,
                          minHeight: 4,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            estado.finalizado
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${formatarPct1Apuracao(estado.pctSecoes)} das seções',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 58,
            child: Text(
              lider == null ? '—' : formatarPct1Apuracao(lider.pct),
              textAlign: TextAlign.right,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: cor,
              ),
            ),
          ),
          if (estado.finalizado)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: Color(0xFF16A34A),
              ),
            )
          else
            const SizedBox(width: 18),
        ],
      ),
    );
  }
}
