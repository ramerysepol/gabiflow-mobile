import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ibge_municipio_model.dart';
import '../providers/eleitoral_providers.dart';
import 'erro_inline.dart';

/// Bottom sheet para seleção de microrregião — filtra o mapa.
class SeletorMicrorregiao extends ConsumerStatefulWidget {
  const SeletorMicrorregiao({
    super.key,
    required this.onSelected,
    required this.onClear,
  });

  final void Function(IbgeMicrorregiao) onSelected;
  final VoidCallback onClear;

  @override
  ConsumerState<SeletorMicrorregiao> createState() => _SeletorMicrorregiaoState();
}

class _SeletorMicrorregiaoState extends ConsumerState<SeletorMicrorregiao> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(ibgeMicrorregioesProvider);
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Selecionar Microrregião',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onClear();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Limpar filtro'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar microrregião...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: asyncData.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErroInline(
                    mensagem: 'Não foi possível carregar as microrregiões',
                    onRetry: () => ref.invalidate(ibgeMicrorregioesProvider),
                  ),
                  data: (micros) {
                    final filtered = _search.isEmpty
                        ? micros
                        : micros.where((m) => m.nome.toLowerCase().contains(_search)).toList();
                    return ListView.separated(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final micro = filtered[i];
                        return ListTile(
                          title: Text(micro.nome),
                          subtitle: Text('${micro.municipios.length} municípios'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Fecha o sheet ANTES do callback pra evitar que
                            // futuras sheets (ex.: card/overlay) sejam descartadas
                            // pelo pop.
                            Navigator.of(ctx).pop();
                            widget.onSelected(micro);
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
