import 'dart:async';

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
  /// Texto da busca. A API ja' procura em titulo, descricao e protocolo.
  final String searchTerm;

  const DemandListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.activeStatus = 'all',
    this.statusCounts,
    this.searchTerm = '',
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
    String? searchTerm,
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
        searchTerm: searchTerm ?? this.searchTerm,
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
        search: state.searchTerm.isEmpty ? null : state.searchTerm,
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

  Timer? _debounce;

  /// Busca com atraso: evita uma requisicao por tecla digitada.
  void search(String termo) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final t = termo.trim();
      if (t == state.searchTerm) return;
      state = state.copyWith(searchTerm: t, page: 1, hasMore: true);
      fetch(reset: true);
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    if (state.searchTerm.isEmpty) return;
    state = state.copyWith(searchTerm: '', page: 1, hasMore: true);
    fetch(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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

  /// Exclusao logica: o servidor marca `deleted_at`, nao apaga.
  Future<bool> delete(String demandId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ds.deleteDemand(demandId);
      state = state.copyWith(isLoading: false, success: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Não foi possível excluir a demanda',
      );
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

// ── Anexos ──────────────────────────────────────────────────────────────────

/// Lista de anexos da demanda. Invalidar apos enviar um novo para recarregar.
final demandAttachmentsProvider =
    FutureProvider.family<List<DemandAttachment>, String>((ref, id) async {
  return ref.watch(demandDataSourceProvider).getAttachments(id);
});

class AttachmentUploadState {
  final bool isUploading;
  final String? error;
  const AttachmentUploadState({this.isUploading = false, this.error});
}

class AttachmentUploadNotifier extends StateNotifier<AttachmentUploadState> {
  final DemandRemoteDataSource _ds;
  AttachmentUploadNotifier(this._ds) : super(const AttachmentUploadState());

  /// Envia o arquivo e devolve true no sucesso. A tela decide o que mostrar.
  Future<bool> upload(String demandId, String filePath) async {
    if (state.isUploading) return false;
    state = const AttachmentUploadState(isUploading: true);
    try {
      await _ds.uploadAttachment(demandId, filePath);
      state = const AttachmentUploadState();
      return true;
    } catch (e) {
      state = AttachmentUploadState(error: _mensagem(e));
      return false;
    }
  }

  /// Traduz o erro do servidor para algo que o usuario entenda no celular.
  String _mensagem(Object e) {
    final t = e.toString();
    if (t.contains('FILE_TOO_LARGE')) return 'Arquivo maior que 10 MB';
    if (t.contains('INVALID_TYPE')) return 'Tipo de arquivo não aceito';
    if (t.contains('NOT_FOUND')) return 'Demanda não encontrada';
    return 'Não foi possível enviar o anexo';
  }
}

final attachmentUploadProvider =
    StateNotifierProvider<AttachmentUploadNotifier, AttachmentUploadState>(
        (ref) => AttachmentUploadNotifier(ref.watch(demandDataSourceProvider)));
