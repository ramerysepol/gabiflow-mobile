import 'package:flutter/material.dart';

import '../../data/models/comparativo_bairro_model.dart';
import 'numero_formatado.dart';

/// Cabeçalho com os dois candidatos (A / B).
class ComparativoCabecalho extends StatelessWidget {
  const ComparativoCabecalho({
    super.key,
    required this.a,
    required this.b,
    required this.corA,
    required this.corB,
    required this.votosA,
    required this.votosB,
  });

  final CandidatoResumoModel a;
  final CandidatoResumoModel b;
  final Color corA;
  final Color corB;
  final int votosA;
  final int votosB;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Lado(letra: 'A', c: a, cor: corA, votos: votosA),
        const SizedBox(width: 10),
        _Lado(letra: 'B', c: b, cor: corB, votos: votosB),
      ],
    );
  }
}

class _Lado extends StatelessWidget {
  const _Lado({
    required this.letra,
    required this.c,
    required this.cor,
    required this.votos,
  });

  final String letra;
  final CandidatoResumoModel c;
  final Color cor;
  final int votos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: cor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    letra,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: cs.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    c.partido,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              c.nomeUrna,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              formatarNumero(votos),
              style: tt.headlineSmall?.copyWith(
                  color: cor, fontWeight: FontWeight.w900, height: 1.0),
            ),
            Text('votos',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// Mini barra dupla proporcional A × B.
class BarraDupla extends StatelessWidget {
  const BarraDupla({
    super.key,
    required this.votosA,
    required this.votosB,
    required this.corA,
    required this.corB,
    this.altura = 6,
  });

  final int votosA;
  final int votosB;
  final Color corA;
  final Color corB;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = votosA + votosB;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: altura,
        child: total == 0
            ? Container(color: cs.outlineVariant.withValues(alpha: 0.4))
            : Row(
                children: [
                  if (votosA > 0)
                    Flexible(flex: votosA, child: Container(color: corA)),
                  if (votosB > 0)
                    Flexible(flex: votosB, child: Container(color: corB)),
                ],
              ),
      ),
    );
  }
}

/// Cor do vencedor (A, B ou neutra no empate).
Color corVencedor(int a, int b, Color corA, Color corB, Color neutra) =>
    a > b ? corA : (b > a ? corB : neutra);
