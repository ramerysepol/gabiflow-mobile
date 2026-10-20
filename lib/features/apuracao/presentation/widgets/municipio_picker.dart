import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/apuracao_municipio_model.dart';

String _semAcento(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
  const para = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
  final b = StringBuffer();
  for (final ch in s.characters) {
    final i = de.indexOf(ch);
    b.write(i >= 0 ? para[i] : ch);
  }
  return b.toString().toUpperCase();
}

/// Campo de seleção de município com busca (417 cidades na Bahia): abre um
/// bottom sheet com campo de pesquisa sem acento e lista filtrada.
class MunicipioPickerField extends StatelessWidget {
  const MunicipioPickerField({
    super.key,
    required this.municipios,
    required this.valor,
    required this.onChanged,
    this.rotuloTodos = 'Todo o estado',
  });

  final List<ApuracaoMunicipioSimples> municipios;
  final String? valor;
  final void Function(String? cd) onChanged;
  final String rotuloTodos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final selecionado = valor == null
        ? null
        : municipios.cast<ApuracaoMunicipioSimples?>().firstWhere(
            (m) => m!.cd == valor,
            orElse: () => null,
          );
    final texto = selecionado?.nome ?? rotuloTodos;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: () => _abrir(context),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                selecionado == null
                    ? Icons.map_outlined
                    : Icons.location_city_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (selecionado != null)
                GestureDetector(
                  onTap: () => onChanged(null),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                )
              else
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrir(BuildContext context) async {
    final cd = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _MunicipioSheet(
        municipios: municipios,
        valor: valor,
        rotuloTodos: rotuloTodos,
      ),
    );
    // null = fechou sem escolher; '' = "todo o estado"
    if (cd == null) return;
    onChanged(cd.isEmpty ? null : cd);
  }
}

class _MunicipioSheet extends StatefulWidget {
  const _MunicipioSheet({
    required this.municipios,
    required this.valor,
    required this.rotuloTodos,
  });

  final List<ApuracaoMunicipioSimples> municipios;
  final String? valor;
  final String rotuloTodos;

  @override
  State<_MunicipioSheet> createState() => _MunicipioSheetState();
}

class _MunicipioSheetState extends State<_MunicipioSheet> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final q = _semAcento(_q.trim());
    final lista = q.isEmpty
        ? widget.municipios
        : widget.municipios
              .where((m) => _semAcento(m.nome).contains(q))
              .toList(growable: false);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Município',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${widget.municipios.length} municípios · digite para filtrar',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar município...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _q.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _ctrl.clear();
                              setState(() => _q = '');
                            },
                          ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: lista.length + (q.isEmpty ? 1 : 0),
              itemBuilder: (context, i) {
                if (q.isEmpty && i == 0) {
                  final sel = widget.valor == null;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.map_outlined,
                      color: sel ? cs.primary : cs.onSurfaceVariant,
                    ),
                    title: Text(
                      widget.rotuloTodos,
                      style: TextStyle(
                        fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                        color: sel ? cs.primary : null,
                      ),
                    ),
                    trailing: sel
                        ? Icon(Icons.check_rounded, color: cs.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(''),
                  );
                }
                final m = lista[q.isEmpty ? i - 1 : i];
                final sel = m.cd == widget.valor;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    m.capital
                        ? Icons.star_rounded
                        : Icons.location_city_rounded,
                    size: 20,
                    color: m.capital
                        ? const Color(0xFFD97706)
                        : (sel ? cs.primary : cs.onSurfaceVariant),
                  ),
                  title: Text(
                    m.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                      color: sel ? cs.primary : null,
                    ),
                  ),
                  trailing: sel
                      ? Icon(Icons.check_rounded, color: cs.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(m.cd),
                );
              },
            ),
          ),
          if (lista.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Nenhum município encontrado para "$_q".',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
