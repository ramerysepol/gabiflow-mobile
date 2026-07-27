import 'package:flutter/material.dart';

import '../../data/models/candidato_stats_model.dart';
import 'numero_formatado.dart';

class TopMunicipiosList extends StatelessWidget {
  const TopMunicipiosList({
    super.key,
    required this.municipios,
    this.onTap,
  });

  final List<TopMunicipioModel> municipios;
  final void Function(TopMunicipioModel)? onTap;

  @override
  Widget build(BuildContext context) {
    if (municipios.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum município encontrado'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'TOP 10 MUNICÍPIOS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        ...municipios.asMap().entries.map(
          (entry) => _MunicipioItem(
            posicao: entry.key + 1,
            municipio: entry.value,
            maxVotos: municipios.first.votosMunicipio,
            onTap: onTap != null ? () => onTap!(entry.value) : null,
          ),
        ),
      ],
    );
  }
}

class _MunicipioItem extends StatelessWidget {
  const _MunicipioItem({
    required this.posicao,
    required this.municipio,
    required this.maxVotos,
    this.onTap,
  });

  final int posicao;
  final TopMunicipioModel municipio;
  final int maxVotos;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final pct = maxVotos > 0 ? municipio.votosMunicipio / maxVotos : 0.0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$posicao',
                style: tt.labelSmall?.copyWith(
                  color: posicao <= 3 ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: posicao <= 3 ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    municipio.nomeMunicipio,
                    style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatarNumero(municipio.votosMunicipio),
                  style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${formatarDecimal(municipio.percentualMunicipio)}%',
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
    );
  }
}
