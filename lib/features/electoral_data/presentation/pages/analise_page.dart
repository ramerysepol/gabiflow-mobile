import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/estatisticas_model.dart';
import '../providers/eleitoral_providers.dart';
import '../widgets/eleicao_contexto_chip.dart';
import '../widgets/partido_detalhe_sheet.dart';

final _numFmt = NumberFormat.decimalPattern('pt_BR');

/// Página de Análise da eleição — paridade com o dashboard
/// "análise/estatísticas" do desktop: KPIs, gênero, situação e partidos.
class AnalisePage extends ConsumerWidget {
  const AnalisePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(estatisticasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise da Eleição'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: EleicaoContextoChip()),
          ),
        ],
      ),
      body: async.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerSkeleton.card(height: 110),
            ),
          ),
        ),
        error: (e, _) => AppEmptyState(
          title: 'Erro ao carregar análise',
          subtitle: e.toString(),
          actionLabel: 'Tentar novamente',
          onAction: () => ref.invalidate(estatisticasProvider),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(estatisticasProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _KpiGrid(stats: stats),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _GeneroDonut(genero: stats.genero)),
                  const SizedBox(width: 12),
                  Expanded(child: _SituacaoDonut(situacao: stats.situacao)),
                ],
              ),
              const SizedBox(height: 16),
              _PartidosRanking(
                ranking: stats.partidosRanking,
                total: stats.totalPartidos,
              ),
              const SizedBox(height: 16),
              _TopCandidatos(candidatos: stats.candidatosMaisVotados),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── KPIs ────────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats});

  final EstatisticasModel stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            _KpiBox(
              label: 'Candidatos',
              value: _numFmt.format(stats.totalCandidatos),
              icon: Icons.groups_outlined,
              color: cs.primary,
            ),
            const SizedBox(width: 10),
            _KpiBox(
              label: 'Eleitos',
              value: _numFmt.format(stats.candidatosEleitos),
              sub: '${stats.percentualEleitos.toStringAsFixed(1)}%',
              icon: Icons.emoji_events_outlined,
              color: Colors.green.shade700,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _KpiBox(
              label: 'Mulheres',
              value: '${stats.candidatasMulheresPct.toStringAsFixed(1)}%',
              sub: '${_numFmt.format(stats.genero.feminino)} candidatas',
              icon: Icons.female_rounded,
              color: Colors.purple.shade600,
            ),
            const SizedBox(width: 10),
            _KpiBox(
              label: 'Partidos',
              value: _numFmt.format(stats.totalPartidos),
              icon: Icons.flag_outlined,
              color: Colors.orange.shade700,
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiBox extends StatelessWidget {
  const _KpiBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sub,
  });

  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            if (sub != null)
              Text(
                sub!,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Donut de gênero ─────────────────────────────────────────────────────────

class _GeneroDonut extends StatelessWidget {
  const _GeneroDonut({required this.genero});

  final EstatisticasGenero genero;

  @override
  Widget build(BuildContext context) {
    final total = genero.masculino + genero.feminino;
    final sections = <PieChartSectionData>[
      if (genero.masculino > 0)
        PieChartSectionData(
          value: genero.masculino.toDouble(),
          color: Colors.blue.shade600,
          showTitle: false,
          radius: 22,
        ),
      if (genero.feminino > 0)
        PieChartSectionData(
          value: genero.feminino.toDouble(),
          color: Colors.purple.shade400,
          showTitle: false,
          radius: 22,
        ),
    ];

    return _ChartCard(
      title: 'Gênero',
      icon: Icons.wc_rounded,
      child: total == 0
          ? const SizedBox(height: 100)
          : Column(
              children: [
                SizedBox(
                  height: 100,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 26,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _LegendaLinha(
                  color: Colors.blue.shade600,
                  label: 'Homens',
                  value:
                      '${(genero.masculino / total * 100).toStringAsFixed(0)}%',
                ),
                _LegendaLinha(
                  color: Colors.purple.shade400,
                  label: 'Mulheres',
                  value:
                      '${(genero.feminino / total * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
    );
  }
}

// ─── Donut de situação ───────────────────────────────────────────────────────

class _SituacaoDonut extends StatelessWidget {
  const _SituacaoDonut({required this.situacao});

  final List<EstatisticasSituacao> situacao;

  static const _cores = [
    Color(0xFF16A34A),
    Color(0xFFD97706),
    Color(0xFFDC2626),
    Color(0xFF64748B),
    Color(0xFF0284C7),
  ];

  @override
  Widget build(BuildContext context) {
    final relevantes = situacao.take(4).toList();
    final total = relevantes.fold<int>(0, (s, e) => s + e.total);

    return _ChartCard(
      title: 'Situação',
      icon: Icons.how_to_reg_outlined,
      child: total == 0
          ? const SizedBox(height: 100)
          : Column(
              children: [
                SizedBox(
                  height: 100,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        for (final (i, s) in relevantes.indexed)
                          PieChartSectionData(
                            value: s.total.toDouble(),
                            color: _cores[i % _cores.length],
                            showTitle: false,
                            radius: 22,
                          ),
                      ],
                      centerSpaceRadius: 26,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final (i, s) in relevantes.indexed)
                  _LegendaLinha(
                    color: _cores[i % _cores.length],
                    label: _statusLabel(s.status),
                    value: _numFmt.format(s.total),
                  ),
              ],
            ),
    );
  }

  String _statusLabel(String s) {
    final t = s.trim();
    if (t.isEmpty || t == 'não informado') return 'Não informado';
    return '${t[0].toUpperCase()}${t.substring(1)}';
  }
}

class _LegendaLinha extends StatelessWidget {
  const _LegendaLinha({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: tt.labelSmall?.copyWith(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: tt.labelSmall
                ?.copyWith(fontWeight: FontWeight.w700, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: cs.primary),
              const SizedBox(width: 5),
              Text(
                title,
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ─── Ranking de partidos ─────────────────────────────────────────────────────

class _PartidosRanking extends StatelessWidget {
  const _PartidosRanking({required this.ranking, required this.total});

  final List<PartidoRankingItem> ranking;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final top = ranking.take(10).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    final maxVotos =
        top.map((p) => p.votos).fold<int>(0, (a, b) => a > b ? a : b);

    return _ChartCard(
      title: 'Partidos ($total)',
      icon: Icons.flag_outlined,
      child: Column(
        children: [
          for (final p in top)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showPartidoDetalheSheet(context, p.sigla),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 74,
                      child: Text(
                        p.sigla,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxVotos > 0 ? p.votos / maxVotos : 0,
                          minHeight: 12,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(cs.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 92,
                      child: Text(
                        '${_numFmt.format(p.votos)} · ${p.eleitos} el.',
                        textAlign: TextAlign.right,
                        style: tt.labelSmall?.copyWith(fontSize: 10),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 14, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Top candidatos ──────────────────────────────────────────────────────────

class _TopCandidatos extends StatelessWidget {
  const _TopCandidatos({required this.candidatos});

  final List<TopCandidatoItem> candidatos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (candidatos.isEmpty) return const SizedBox.shrink();

    return _ChartCard(
      title: 'Mais votados',
      icon: Icons.leaderboard_outlined,
      child: Column(
        children: [
          for (final (i, c) in candidatos.take(10).indexed)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context
                  .push('/home/eleitoral/candidato/${c.sequencial}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < 3
                            ? [
                                const Color(0xFFFFD700),
                                const Color(0xFFC0C0C0),
                                const Color(0xFFCD7F32),
                              ][i]
                                .withValues(alpha: 0.25)
                            : cs.surfaceContainerHighest,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.nomeUrna.isNotEmpty ? c.nomeUrna : c.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            c.siglaPartido,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (c.eleito)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ELEITO',
                          style: tt.labelSmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    Text(
                      _numFmt.format(c.votos),
                      style: tt.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
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
