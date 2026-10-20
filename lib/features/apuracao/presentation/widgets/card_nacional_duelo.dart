import 'package:flutter/material.dart';

import '../../data/models/apuracao_mapa_uf_model.dart';
import '../../data/models/apuracao_ranking_model.dart';
import '../apuracao_format.dart';
import '../cores_duelo.dart';
import 'ao_vivo_pill.dart';
import 'barra_duelo.dart';
import 'duelo_candidato_tile.dart';

/// Candidato eleito: só após totalizar, por TSE ou projeção.
bool candidatoEleito(bool finalizado, ApuracaoCandVoto c) =>
    finalizado && (c.eleitoTse || c.projecao == 'eleito');

/// Card nacional do dashboard: seções totalizadas, duelo (% + votos), barra
/// dividida e KPIs de votos/comparecimento.
class CardNacionalDuelo extends StatelessWidget {
  const CardNacionalDuelo({super.key, required this.dados});

  final ApuracaoMapaUfModel dados;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final r = dados.resumo;
    final finalizado = r?.finalizado ?? false;
    final itens = dados.itens;
    final duelo = itens.take(2).toList();
    final vantagem = duelo.length == 2
        ? duelo[0].votos - duelo[1].votos
        : null;
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
              Expanded(
                child: Text(
                  'Brasil — ${r?.cargoNome ?? 'Presidente'}',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              AoVivoPill(aoVivo: !finalizado),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${formatarVotosApuracao(r?.secoesTotalizadas)} de '
                  '${formatarVotosApuracao(r?.secoesTotal)} seções totalizadas',
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              Text(
                formatarPct1Apuracao(r?.pctSecoes),
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: finalizado ? const Color(0xFF16A34A) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ((r?.pctSecoes ?? 0).toDouble() / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                finalizado ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < duelo.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            DueloCandidatoTile(
              candidato: duelo[i],
              cor: cor(duelo[i].sqcand),
              eleito: candidatoEleito(finalizado, duelo[i]),
              vantagem: i == 0 ? vantagem : null,
            ),
          ],
          if (duelo.length == 2) ...[
            const SizedBox(height: 12),
            BarraDuelo(
              votosA: duelo[0].votos,
              votosB: duelo[1].votos,
              corA: cor(duelo[0].sqcand),
              corB: cor(duelo[1].sqcand),
            ),
          ],
          const SizedBox(height: 14),
          _Kpis(
            itens: [
              ('Votos totais', formatarVotosApuracao(r?.votosTotal), null),
              ('Votos válidos', formatarVotosApuracao(r?.votosValidos), null),
              (
                'Comparecimento',
                formatarVotosApuracao(r?.comparecimento),
                '${formatarPct1Apuracao(r?.pctComparecimento)} do eleitorado',
              ),
              (
                'Brancos e nulos',
                r == null
                    ? '—'
                    : formatarVotosApuracao((r.brancos ?? 0) + (r.nulos ?? 0)),
                'brancos ${formatarVotosApuracao(r?.brancos)} · '
                    'nulos ${formatarVotosApuracao(r?.nulos)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.itens});

  final List<(String, String, String?)> itens;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) {
        final largura = (c.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (rotulo, valor, sub) in itens)
              SizedBox(
                width: largura,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rotulo.toUpperCase(),
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 9.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        valor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (sub != null)
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
