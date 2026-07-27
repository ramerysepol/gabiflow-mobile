import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/candidato_model.dart';
import '../../data/models/comparacao_model.dart';
import '../providers/eleitoral_providers.dart';
import '../widgets/eleicao_contexto_chip.dart';
import '../widgets/erro_inline.dart';
import '../widgets/numero_formatado.dart';

class CompararPage extends ConsumerStatefulWidget {
  const CompararPage({super.key});

  @override
  ConsumerState<CompararPage> createState() => _CompararPageState();
}

class _CompararPageState extends ConsumerState<CompararPage> {
  /// Slots de comparação (2 fixos, expansível até 4 — paridade desktop)
  final List<CandidatoModel?> _slots = [null, null];

  static const _slotLabels = ['A', 'B', 'C', 'D'];

  List<Color> _slotColors(ColorScheme cs) => [
        cs.primary,
        cs.tertiary,
        Colors.orange.shade700,
        Colors.purple.shade600,
      ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparar Candidatos'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: EleicaoContextoChip()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Seleção de candidatos (grid 2 colunas, até 4 slots)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              children: [
                for (var row = 0; row * 2 < _slots.length; row++)
                  Padding(
                    padding: EdgeInsets.only(top: row > 0 ? 10 : 0),
                    child: Row(
                      children: [
                        for (var col = 0; col < 2; col++)
                          if (row * 2 + col < _slots.length) ...[
                            if (col > 0) const SizedBox(width: 10),
                            Expanded(
                              child: _CandidatoSelector(
                                label:
                                    'Candidato ${_slotLabels[row * 2 + col]}',
                                candidato: _slots[row * 2 + col],
                                onTap: () =>
                                    _selecionarCandidato(row * 2 + col),
                                onClear: () =>
                                    _limparSlot(row * 2 + col),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(width: 10),
                            const Expanded(child: SizedBox.shrink()),
                          ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_slots.length < 4)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: TextButton.icon(
                  onPressed: () => setState(() => _slots.add(null)),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    'Adicionar candidato',
                    style: TextStyle(fontSize: 12, color: cs.primary),
                  ),
                ),
              ),
            ),
          // Resultado
          Expanded(
            child: _buildComparacao(),
          ),
        ],
      ),
    );
  }

  void _limparSlot(int index) {
    setState(() {
      if (index >= 2) {
        _slots.removeAt(index);
      } else {
        _slots[index] = null;
      }
    });
  }

  Widget _buildComparacao() {
    final selecionados = _slots.whereType<CandidatoModel>().toList();
    if (selecionados.length < 2) {
      return const AppEmptyState(
        title: 'Selecione ao menos dois candidatos',
        subtitle:
            'Toque nos cards acima para escolher de 2 a 4 candidatos',
      );
    }

    final seqsCsv = selecionados.map((c) => c.sequencial).join(',');
    return Consumer(
      builder: (ctx, ref, _) {
        final asyncData = ref.watch(comparacaoProvider(seqsCsv));
        return asyncData.when(
          loading: () => ListView.builder(
            itemCount: 5,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ShimmerSkeleton.card(height: 60),
            ),
          ),
          error: (e, _) => ErroInline(
            mensagem: 'Não foi possível carregar a comparação',
            onRetry: () => ref.invalidate(comparacaoProvider(seqsCsv)),
          ),
          data: (comp) => _ComparacaoResult(
            comparacao: comp,
            candidatos: selecionados,
            cores: _slotColors(Theme.of(context).colorScheme),
            labels: _slotLabels,
          ),
        );
      },
    );
  }

  Future<void> _selecionarCandidato(int index) async {
    final selected = await showModalBottomSheet<CandidatoModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BuscaCandidatoSheet(),
    );
    if (selected != null) {
      setState(() => _slots[index] = selected);
    }
  }
}

class _CandidatoSelector extends StatelessWidget {
  const _CandidatoSelector({
    required this.label,
    required this.candidato,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final CandidatoModel? candidato;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: candidato != null ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: candidato == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, color: cs.onSurfaceVariant),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          candidato!.nomeUrna,
                          style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onClear,
                        child: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  Text(
                    '${candidato!.siglaPartido} · ${formatarVotos(candidato!.votosTotal)} votos',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ComparacaoResult extends StatelessWidget {
  const _ComparacaoResult({
    required this.comparacao,
    required this.candidatos,
    required this.cores,
    required this.labels,
  });

  final ComparacaoModel comparacao;
  final List<CandidatoModel> candidatos;
  final List<Color> cores;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final diffs = comparacao.diffMunicipios;

    // Contadores (o diff do endpoint é sempre entre os dois primeiros)
    final vencA = diffs.where((d) => d.vencedor == 'a').length;
    final vencB = diffs.where((d) => d.vencedor == 'b').length;
    final empates = diffs.where((d) => d.vencedor == 'empate').length;
    final maxDiff = diffs.isNotEmpty
        ? diffs.map((d) => d.diferenca.abs()).reduce((a, b) => a > b ? a : b)
        : 0;

    final corA = cores[0];
    final corB = cores[1];
    final nomeA = candidatos[0].nomeUrna;
    final nomeB = candidatos[1].nomeUrna;
    final statsCards = comparacao.candidatos;

    return ListView(
      children: [
        // Cards de stats (grid 2 colunas — suporta até 4 candidatos)
        if (statsCards.length >= 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                for (var row = 0; row * 2 < statsCards.length; row++)
                  Padding(
                    padding: EdgeInsets.only(top: row > 0 ? 10 : 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var col = 0; col < 2; col++)
                          if (row * 2 + col < statsCards.length) ...[
                            if (col > 0) const SizedBox(width: 10),
                            _StatsCard(
                              candidato: statsCards[row * 2 + col],
                              color: cores[
                                  (row * 2 + col) % cores.length],
                              label: labels[row * 2 + col],
                            ),
                          ] else ...[
                            const SizedBox(width: 10),
                            const Expanded(child: SizedBox.shrink()),
                          ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (statsCards.length >= 2) ...[
          // Barra comparativa horizontal — participação relativa entre A e B
          _BarraComparativa(
            votosA: statsCards[0].stats.votosTotal,
            votosB: statsCards[1].stats.votosTotal,
            nomeA: nomeA,
            nomeB: nomeB,
            corA: corA,
            corB: corB,
          ),
          // KPIs de vitórias por município (A × B)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _KpiVencedor(
                  label: 'Vence A',
                  value: vencA,
                  color: corA,
                ),
                const SizedBox(width: 8),
                _KpiVencedor(
                  label: 'Vence B',
                  value: vencB,
                  color: corB,
                ),
                const SizedBox(width: 8),
                _KpiVencedor(
                  label: 'Empates',
                  value: empates,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DIFERENÇA POR MUNICÍPIO (A × B)',
                style: tt.labelSmall
                    ?.copyWith(letterSpacing: 0.8, color: cs.onSurfaceVariant),
              ),
              Text(
                '${diffs.length} municípios',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        ...diffs.map((d) => _DiffMunicipioItem(
              diff: d,
              nomeA: nomeA,
              nomeB: nomeB,
              corA: corA,
              corB: corB,
              maxDiff: maxDiff,
            )),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Barra comparativa horizontal (participação relativa) ────────────────────

class _BarraComparativa extends StatelessWidget {
  const _BarraComparativa({
    required this.votosA,
    required this.votosB,
    required this.nomeA,
    required this.nomeB,
    required this.corA,
    required this.corB,
  });

  final int votosA;
  final int votosB;
  final String nomeA;
  final String nomeB;
  final Color corA;
  final Color corB;

  @override
  Widget build(BuildContext context) {
    final total = votosA + votosB;
    final pctA = total > 0 ? (votosA * 100 / total) : 0.0;
    final pctB = total > 0 ? (votosB * 100 / total) : 0.0;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${pctA.toStringAsFixed(1)}%',
                style: tt.labelSmall
                    ?.copyWith(color: corA, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                'Participação entre os dois',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                '${pctB.toStringAsFixed(1)}%',
                style: tt.labelSmall
                    ?.copyWith(color: corB, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (pctA > 0)
                    Flexible(
                      flex: (pctA * 10).round().clamp(1, 10000),
                      child: Container(color: corA),
                    ),
                  if (pctB > 0)
                    Flexible(
                      flex: (pctB * 10).round().clamp(1, 10000),
                      child: Container(color: corB),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiVencedor extends StatelessWidget {
  const _KpiVencedor({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.candidato,
    required this.color,
    required this.label,
  });

  final ComparacaoCandidatoModel candidato;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: cs.surface,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    candidato.siglaPartido.isNotEmpty
                        ? candidato.siglaPartido
                        : candidato.partido,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              candidato.nomeUrna,
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              formatarNumero(candidato.stats.votosTotal),
              style: tt.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'votos totais',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    '${candidato.stats.municipiosAtingidos} municípios',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffMunicipioItem extends StatelessWidget {
  const _DiffMunicipioItem({
    required this.diff,
    required this.nomeA,
    required this.nomeB,
    required this.corA,
    required this.corB,
    required this.maxDiff,
  });

  final DiffMunicipioModel diff;
  final String nomeA;
  final String nomeB;
  final Color corA;
  final Color corB;
  final int maxDiff;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final cor = diff.vencedor == 'a'
        ? corA
        : diff.vencedor == 'b'
            ? corB
            : cs.onSurfaceVariant;
    final vencedorNome = diff.vencedor == 'a'
        ? nomeA
        : diff.vencedor == 'b'
            ? nomeB
            : 'Empate';

    // Barra bidirecional: esquerda = votos A, direita = votos B
    final totalRow = diff.votosA + diff.votosB;
    final pctA = totalRow > 0 ? (diff.votosA / totalRow) : 0.5;
    final pctB = totalRow > 0 ? (diff.votosB / totalRow) : 0.5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cor.withValues(alpha: 0.25),
          width: diff.vencedor == 'empate' ? 0.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  diff.nomeMunicipio,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vencedorNome,
                  style: tt.labelSmall?.copyWith(
                    color: cor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barra visual com votos de cada lado
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Flexible(
                    flex: (pctA * 1000).round().clamp(1, 100000),
                    child: Container(color: corA),
                  ),
                  Flexible(
                    flex: (pctB * 1000).round().clamp(1, 100000),
                    child: Container(color: corB),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // A
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: corA,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: cs.surface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                formatarNumero(diff.votosA),
                style: tt.labelSmall?.copyWith(
                  color: corA,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${diff.diferenca >= 0 ? '+' : '−'}${formatarNumero(diff.diferenca.abs())}',
                style: tt.labelSmall?.copyWith(
                  color: cor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                formatarNumero(diff.votosB),
                style: tt.labelSmall?.copyWith(
                  color: corB,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: corB,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Text(
                    'B',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: cs.surface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuscaCandidatoSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BuscaCandidatoSheet> createState() => _BuscaCandidatoSheetState();
}

class _BuscaCandidatoSheetState extends ConsumerState<_BuscaCandidatoSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (value == _ctrl.text) {
        ref.read(comparacaoSearchProvider.notifier).state = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final asyncData = ref.watch(comparacaoCandidatoBuscaProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Buscar Candidato',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Nome ou partido...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: _onSearch,
                ),
              ),
              Expanded(
                child: asyncData.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErroInline(
                    mensagem: 'Não foi possível buscar candidatos',
                    onRetry: () =>
                        ref.invalidate(comparacaoCandidatoBuscaProvider),
                  ),
                  data: (page) {
                    if (page.items.isEmpty && _ctrl.text.isNotEmpty) {
                      return const Center(child: Text('Nenhum candidato encontrado'));
                    }
                    if (_ctrl.text.isEmpty) {
                      return const Center(child: Text('Digite para buscar'));
                    }
                    return ListView.separated(
                      controller: scrollCtrl,
                      itemCount: page.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final c = page.items[i];
                        return ListTile(
                          title: Text(c.nomeUrna),
                          subtitle: Text('${c.siglaPartido} · ${formatarVotos(c.votosTotal)} votos'),
                          onTap: () => Navigator.of(ctx).pop(c),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
