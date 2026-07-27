import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/eleitoral_providers.dart';

/// Bottom sheet de busca de município para o mapa.
/// Ao selecionar, chama [onSelected] com a microrregião que contém o município
/// e o id do município.
class SeletorMunicipioSheet extends ConsumerStatefulWidget {
  const SeletorMunicipioSheet({
    super.key,
    required this.onSelected,
  });

  final void Function(String idMunicipio, String nomeMunicipio) onSelected;

  @override
  ConsumerState<SeletorMunicipioSheet> createState() =>
      _SeletorMunicipioSheetState();
}

class _SeletorMunicipioSheetState
    extends ConsumerState<SeletorMunicipioSheet> {
  String _search = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _search = value.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Use microrregioes para extrair lista de municípios (id + nome)
    final asyncData = ref.watch(ibgeMicrorregioesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Buscar Município',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Nome do município...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _onSearch,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: asyncData.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Erro ao carregar municípios',
                      style: TextStyle(color: cs.error),
                    ),
                  ),
                  data: (micros) {
                    // Monta lista flat de municípios ({id, nome, microrregiao})
                    final allMunicipios = <_MunicipioEntry>[];
                    for (final micro in micros) {
                      for (final m in micro.municipios) {
                        allMunicipios.add(_MunicipioEntry(
                          id: m.id,
                          nome: m.nome,
                          microrregiao: micro.nome,
                        ));
                      }
                    }
                    allMunicipios.sort((a, b) => a.nome.compareTo(b.nome));

                    final filtered = _search.isEmpty
                        ? allMunicipios
                        : allMunicipios
                            .where((m) =>
                                m.nome.toLowerCase().contains(_search) ||
                                m.microrregiao.toLowerCase().contains(_search))
                            .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhum município encontrado',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final m = filtered[i];
                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_city,
                              size: 14,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            m.nome,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            m.microrregiao,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () {
                            // Fecha o seletor ANTES de chamar o callback —
                            // senão showModalBottomSheet subsequente é fechado
                            // junto pelo pop.
                            Navigator.of(ctx).pop();
                            widget.onSelected(m.id, m.nome);
                          },
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

class _MunicipioEntry {
  final String id;
  final String nome;
  final String microrregiao;

  const _MunicipioEntry({
    required this.id,
    required this.nome,
    required this.microrregiao,
  });
}
