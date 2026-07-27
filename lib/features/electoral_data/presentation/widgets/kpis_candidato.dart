import 'package:flutter/material.dart';

import '../../data/models/candidato_stats_model.dart';
import 'numero_formatado.dart';

/// Grid 2×2 de KPIs do candidato.
class KpisCandidato extends StatelessWidget {
  const KpisCandidato({super.key, required this.stats});

  final CandidatoStatsModel stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.0,
      children: [
        _KpiTile(
          label: 'Votos totais',
          value: formatarNumero(stats.votosTotal),
          icon: Icons.how_to_vote_outlined,
        ),
        _KpiTile(
          label: 'Municípios',
          value: '${stats.municipiosAtingidos}',
          icon: Icons.location_city_outlined,
        ),
        _KpiTile(
          label: '% do Estado',
          value: '${formatarDecimal(stats.percentualEstado)}%',
          icon: Icons.pie_chart_outline,
        ),
        _KpiTile(
          label: 'Ranking',
          value: '#${stats.rankingCargo}/${stats.totalCandidatosCargo}',
          icon: Icons.leaderboard_outlined,
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
