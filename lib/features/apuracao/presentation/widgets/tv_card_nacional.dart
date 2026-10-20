import 'package:flutter/material.dart';

import '../../data/models/apuracao_mapa_uf_model.dart';
import '../../data/models/apuracao_ranking_model.dart';
import '../apuracao_format.dart';
import '../cores_duelo.dart';
import 'avatar_candidato.dart';
import 'barra_duelo.dart';
import 'card_nacional_duelo.dart' show candidatoEleito;
import 'tv_numero_animado.dart';

const _verde = Color(0xFF22C55E);

/// Card nacional da sala de guerra: duelo com percentuais gigantes animados,
/// barra dividida, vantagem, seções totalizadas e KPIs. Sem interação.
class TvCardNacional extends StatelessWidget {
  const TvCardNacional({super.key, required this.dados, required this.escala});

  final ApuracaoMapaUfModel dados;

  /// Fator de tamanho de fonte (função da altura disponível).
  final double escala;

  @override
  Widget build(BuildContext context) {
    final r = dados.resumo;
    final finalizado = r?.finalizado ?? false;
    final itens = dados.itens;
    final duelo = itens.take(2).toList();
    Color cor(String sq) => CoresDuelo.doCandidato(sq, itens);

    final va = duelo.isNotEmpty ? duelo[0].votos : 0;
    final vb = duelo.length > 1 ? duelo[1].votos : 0;
    final vantagem = (va - vb).abs();
    final lider = va + vb == 0 ? null : (va >= vb ? duelo[0] : duelo[1]);
    final eleito = duelo.where((c) => candidatoEleito(finalizado, c));

    return Container(
      padding: EdgeInsets.all(16 * escala),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'BRASIL · VOTO NACIONAL',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11 * escala,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10 * escala),
          for (var i = 0; i < duelo.length; i++) ...[
            _BlocoCandidato(
              c: duelo[i],
              cor: cor(duelo[i].sqcand),
              eleito: eleito.contains(duelo[i]),
              escala: escala,
            ),
            SizedBox(height: 8 * escala),
          ],
          BarraDuelo(
            votosA: va,
            votosB: vb,
            corA: duelo.isNotEmpty ? cor(duelo[0].sqcand) : Colors.grey,
            corB: duelo.length > 1 ? cor(duelo[1].sqcand) : Colors.grey,
            altura: 18 * escala,
            corFundo: Colors.white12,
          ),
          SizedBox(height: 6 * escala),
          Center(
            child: Text(
              lider == null
                  ? 'aguardando os primeiros votos'
                  : 'vantagem: ${formatarVotosApuracao(vantagem)} votos',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13 * escala,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (eleito.isNotEmpty) ...[
            SizedBox(height: 10 * escala),
            _FaixaEleito(nome: eleito.first.nomeUrna, escala: escala),
          ],
          SizedBox(height: 12 * escala),
          _Secoes(r: r, escala: escala),
          SizedBox(height: 10 * escala),
          _Kpis(r: r, escala: escala),
          SizedBox(height: 8 * escala),
          Text(
            'última atualização do TSE: ${formatarHoraApuracao(r?.atualizadoEm)}',
            style: TextStyle(color: Colors.white38, fontSize: 10.5 * escala),
          ),
        ],
      ),
    );
  }
}

class _BlocoCandidato extends StatelessWidget {
  const _BlocoCandidato({
    required this.c,
    required this.cor,
    required this.eleito,
    required this.escala,
  });

  final ApuracaoCandVoto c;
  final Color cor;
  final bool eleito;
  final double escala;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10 * escala),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: eleito ? _verde : cor.withValues(alpha: 0.35),
          width: eleito ? 2.5 : 1,
        ),
      ),
      child: Row(
        children: [
          AvatarCandidato(nome: c.nomeUrna, cor: cor, tamanho: 46 * escala),
          SizedBox(width: 10 * escala),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.nomeUrna,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * escala,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${c.partido ?? '—'} · ${c.numero ?? ''}',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11.5 * escala,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                TvNumeroAnimado(
                  valor: c.votos.toDouble(),
                  formatar: (v) => '${formatarVotosApuracao(v.round())} votos',
                  estilo: TextStyle(
                    color: Colors.white70,
                    fontSize: 13 * escala,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6 * escala),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (eleito)
                Icon(Icons.emoji_events_rounded, color: _verde, size: 20 * escala),
              TvNumeroAnimado(
                valor: (c.pct ?? 0).toDouble(),
                formatar: (v) => formatarPctApuracao(v),
                estilo: TextStyle(
                  color: cor,
                  fontSize: 40 * escala,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaixaEleito extends StatelessWidget {
  const _FaixaEleito({required this.nome, required this.escala});

  final String nome;
  final double escala;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8 * escala, horizontal: 12 * escala),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22 * escala),
          SizedBox(width: 8 * escala),
          Flexible(
            child: Text(
              '$nome · ELEITO',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17 * escala,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Secoes extends StatelessWidget {
  const _Secoes({required this.r, required this.escala});

  final ApuracaoResumo? r;
  final double escala;

  @override
  Widget build(BuildContext context) {
    final pct = ((r?.pctSecoes ?? 0).toDouble() / 100).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Seções totalizadas',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12 * escala,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${formatarVotosApuracao(r?.secoesTotalizadas ?? 0)} de '
              '${formatarVotosApuracao(r?.secoesTotal)} · '
              '${formatarPct1Apuracao(r?.pctSecoes)}',
              style: TextStyle(color: Colors.white70, fontSize: 12 * escala),
            ),
          ],
        ),
        SizedBox(height: 4 * escala),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8 * escala,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4ADE80)),
          ),
        ),
      ],
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.r, required this.escala});

  final ApuracaoResumo? r;
  final double escala;

  @override
  Widget build(BuildContext context) {
    final itens = <(String, String, String?)>[
      ('Votos válidos', formatarVotosApuracao(r?.votosValidos), null),
      (
        'Comparecimento',
        formatarVotosApuracao(r?.comparecimento),
        '${formatarPct1Apuracao(r?.pctComparecimento)} do eleitorado',
      ),
      ('Brancos', formatarVotosApuracao(r?.brancos), null),
      ('Nulos', formatarVotosApuracao(r?.nulos), null),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (rotulo, valor, sub) in itens)
              Container(
                width: w,
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * escala,
                  vertical: 6 * escala,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rotulo.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9.5 * escala,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      valor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18 * escala,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (sub != null)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10 * escala,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
