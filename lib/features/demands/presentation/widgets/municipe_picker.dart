import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/friendly_error.dart';
import '../../../constituents/data/models/constituent_model.dart';
import '../../../constituents/presentation/providers/constituent_provider.dart';

/// Abre a busca de munícipes (reaproveita o datasource de constituents).
Future<ConstituentModel?> escolherMunicipe(BuildContext context) {
  return showModalBottomSheet<ConstituentModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _MunicipeSheet(),
  );
}

class _MunicipeSheet extends ConsumerStatefulWidget {
  const _MunicipeSheet();

  @override
  ConsumerState<_MunicipeSheet> createState() => _MunicipeSheetState();
}

class _MunicipeSheetState extends ConsumerState<_MunicipeSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<ConstituentModel> _itens = const [];
  bool _carregando = false;
  String? _erro;
  int _geracao = 0;

  @override
  void initState() {
    super.initState();
    _buscar('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _buscar(String termo) async {
    final g = ++_geracao;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final r = await ref
          .read(constituentDataSourceProvider)
          .getConstituents(search: termo.trim(), limit: 20);
      if (!mounted || g != _geracao) return;
      setState(() {
        _itens = r.items;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted || g != _geracao) return;
      setState(() {
        _erro = mensagemAmigavel(e);
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final altura = MediaQuery.of(context).size.height * 0.75;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: altura,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar munícipe por nome, CPF ou telefone',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 350),
                    () => _buscar(v),
                  );
                },
              ),
            ),
            if (_carregando) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _erro != null
                  ? Center(child: Text(_erro!))
                  : _itens.isEmpty && !_carregando
                  ? const Center(child: Text('Nenhum munícipe encontrado'))
                  : ListView.builder(
                      itemCount: _itens.length,
                      itemBuilder: (_, i) {
                        final m = _itens[i];
                        final sub = [
                          m.telefone,
                          m.bairro,
                        ].where((e) => e != null && e.isNotEmpty).join(' · ');
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              m.nome.isEmpty ? '?' : m.nome[0].toUpperCase(),
                              style: TextStyle(color: cs.onPrimaryContainer),
                            ),
                          ),
                          title: Text(
                            m.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: sub.isEmpty ? null : Text(sub),
                          onTap: () => Navigator.pop(context, m),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
