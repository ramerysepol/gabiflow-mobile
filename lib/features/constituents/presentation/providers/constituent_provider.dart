import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_providers.dart';
import '../../../demands/data/models/demand_model.dart';
import '../../../demands/presentation/providers/demand_provider.dart';
import '../../data/datasources/constituent_remote_datasource.dart';
import '../../data/models/constituent_extras.dart';
import '../../data/models/constituent_model.dart';

/// Converte exceções técnicas em mensagens amigáveis (nunca vazar stacktrace).
String _mensagemAmigavel(Object e) {
  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Tempo de conexão esgotado. Verifique sua internet.';
      case DioExceptionType.connectionError:
        return 'Sem conexão com o servidor. Verifique sua internet.';
      default:
        break;
    }
  }
  final msg = e.toString().replaceFirst('Exception: ', '');
  // Mensagens vindas do backend ({success:false, error}) já são amigáveis
  if (msg.length < 120 && !msg.contains('DioException')) return msg;
  return 'Algo deu errado. Tente novamente.';
}

// ── DataSource provider ─────────────────────────────────────────────────────

final constituentDataSourceProvider =
    Provider<ConstituentRemoteDataSource>((ref) {
  return ConstituentRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

// ── Lista paginada ──────────────────────────────────────────────────────────

class ConstituentListState {
  final List<ConstituentModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;
  final String searchQuery;
  final ConstituentFilters filters;

  const ConstituentListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.searchQuery = '',
    this.filters = ConstituentFilters.vazios,
  });

  ConstituentListState copyWith({
    List<ConstituentModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    String? searchQuery,
    ConstituentFilters? filters,
  }) =>
      ConstituentListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: error ?? this.error,
        searchQuery: searchQuery ?? this.searchQuery,
        filters: filters ?? this.filters,
      );
}

class ConstituentListNotifier extends StateNotifier<ConstituentListState> {
  final ConstituentRemoteDataSource _ds;

  ConstituentListNotifier(this._ds) : super(const ConstituentListState()) {
    fetch();
  }

  Future<void> fetch({bool reset = false}) async {
    if (state.isLoading || state.isLoadingMore) return;

    final nextPage = reset ? 1 : state.page;
    final loading = nextPage == 1;

    state = state.copyWith(
      isLoading: loading,
      isLoadingMore: !loading,
      error: null,
    );

    try {
      final result = await _ds.getConstituents(
        page: nextPage,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        filters: state.filters,
      );

      final newItems =
          reset ? result.items : [...state.items, ...result.items];
      state = state.copyWith(
        items: newItems,
        isLoading: false,
        isLoadingMore: false,
        hasMore: result.hasMore,
        page: nextPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: _mensagemAmigavel(e),
      );
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, page: 1);
    await fetch(reset: true);
  }

  Future<void> aplicarFiltros(ConstituentFilters filters) async {
    state = state.copyWith(filters: filters, page: 1, hasMore: true);
    await fetch(reset: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(page: 1, hasMore: true);
    await fetch(reset: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    await fetch();
  }
}

final constituentListProvider =
    StateNotifierProvider<ConstituentListNotifier, ConstituentListState>((ref) {
  return ConstituentListNotifier(ref.watch(constituentDataSourceProvider));
});

// ── Detalhe por ID ──────────────────────────────────────────────────────────

final constituentDetailProvider =
    FutureProvider.family<ConstituentModel, String>((ref, id) async {
  final ds = ref.watch(constituentDataSourceProvider);
  return ds.getConstituentById(id);
});

// ── Facetas dos filtros (tags/cidades/aniversariantes) ──────────────────────

final constituentFacetsProvider =
    FutureProvider.autoDispose<ConstituentFacets>((ref) async {
  final ds = ref.watch(constituentDataSourceProvider);
  return ds.getFacets();
});

// ── Interações do munícipe ──────────────────────────────────────────────────

final constituentInteracoesProvider = FutureProvider.autoDispose
    .family<List<InteracaoModel>, String>((ref, constituentId) async {
  final ds = ref.watch(constituentDataSourceProvider);
  return ds.getInteracoes(constituentId);
});

// ── Demandas do munícipe (usa o datasource de demandas) ─────────────────────

final constituentDemandsProvider = FutureProvider.autoDispose
    .family<DemandListResponse, String>((ref, constituentId) async {
  final ds = ref.watch(demandDataSourceProvider);
  return ds.getDemands(constituentId: constituentId, limit: 20);
});

// ── Formulário (criar/editar) ───────────────────────────────────────────────

class ConstituentFormState {
  final bool isLoading;
  final String? error;
  final bool success;

  const ConstituentFormState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  ConstituentFormState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) =>
      ConstituentFormState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        success: success ?? this.success,
      );
}

class ConstituentFormNotifier extends StateNotifier<ConstituentFormState> {
  final ConstituentRemoteDataSource _ds;

  ConstituentFormNotifier(this._ds) : super(const ConstituentFormState());

  Future<ConstituentModel?> save(
      Map<String, dynamic> body, String? existingId) async {
    state = const ConstituentFormState(isLoading: true);
    try {
      final result = existingId != null
          ? await _ds.updateConstituent(existingId, body)
          : await _ds.createConstituent(body);
      state = const ConstituentFormState(success: true);
      return result;
    } catch (e) {
      state = ConstituentFormState(error: _mensagemAmigavel(e));
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = const ConstituentFormState(isLoading: true);
    try {
      await _ds.deleteConstituent(id);
      state = const ConstituentFormState(success: true);
      return true;
    } catch (e) {
      state = ConstituentFormState(error: _mensagemAmigavel(e));
      return false;
    }
  }
}

final constituentFormProvider =
    StateNotifierProvider.autoDispose<ConstituentFormNotifier,
        ConstituentFormState>((ref) {
  return ConstituentFormNotifier(ref.watch(constituentDataSourceProvider));
});
