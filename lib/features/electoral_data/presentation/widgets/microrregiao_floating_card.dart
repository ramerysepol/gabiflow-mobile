import 'package:flutter/material.dart';

import '../../data/models/ibge_municipio_model.dart';
import '../../data/models/municipio_voto_model.dart';
import 'numero_formatado.dart';

/// Card flutuante sobre o mapa exibindo totais da microrregião selecionada.
/// Não é bloqueante (diferente de um bottom sheet).
class MicrorregiaoFloatingCard extends StatelessWidget {
  const MicrorregiaoFloatingCard({
    super.key,
    required this.micro,
    required this.municipios,
    required this.onClear,
    required this.onVerTodos,
  });

  final IbgeMicrorregiao micro;
  final List<MunicipioVotoModel> municipios;
  final VoidCallback onClear;
  final VoidCallback onVerTodos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final idsSet = Set<String>.from(micro.municipioIds);
    final municipiosNaMicro = municipios
        .where((m) => idsSet.contains(m.idMunicipio))
        .toList()
      ..sort((a, b) => b.votosMunicipio.compareTo(a.votosMunicipio));

    final totalVotos =
        municipiosNaMicro.fold(0, (sum, m) => sum + m.votosMunicipio);
    final cobertura = municipiosNaMicro.length;
    final top3 = municipiosNaMicro.take(3).toList();

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(Icons.layers, size: 14, color: cs.onPrimaryContainer),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        micro.nome,
                        style: tt.labelMedium?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$cobertura/${micro.municipios.length} municípios',
                        style: TextStyle(
                          fontSize: 9,
                          color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: cs.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
          // Votos totais
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Text(
                  formatarNumero(totalVotos),
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'votos totais',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Top 3 municípios
          if (top3.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
              child: Text(
                'TOP MUNICÍPIOS',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            ...top3.map((m) => _TopMunicipioRow(municipio: m, total: totalVotos)),
          ],
          // Botão Ver todos
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onVerTodos,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Ver todos os municípios',
                  style: TextStyle(fontSize: 11, color: cs.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMunicipioRow extends StatelessWidget {
  const _TopMunicipioRow({required this.municipio, required this.total});

  final MunicipioVotoModel municipio;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final frac = total > 0 ? municipio.votosMunicipio / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  municipio.nomeMunicipio,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatarVotos(municipio.votosMunicipio),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: frac.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
