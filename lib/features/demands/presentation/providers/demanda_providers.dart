import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/friendly_error.dart';
import '../../../../core/providers/api_providers.dart';
import '../../data/datasources/demanda_remote_datasource.dart';
import '../../data/models/demanda_extras.dart';
import '../../data/models/demanda_model.dart';

final demandaDataSourceProvider = Provider<DemandaRemoteDataSource>((ref) {
  return DemandaRemoteDataSource(ref.watch(apiClientProvider));
});

// ── Mesa (lista paginada + contadores) ──────────────────────────────────────

class DemandaListaState {
  final List<DemandaResumo> items;
  final DemandaContadores contadores;
  final DemandaFiltros filtros;
  final int total;
  final int page;
  final bool carregando;
  final bool carregandoMais;
  final bool temMais;
  final String? erro;

  const DemandaListaState({
    this.items = const [],
    this.contadores = const DemandaContadores(),
    this.filtros = const DemandaFiltros(),
    this.total = 0,
    this.page = 1,
    this.carregando = true,
    this.carregandoMais = false,
    this.temMais = false,
    this.erro,
  });

  DemandaListaState copyWith({
    List<DemandaResumo>? items,
    DemandaContadores? contadores,
    DemandaFiltros? filtros,
    int? total,
    int? page,
    bool? carregando,
    bool? carregandoMais,
    bool? temMais,
    String? Function()? erro,
  }) => DemandaListaState(
    items: items ?? this.items,
    contadores: contadores ?? this.contadores,
    filtros: filtros ?? this.filtros,
    total: total ?? this.total,
    page: page ?? this.page,
    carregando: carregando ?? this.carregando,
    carregandoMais: carregandoMais ?? this.carregandoMais,
    temMais: temMais ?? this.temMais,
    erro: erro != null ? erro() : this.erro,
  );
}

class DemandaListaNotifier extends StateNotifier<DemandaListaState> {
  DemandaListaNotifier(this._ds) : super(const DemandaListaState()) {
    recarregar();
  }

  final DemandaRemoteDataSource _ds;
  static const _porPagina = 20;
  int _geracao = 0;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Recarrega da página 1. [silencioso] mantém a lista visível (pull-to-refresh
  /// e pós-mutação).
  Future<void> recarregar({bool silencioso = false}) async {
    final g = ++_geracao;
    if (!silencioso) {
      state = state.copyWith(carregando: true, erro: () => null);
    }
    try {
      final r = await _ds.listar(state.filtros, page: 1, limit: _porPagina);
      if (g != _geracao || !mounted) return;
      state = state.copyWith(
        items: r.items,
        contadores: r.contadores,
        total: r.total,
        page: 1,
        temMais: r.temMais,
        carregando: false,
        carregandoMais: false,
        erro: () => null,
      );
    } catch (e) {
      if (g != _geracao || !mounted) return;
      state = state.copyWith(
        carregando: false,
        erro: () => mensagemAmigavel(e),
      );
    }
  }

  Future<void> carregarMais() async {
    if (state.carregando || state.carregandoMais || !state.temMais) return;
    final g = _geracao;
    state = state.copyWith(carregandoMais: true);
    try {
      final proxima = state.page + 1;
      final r = await _ds.listar(
        state.filtros,
        page: proxima,
        limit: _porPagina,
      );
      if (g != _geracao || !mounted) return;
      state = state.copyWith(
        items: [...state.items, ...r.items],
        contadores: r.contadores,
        total: r.total,
        page: proxima,
        temMais: r.temMais,
        carregandoMais: false,
      );
    } catch (_) {
      if (g != _geracao || !mounted) return;
      state = state.copyWith(carregandoMais: false);
    }
  }

  void aplicar(DemandaFiltros f) {
    state = state.copyWith(filtros: f);
    recarregar();
  }

  void selecionarStatus(String? status) =>
      aplicar(state.filtros.copyWith(status: () => status));

  void buscar(String texto) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      aplicar(state.filtros.copyWith(busca: texto));
    });
  }
}

final demandaListaProvider =
    StateNotifierProvider<DemandaListaNotifier, DemandaListaState>((ref) {
      return DemandaListaNotifier(ref.watch(demandaDataSourceProvider));
    });

// ── Detalhe / opções / config ───────────────────────────────────────────────

final demandaDetalheProvider = FutureProvider.autoDispose
    .family<DemandaDetalhe, int>((ref, id) {
      return ref.watch(demandaDataSourceProvider).detalhe(id);
    });

final demandaOpcoesProvider = FutureProvider<DemandaOpcoes>((ref) {
  return ref.watch(demandaDataSourceProvider).opcoes();
});

final demandaConfigProvider = FutureProvider<DemandaConfig>((ref) {
  return ref.watch(demandaDataSourceProvider).config();
});

/// Demandas de um munícipe (aba do detalhe do munícipe).
final demandasDoMunicipeProvider = FutureProvider.autoDispose
    .family<DemandaListaResposta, int>((ref, eleitorId) {
      return ref
          .watch(demandaDataSourceProvider)
          .listarDoMunicipe(eleitorId, limit: 20);
    });

/// Atualiza detalhe e Mesa depois de qualquer mutação.
void demandaAtualizada(WidgetRef ref, int id) {
  ref.invalidate(demandaDetalheProvider(id));
  unawaited(
    ref.read(demandaListaProvider.notifier).recarregar(silencioso: true),
  );
}
