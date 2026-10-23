import 'package:flutter/material.dart';

import '../../data/models/demanda_extras.dart';
import '../../data/models/demanda_vocab.dart';

/// Filtro rápido: área, prioridade e "minhas".
Future<DemandaFiltros?> mostrarFiltrosDemanda(
  BuildContext context,
  DemandaFiltros atual,
) {
  return showModalBottomSheet<DemandaFiltros>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FiltrosSheet(atual: atual),
  );
}

class _FiltrosSheet extends StatefulWidget {
  const _FiltrosSheet({required this.atual});
  final DemandaFiltros atual;

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late DemandaFiltros _f = widget.atual;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrar demandas', style: tt.titleMedium),
            const SizedBox(height: 16),
            Text('Área', style: tt.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final a in const ['geral', 'saude'])
                  ChoiceChip(
                    label: Text(DemandaVocab.area(a)),
                    selected: _f.area == a,
                    onSelected: (v) => setState(
                      () => _f = _f.copyWith(area: () => v ? a : null),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Prioridade', style: tt.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final p in DemandaVocab.prioridadeLista)
                  ChoiceChip(
                    label: Text(DemandaVocab.prioridade(p)),
                    selected: _f.prioridade == p,
                    onSelected: (v) => setState(
                      () => _f = _f.copyWith(prioridade: () => v ? p : null),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Somente minhas demandas'),
              value: _f.minhas,
              onChanged: (v) => setState(() => _f = _f.copyWith(minhas: v)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, _f.semRapidos()),
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _f),
                    child: const Text('Aplicar'),
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
