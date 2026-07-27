import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../electoral_data/data/models/candidato_model.dart';
import '../../../electoral_data/presentation/providers/eleitoral_providers.dart';
import '../../data/models/ia_contexto_model.dart';
import '../providers/command_center_providers.dart';

/// Abre o seletor de candidato para o Command Center.
/// Retorna o contexto selecionado (também já persiste no provider).
Future<IaContexto?> showIaCandidatoPicker(BuildContext context) {
  return showModalBottomSheet<IaContexto>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _CandidatoPickerSheet(),
  );
}

class _CandidatoPickerSheet extends ConsumerStatefulWidget {
  const _CandidatoPickerSheet();

  @override
  ConsumerState<_CandidatoPickerSheet> createState() =>
      _CandidatoPickerSheetState();
}

class _CandidatoPickerSheetState extends ConsumerState<_CandidatoPickerSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<CandidatoModel> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final filtros = ref.read(filtrosSelecionadosProvider);
      final page = await ref.read(eleitoralDatasourceProvider).getCandidatos(
            ano: filtros.ano,
            estado: filtros.estado,
            cargo: filtros.cargo,
            search: query,
            limit: 20,
          );
      if (mounted) {
        setState(() {
          _results = page.items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _select(CandidatoModel c) async {
    final contexto = IaContexto(
      sequencial: c.sequencial,
      nomeCandidato: c.nomeUrna.isNotEmpty ? c.nomeUrna : c.nome,
      siglaPartido: c.siglaPartido,
      cargo: c.cargo,
      votosTotal: c.votosTotal,
      fotoUrl: c.fotoUrl,
    );
    await ref.read(iaContextoProvider.notifier).select(contexto);
    if (mounted) Navigator.of(context).pop(contexto);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.person_search_rounded, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Quem você quer analisar?',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onChanged,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Buscar candidato...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(_error!,
                                textAlign: TextAlign.center,
                                style: tt.bodySmall),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollCtrl,
                          itemCount: _results.length,
                          itemBuilder: (_, i) {
                            final c = _results[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    cs.primaryContainer.withValues(alpha: 0.6),
                                backgroundImage: c.fotoUrl != null
                                    ? CachedNetworkImageProvider(c.fotoUrl!)
                                    : null,
                                child: c.fotoUrl == null
                                    ? Text(
                                        c.nomeUrna.isNotEmpty
                                            ? c.nomeUrna[0]
                                            : '?',
                                        style: TextStyle(
                                            color: cs.onPrimaryContainer),
                                      )
                                    : null,
                              ),
                              title: Text(
                                c.nomeUrna.isNotEmpty ? c.nomeUrna : c.nome,
                                style: tt.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${c.siglaPartido} · ${_formatVotos(c.votosTotal)} votos',
                                style: tt.labelSmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              trailing: const Icon(Icons.chevron_right, size: 18),
                              onTap: () => _select(c),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  String _formatVotos(int votos) {
    if (votos >= 1000000) {
      return '${(votos / 1000000).toStringAsFixed(1)}M';
    }
    if (votos >= 1000) return '${(votos / 1000).toStringAsFixed(1)}k';
    return votos.toString();
  }
}
