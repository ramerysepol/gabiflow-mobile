import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissoes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/demanda_extras.dart';
import '../../data/models/demanda_model.dart';
import '../../data/models/demanda_vocab.dart';
import '../providers/demanda_providers.dart';
import '../widgets/demanda_card.dart';
import '../widgets/demanda_faixa_hoje.dart';
import '../widgets/demanda_filtros_sheet.dart';

/// Mesa de Demandas 2.0: faixa Hoje, abas por status, busca e lista paginada.
class DemandasMesaPage extends ConsumerStatefulWidget {
  const DemandasMesaPage({super.key});

  @override
  ConsumerState<DemandasMesaPage> createState() => _DemandasMesaPageState();
}

class _DemandasMesaPageState extends ConsumerState<DemandasMesaPage>
    with SingleTickerProviderStateMixin {
  // null = "Todas".
  static const List<String?> _abas = [null, ...DemandaVocab.statusLista];

  late final TabController _tabs = TabController(
    length: _abas.length,
    vsync: this,
  );
  final _rolagem = ScrollController();
  final _busca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rolagem.addListener(() {
      if (_rolagem.position.pixels >= _rolagem.position.maxScrollExtent - 240) {
        ref.read(demandaListaProvider.notifier).carregarMais();
      }
    });
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      final status = _abas[_tabs.index];
      final atual = ref.read(demandaListaProvider).filtros.status;
      if (status != atual) {
        ref.read(demandaListaProvider.notifier).selecionarStatus(status);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _rolagem.dispose();
    _busca.dispose();
    super.dispose();
  }

  Future<void> _abrirFiltros(DemandaFiltros atual) async {
    final novo = await mostrarFiltrosDemanda(context, atual);
    if (novo != null && mounted) {
      ref.read(demandaListaProvider.notifier).aplicar(novo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(demandaListaProvider);
    final notifier = ref.read(demandaListaProvider.notifier);

    // Faixa "Hoje" pode trocar a aba (ex.: Aguardando retorno).
    ref.listen<String?>(demandaListaProvider.select((s) => s.filtros.status), (
      _,
      status,
    ) {
      final i = _abas.indexOf(status);
      if (i >= 0 && i != _tabs.index) _tabs.animateTo(i);
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _barraBusca(state, notifier),
            DemandaFaixaHoje(
              contadores: state.contadores,
              filtros: state.filtros,
              onAplicar: notifier.aplicar,
            ),
            const SizedBox(height: 4),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [for (final s in _abas) _aba(s, state.contadores)],
            ),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => notifier.recarregar(silencioso: true),
                child: _corpo(state),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SePodeVer(
        permissao: Permissoes.demandasCriar,
        child: FloatingActionButton.extended(
          heroTag: 'fab_demandas',
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/home/demands/new');
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova demanda'),
        ),
      ),
    );
  }

  Widget _barraBusca(DemandaListaState state, DemandaListaNotifier n) {
    final ativos = state.filtros.ativos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _busca,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar por título, protocolo ou munícipe',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                suffixIcon: state.filtros.busca.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          _busca.clear();
                          n.aplicar(state.filtros.copyWith(busca: ''));
                          FocusScope.of(context).unfocus();
                        },
                      ),
              ),
              onChanged: n.buscar,
            ),
          ),
          IconButton(
            tooltip: 'Filtros',
            onPressed: () => _abrirFiltros(state.filtros),
            icon: Badge(
              isLabelVisible: ativos > 0,
              label: Text('$ativos'),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Tab _aba(String? status, DemandaContadores c) {
    final n = status == null
        ? c.porStatus.values.fold<int>(0, (a, b) => a + b)
        : c.status(status);
    final rotulo = status == null ? 'Todas' : DemandaVocab.status(status);
    return Tab(text: n > 0 ? '$rotulo ($n)' : rotulo);
  }

  Widget _corpo(DemandaListaState state) {
    if (state.carregando && state.items.isEmpty) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => ShimmerSkeleton.card(height: 96),
      );
    }
    if (state.erro != null && state.items.isEmpty) {
      return _Rolavel(
        child: AppEmptyState(
          title: 'Não foi possível carregar',
          subtitle: state.erro!,
          actionLabel: 'Tentar de novo',
          onAction: () => ref.read(demandaListaProvider.notifier).recarregar(),
        ),
      );
    }
    if (state.items.isEmpty) {
      final filtrando =
          state.filtros.ativos > 0 ||
          state.filtros.busca.isNotEmpty ||
          state.filtros.status != null;
      return _Rolavel(
        child: AppEmptyState(
          title: filtrando ? 'Nenhuma demanda encontrada' : 'Mesa vazia',
          subtitle: filtrando
              ? 'Ajuste a busca, a aba ou os filtros.'
              : 'Registre a primeira demanda tocando em "Nova demanda".',
          actionLabel: filtrando ? null : 'Nova demanda',
          onAction: filtrando ? null : () => context.push('/home/demands/new'),
        ),
      );
    }
    return ListView.separated(
      controller: _rolagem,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        96,
      ),
      itemCount: state.items.length + (state.carregandoMais ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        if (i == state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final d = state.items[i];
        return DemandaCard(
          demanda: d,
          onTap: () => context.push('/home/demands/${d.id}'),
        );
      },
    );
  }
}

/// Permite pull-to-refresh sobre estados vazios/erro.
class _Rolavel extends StatelessWidget {
  const _Rolavel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, c) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(height: c.maxHeight, child: child),
    ),
  );
}
