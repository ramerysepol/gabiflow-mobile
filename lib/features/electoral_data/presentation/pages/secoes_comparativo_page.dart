import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/comparativo_bairro_model.dart';
import '../../data/services/secoes_xlsx_service.dart';
import '../comparativo_args.dart';
import '../ordenacao_tabela.dart';
import '../providers/comparativo_bairro_providers.dart';
import '../providers/eleitoral_providers.dart';
import '../widgets/comparativo_widgets.dart';
import '../widgets/erro_inline.dart';
import '../widgets/numero_formatado.dart';

class SecoesComparativoPage extends ConsumerStatefulWidget {
  const SecoesComparativoPage({super.key, required this.args});

  final ComparativoArgs args;

  @override
  ConsumerState<SecoesComparativoPage> createState() =>
      _SecoesComparativoPageState();
}

class _SecoesComparativoPageState
    extends ConsumerState<SecoesComparativoPage> {
  OrdenacaoTabela _ord = const OrdenacaoTabela();
  bool _exportando = false;

  ComparativoParams get _params => ComparativoParams(
        municipio: widget.args.municipio,
        candA: widget.args.candA,
        candB: widget.args.candB,
        bairro: widget.args.bairro,
      );

  String get _nomeBairro {
    final b = widget.args.bairro ?? '';
    return b.isEmpty ? '(sem bairro)' : b;
  }

  Comparable<dynamic> _chave(SecaoComparativoItem s, int col) => switch (col) {
        0 => (int.tryParse(s.zona) ?? 0) * 100000 + (int.tryParse(s.secao) ?? 0),
        1 => s.local.toLowerCase(),
        2 => s.votosA,
        3 => s.votosB,
        _ => s.diferenca,
      };

  Future<void> _exportar(SecoesComparativoModel m) async {
    setState(() => _exportando = true);
    try {
      final f = ref.read(filtrosSelecionadosProvider);
      await SecoesXlsxService.compartilhar(
        m: m,
        municipio: widget.args.nomeMunicipio,
        bairro: _nomeBairro,
        ano: f.ano,
        estado: f.estado,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível gerar o Excel')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(secoesComparativoProvider(_params));
    return Scaffold(
      appBar: AppBar(
        title: Text(_nomeBairro),
        actions: [
          if (_exportando)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              tooltip: 'Compartilhar Excel',
              icon: const Icon(Icons.ios_share),
              onPressed: async.hasValue ? () => _exportar(async.value!) : null,
            ),
        ],
      ),
      body: async.when(
        loading: () => ListView.builder(
          itemCount: 6,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ShimmerSkeleton.card(height: 64),
          ),
        ),
        error: (e, _) => ErroInline(
          mensagem: 'Não foi possível carregar as seções',
          onRetry: () => ref.invalidate(secoesComparativoProvider(_params)),
        ),
        data: (m) => _corpo(m, cs),
      ),
    );
  }

  Widget _corpo(SecoesComparativoModel m, ColorScheme cs) {
    final corA = corComparativoA(cs);
    final corB = corComparativoB(cs);
    final itens = _ord.aplicar(m.secoes, _chave);
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
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nas ${m.totalSecoes} seções: ambos em ${m.secoesComAmbos}, '
                  'só A em ${m.secoesSoA}, só B em ${m.secoesSoB}.',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quando os dois aparecem na maioria das seções e a razão '
                  'entre os votos se mantém, a liderança provavelmente '
                  'trabalhou para os dois candidatos.',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        CabecalhoOrdenavel(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 2),
          ordenacao: _ord,
          onOrdenar: (i) =>
              setState(() => _ord = _ord.alternar(i, ascInicial: i <= 1)),
          colunas: [
            const ColunaOrdenavel('Zona/Seção', flex: 2),
            const ColunaOrdenavel('Local', flex: 2),
            ColunaOrdenavel('A', direita: true, cor: corA),
            ColunaOrdenavel('B', direita: true, cor: corB),
            const ColunaOrdenavel('Dif.', direita: true),
          ],
        ),
        for (final s in itens) _linha(s, corA, corB, cs),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _linha(
      SecaoComparativoItem s, Color corA, Color corB, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Zona ${s.zona} · Seção ${s.secao}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(formatarNumero(s.votosA),
                  style: TextStyle(
                      color: corA, fontWeight: FontWeight.w800, fontSize: 13)),
              Text('  ×  ',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              Text(formatarNumero(s.votosB),
                  style: TextStyle(
                      color: corB, fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
          if (s.local.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(s.local,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: 8),
          BarraDupla(
              votosA: s.votosA, votosB: s.votosB, corA: corA, corB: corB),
        ],
      ),
    );
  }
}
