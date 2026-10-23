import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/comparativo_bairro_model.dart';
import '../comparativo_args.dart';
import '../ordenacao_tabela.dart';
import '../providers/comparativo_bairro_providers.dart';
import '../widgets/comparativo_widgets.dart';
import '../widgets/erro_inline.dart';
import '../widgets/numero_formatado.dart';

class BairrosComparativoPage extends ConsumerStatefulWidget {
  const BairrosComparativoPage({super.key, required this.args});

  final ComparativoArgs args;

  @override
  ConsumerState<BairrosComparativoPage> createState() =>
      _BairrosComparativoPageState();
}

class _BairrosComparativoPageState
    extends ConsumerState<BairrosComparativoPage> {
  OrdenacaoTabela _ord = const OrdenacaoTabela(coluna: 3, asc: false);

  ComparativoParams get _params => ComparativoParams(
        municipio: widget.args.municipio,
        candA: widget.args.candA,
        candB: widget.args.candB,
      );

  Comparable<dynamic> _chave(BairroComparativoItem b, int col) => switch (col) {
        0 => b.bairro.toLowerCase(),
        1 => b.votosA,
        2 => b.votosB,
        _ => b.diferenca,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(bairrosComparativoProvider(_params));
    return Scaffold(
      appBar: AppBar(title: Text(widget.args.nomeMunicipio)),
      body: async.when(
        loading: () => ListView.builder(
          itemCount: 6,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ShimmerSkeleton.card(height: 56),
          ),
        ),
        error: (e, _) => ErroInline(
          mensagem: 'Não foi possível carregar os bairros',
          onRetry: () => ref.invalidate(bairrosComparativoProvider(_params)),
        ),
        data: (m) => _corpo(m, cs),
      ),
    );
  }

  Widget _corpo(BairrosComparativoModel m, ColorScheme cs) {
    final corA = corComparativoA(cs);
    final corB = corComparativoB(cs);
    final itens = _ord.aplicar(m.bairros, _chave);
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ComparativoCabecalho(
            a: m.a,
            b: m.b,
            corA: corA,
            corB: corB,
            votosA: m.totalVotosA,
            votosB: m.totalVotosB,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: BarraDupla(
            votosA: m.totalVotosA,
            votosB: m.totalVotosB,
            corA: corA,
            corB: corB,
            altura: 10,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            '${m.totalBairros} bairros · ${m.totalSecoes} seções',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ),
        CabecalhoOrdenavel(
          padding: const EdgeInsets.fromLTRB(28, 6, 44, 2),
          ordenacao: _ord,
          onOrdenar: (i) =>
              setState(() => _ord = _ord.alternar(i, ascInicial: i == 0)),
          colunas: [
            const ColunaOrdenavel('Bairro', flex: 3),
            ColunaOrdenavel('A', direita: true, cor: corA),
            ColunaOrdenavel('B', direita: true, cor: corB),
            const ColunaOrdenavel('Dif.', direita: true),
          ],
        ),
        for (final b in itens) _linha(b, corA, corB, cs),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _linha(
      BairroComparativoItem b, Color corA, Color corB, ColorScheme cs) {
    final cor = corVencedor(b.votosA, b.votosB, corA, corB, cs.onSurfaceVariant);
    final nome = b.bairro.isEmpty ? '(sem bairro)' : b.bairro;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '/home/eleitoral/comparar/bairros/secoes',
          extra: widget.args.comBairro(b.bairro),
        ),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cor.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  _num(formatarNumero(b.votosA), corA, b.votosA >= b.votosB),
                  _num(formatarNumero(b.votosB), corB, b.votosB >= b.votosA),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${b.diferenca > 0 ? '+' : b.diferenca < 0 ? '−' : ''}${formatarNumero(b.diferenca.abs())}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: cor),
                        ),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 18, color: cs.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 6),
              BarraDupla(
                  votosA: b.votosA, votosB: b.votosB, corA: corA, corB: corB),
            ],
          ),
        ),
      ),
    );
  }

  Widget _num(String t, Color cor, bool forte) => Expanded(
        child: Text(
          t,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 12,
            color: cor,
            fontWeight: forte ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      );
}
