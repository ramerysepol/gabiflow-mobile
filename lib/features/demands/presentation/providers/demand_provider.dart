import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_providers.dart';
import '../../data/datasources/demand_remote_datasource.dart';
import '../../data/models/demand_model.dart';

// ── DataSource ──────────────────────────────────────────────────────────────

final demandDataSourceProvider = Provider<DemandRemoteDataSource>((ref) {
  return DemandRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

// ── Lista paginada com filtro por status ────────────────────────────────────

class DemandListState {
  final List<DemandModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;
  final String activeStatus; // 'all', 'pending', 'in_progress', 'completed', 'cancelled'
  final DemandStatusCounts? statusCounts;

  const DemandListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.activeStatus = 'all',
    this.statusCounts,
  });

  DemandListState copyWith({
    List<DemandModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    String? activeStatus,
    DemandStatusCounts? statusCounts,
  }) =>
      DemandListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: error,
        activeStatus: activeStatus ?? this.activeStatus,
        statusCounts: statusCounts ?? this.statusCounts,
      );
}

class DemandListNotifier extends StateNotifier<DemandListState> {
  final DemandRemoteDataSource _ds;

  DemandListNotifier(this._ds) : super(const DemandListState()) {
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
      final result = await _ds.getDemands(
        page: nextPage,
        status: state.activeStatus == 'all' ? null : state.activeStatus,
      );

      final newItems =
          reset ? result.items : [...state.items, ...result.items];
      state = state.copyWith(
        items: newItems,
        isLoading: false,
        isLoadingMore: false,
        hasMore: result.hasMore,
        page: nextPage + 1,
        statusCounts: result.statusCounts,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> filterByStatus(String status) async {
    if (state.activeStatus == status) return;
    state = state.copyWith(activeStatus: status, page: 1, hasMore: true);
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

final demandListProvider =
    StateNotifierProvider<DemandListNotifier, DemandListState>((ref) {
  return DemandListNotifier(ref.watch(demandDataSourceProvider));
});

// ── Detalhe ─────────────────────────────────────────────────────────────────

final demandDetailProvider =
    FutureProvider.family<DemandModel, String>((ref, id) async {
  return ref.watch(demandDataSourceProvider).getDemandById(id);
});

// ── Formulário ───────────────────────────────────────────────────────────────

class DemandFormState {
  final bool isLoading;
  final String? error;
  final bool success;

  const DemandFormState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  DemandFormState copyWith({bool? isLoading, String? error, bool? success}) =>
      DemandFormState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        success: success ?? this.success,
      );
}

class DemandFormNotifier extends StateNotifier<DemandFormState> {
  final DemandRemoteDataSource _ds;

  DemandFormNotifier(this._ds) : super(const DemandFormState());

  Future<DemandModel?> save(
      Map<String, dynamic> body, String? existingId) async {
    state = const DemandFormState(isLoading: true);
    try {
      final result = existingId != null
          ? await _ds.updateDemand(existingId, body)
          : await _ds.createDemand(body);
      state = const DemandFormState(success: true);
      return result;
    } catch (e) {
      state = DemandFormState(error: e.toString());
      return null;
    }
  }

  Future<bool> addNote(String demandId, String content) async {
    state = const DemandFormState(isLoading: true);
    try {
      await _ds.addNote(demandId, content);
      state = const DemandFormState(success: true);
      return true;
    } catch (e) {
      state = DemandFormState(error: e.toString());
      return false;
    }
  }

  Future<bool> updateStatus(String demandId, String newStatus) async {
    state = const DemandFormState(isLoading: true);
    try {
      await _ds.updateDemand(demandId, {'status': newStatus});
      state = const DemandFormState(success: true);
      return true;
    } catch (e) {
      state = DemandFormState(error: e.toString());
      return false;
    }
  }
}

final demandFormProvider =
    StateNotifierProvider.autoDispose<DemandFormNotifier, DemandFormState>(
        (ref) {
  return DemandFormNotifier(ref.watch(demandDataSourceProvider));
});
