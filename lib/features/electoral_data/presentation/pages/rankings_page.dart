import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/shimmer_skeleton.dart';
import '../providers/eleitoral_providers.dart';
import '../widgets/eleicao_contexto_chip.dart';
import '../widgets/erro_inline.dart';
import '../widgets/ranking_item.dart';

class RankingsPage extends ConsumerStatefulWidget {
  const RankingsPage({super.key});

  @override
  ConsumerState<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends ConsumerState<RankingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tipos = ['municipios', 'partidos', 'coligacoes'];
  static const _labels = ['Municípios', 'Partidos', 'Coligações'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rankings'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: EleicaoContextoChip()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tipos.map((tipo) => _RankingList(tipo: tipo)).toList(),
      ),
    );
  }
}

class _RankingList extends ConsumerWidget {
  const _RankingList({required this.tipo});

  final String tipo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtros = ref.watch(filtrosSelecionadosProvider);
    final params = RankingParams(tipo: tipo, cargo: filtros.cargo);
    final asyncData = ref.watch(rankingProvider(params));

    return asyncData.when(
      loading: () => ListView.builder(
        itemCount: 10,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ShimmerSkeleton.card(height: 56),
        ),
      ),
      error: (e, _) => ErroInline(
        mensagem: 'Não foi possível carregar o ranking',
        onRetry: () => ref.invalidate(rankingProvider(params)),
      ),
      data: (ranking) {
        if (ranking.items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Nenhum dado disponível para este filtro'),
            ),
          );
        }
        return ListView.separated(
          itemCount: ranking.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) => RankingItemWidget(
            posicao: i + 1,
            item: ranking.items[i],
            tipo: tipo,
          ),
        );
      },
    );
  }
}
