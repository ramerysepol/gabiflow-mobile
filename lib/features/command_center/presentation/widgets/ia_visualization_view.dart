import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/ia_chat_models.dart';

final _numFmt = NumberFormat.decimalPattern('pt_BR');

String _fmt(num? v) => _numFmt.format(v ?? 0);

int _asInt(dynamic v) =>
    v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

double _asDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

/// Renderiza uma visualização inline gerada pelas tools da IA.
class IaVisualizationView extends StatelessWidget {
  const IaVisualizationView({super.key, required this.viz});

  final IaVisualization viz;

  @override
  Widget build(BuildContext context) {
    switch (viz.kind) {
      case 'bar_chart_municipios':
        return _BarChartCard(
          title: 'Votos por município',
          icon: Icons.location_city_rounded,
          items: _mapItems(
            viz.data,
            label: (m) => (m['nome_municipio'] ?? '').toString(),
            value: (m) => _asInt(m['votos']),
          ),
        );
      case 'bar_chart_adversarios':
        return _BarChartCard(
          title: 'Ranking de adversários',
          icon: Icons.emoji_events_outlined,
          items: _mapItems(
            viz.data,
            label: (m) =>
                (m['nome_urna'] ?? m['nome'] ?? '').toString(),
            value: (m) => _asInt(m['votos']),
          ),
        );
      case 'heatmap_territorial':
        return _HeatmapMesorregiao(data: viz.data);
      case 'ranking_table':
        return _RankingTable(data: viz.data);
      case 'municipio_card':
        return _MunicipioCard(data: viz.data);
      case 'comparison_card':
      case 'metric_cards':
        return _GenericKeyValueCard(data: viz.data);
      default:
        return const SizedBox.shrink();
    }
  }

  List<({String label, int value})> _mapItems(
    dynamic data, {
    required String Function(Map<String, dynamic>) label,
    required int Function(Map<String, dynamic>) value,
  }) {
    if (data is! List) return const [];
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.cast<String, dynamic>())
        .map((m) => (label: label(m), value: value(m)))
        .where((e) => e.label.isNotEmpty)
        .take(10)
        .toList();
  }
}

// ─── Container base ──────────────────────────────────────────────────────────

class _VizCard extends StatelessWidget {
  const _VizCard({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              _FonteBadge(),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FonteBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'dados reais',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ─── Bar chart horizontal ────────────────────────────────────────────────────

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<({String label, int value})> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxValue =
        items.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return _VizCard(
      title: title,
      icon: icon,
      child: Column(
        children: [
          for (final (i, item) in items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.labelSmall?.copyWith(fontSize: 10.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxValue > 0 ? item.value / maxValue : 0,
                        minHeight: 14,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          i == 0
                              ? cs.primary
                              : cs.primary.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: Text(
                      _fmt(item.value),
                      textAlign: TextAlign.right,
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Heatmap por mesorregião (cobertura territorial) ─────────────────────────

class _HeatmapMesorregiao extends StatelessWidget {
  const _HeatmapMesorregiao({required this.data});

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    if (data is! List) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rows = (data as List)
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    return _VizCard(
      title: 'Cobertura por mesorregião',
      icon: Icons.grid_view_rounded,
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          (row['mesorregiao'] ?? '').toString(),
                          style: tt.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_fmt(_asInt(row['total_votos']))} votos · '
                        '${_asDouble(row['cobertura_percentual']).toStringAsFixed(0)}%',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (_asDouble(row['cobertura_percentual']) / 100)
                          .clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        _coberturaColor(
                            _asDouble(row['cobertura_percentual']), cs),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _coberturaColor(double pct, ColorScheme cs) {
    if (pct >= 70) return Colors.green.shade600;
    if (pct >= 40) return Colors.orange.shade600;
    return cs.error;
  }
}

// ─── Tabela de ranking (votos × gabinete) ────────────────────────────────────

class _RankingTable extends StatelessWidget {
  const _RankingTable({required this.data});

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    if (data is! List) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rows = (data as List)
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.cast<String, dynamic>())
        .take(8)
        .toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    final labelStyle = tt.labelSmall?.copyWith(
      fontSize: 10,
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final cellStyle = tt.labelSmall?.copyWith(fontSize: 10.5);

    return _VizCard(
      title: 'Oportunidades: votos × gabinete',
      icon: Icons.track_changes_rounded,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.4),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            children: [
              Text('Município', style: labelStyle),
              Text('Votos', style: labelStyle, textAlign: TextAlign.right),
              Text('Contatos', style: labelStyle, textAlign: TextAlign.right),
              Text('Gap', style: labelStyle, textAlign: TextAlign.right),
            ],
          ),
          for (final row in rows)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    (row['nome_municipio'] ?? '').toString(),
                    style: cellStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(_fmt(_asInt(row['votos'])),
                      style: cellStyle, textAlign: TextAlign.right),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                      _fmt(_asInt(row['constituintes_cadastrados'])),
                      style: cellStyle,
                      textAlign: TextAlign.right),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    _fmt(_asInt(row['gap_score'])),
                    style: cellStyle?.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Card de município ───────────────────────────────────────────────────────

class _MunicipioCard extends StatelessWidget {
  const _MunicipioCard({required this.data});

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    if (data is! Map) return const SizedBox.shrink();
    final m = (data as Map).cast<String, dynamic>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final chips = <(String, String)>[];
    if (m['votos'] != null) chips.add(('Votos', _fmt(_asInt(m['votos']))));
    if (m['ranking_no_municipio'] != null) {
      chips.add(('Posição', '${_asInt(m['ranking_no_municipio'])}º'));
    }
    if (m['mesorregiao'] != null) {
      chips.add(('Mesorregião', m['mesorregiao'].toString()));
    }
    final populacao = m['populacao'];
    if (populacao is Map && populacao['total'] != null) {
      chips.add(('População', _fmt(_asInt(populacao['total']))));
    }
    final pib = m['pib_per_capita'];
    if (pib is Map && pib['valor_reais'] != null) {
      chips.add(('PIB per capita', 'R\$ ${_fmt(_asInt(pib['valor_reais']))}'));
    }

    return _VizCard(
      title: (m['nome_municipio'] ?? 'Município').toString(),
      icon: Icons.place_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (label, value) in chips)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: tt.labelSmall?.copyWith(
                          fontSize: 9, color: cs.onSurfaceVariant)),
                  Text(value,
                      style: tt.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Fallback genérico (metric_cards / comparison_card) ──────────────────────

class _GenericKeyValueCard extends StatelessWidget {
  const _GenericKeyValueCard({required this.data});

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    if (data is! Map) return const SizedBox.shrink();
    final m = (data as Map).cast<String, dynamic>();
    final tt = Theme.of(context).textTheme;
    final entries = m.entries
        .where((e) => e.value is String || e.value is num)
        .take(8)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return _VizCard(
      title: 'Métricas',
      icon: Icons.insights_rounded,
      child: Column(
        children: [
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key.replaceAll('_', ' '),
                      style: tt.labelSmall
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Text(
                    e.value is num ? _fmt(e.value as num) : e.value.toString(),
                    style:
                        tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Gráfico de pizza simples da distribuição de presença do radar.
/// Usado no hub do Command Center.
class RadarPresencaPie extends StatelessWidget {
  const RadarPresencaPie({
    super.key,
    required this.forte,
    required this.apenasVotos,
    required this.semPresenca,
  });

  final int forte;
  final int apenasVotos;
  final int semPresenca;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = forte + apenasVotos + semPresenca;
    if (total == 0) return const SizedBox.shrink();

    // Largura fixa: PieChart dentro de Row sem constraint tenta largura
    // infinita e estoura o layout do card.
    return SizedBox(
      width: 110,
      height: 110,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 26,
          sections: [
            PieChartSectionData(
              value: forte.toDouble(),
              color: Colors.green.shade600,
              title: '$forte',
              radius: 32,
              titleStyle: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            PieChartSectionData(
              value: apenasVotos.toDouble(),
              color: Colors.orange.shade600,
              title: '$apenasVotos',
              radius: 32,
              titleStyle: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            PieChartSectionData(
              value: semPresenca.toDouble(),
              color: cs.outlineVariant,
              title: '$semPresenca',
              radius: 32,
              titleStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
