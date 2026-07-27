import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/hierarquia_nivel_model.dart';
import '../providers/eleitoral_providers.dart';
import 'erro_inline.dart';
import 'numero_formatado.dart';

/// Árvore expansível de hierarquia territorial.
class HierarquiaTree extends ConsumerWidget {
  const HierarquiaTree({super.key, required this.sequencial});

  final String sequencial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = HierarquiaParams(
      sequencial: sequencial,
      nivel: HierarquiaNivel.mesorregiao,
    );
    final asyncData = ref.watch(hierarquiaProvider(params));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErroInline(
        mensagem: 'Não foi possível carregar a hierarquia',
        onRetry: () => ref.invalidate(hierarquiaProvider(params)),
      ),
      data: (data) => ListView.builder(
        itemCount: data.items.length,
        itemBuilder: (ctx, i) => _HierarquiaNode(
          item: data.items[i],
          sequencial: sequencial,
          nivel: HierarquiaNivel.mesorregiao,
          depth: 0,
        ),
      ),
    );
  }
}

class _HierarquiaNode extends ConsumerStatefulWidget {
  const _HierarquiaNode({
    required this.item,
    required this.sequencial,
    required this.nivel,
    required this.depth,
  });

  final HierarquiaItemModel item;
  final String sequencial;
  final String nivel;
  final int depth;

  @override
  ConsumerState<_HierarquiaNode> createState() => _HierarquiaNodeState();
}

class _HierarquiaNodeState extends ConsumerState<_HierarquiaNode> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final nextNivel = HierarquiaNivel.proximo(widget.nivel);
    final hasChildren = widget.item.temFilhos && nextNivel != null;
    final nextNivelSafe = nextNivel ?? HierarquiaNivel.municipio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: hasChildren
              ? () => setState(() => _expanded = !_expanded)
              : null,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0 + widget.depth * 16,
              right: 16,
              top: 10,
              bottom: 10,
            ),
            child: Row(
              children: [
                if (hasChildren)
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right, size: 20, color: cs.primary),
                  )
                else
                  SizedBox(width: 20, child: Icon(Icons.circle, size: 6, color: cs.onSurfaceVariant)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.nome,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: widget.depth == 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      Text(
                        HierarquiaNivel.label(widget.nivel),
                        style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatarNumero(widget.item.votosTotal),
                      style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${formatarDecimal(widget.item.percentual)}%',
                      style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_expanded && hasChildren)
          _ChildrenLoader(
            sequencial: widget.sequencial,
            nivel: nextNivelSafe,
            paiId: widget.item.id,
            depth: widget.depth + 1,
          ),
        if (widget.depth == 0) const Divider(height: 1),
      ],
    );
  }
}

class _ChildrenLoader extends ConsumerWidget {
  const _ChildrenLoader({
    required this.sequencial,
    required this.nivel,
    required this.paiId,
    required this.depth,
  });

  final String sequencial;
  final String nivel;
  final String paiId;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = HierarquiaParams(
      sequencial: sequencial,
      nivel: nivel,
      paiId: paiId,
    );
    final asyncData = ref.watch(hierarquiaProvider(params));

    return asyncData.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'Não foi possível carregar este nível',
          style:
              TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
        ),
      ),
      data: (data) => Column(
        children: data.items.map((item) {
          return _HierarquiaNode(
            item: item,
            sequencial: sequencial,
            nivel: nivel,
            depth: depth,
          );
        }).toList(),
      ),
    );
  }
}
