import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/eleitoral_remote_datasource.dart';
import '../../data/datasources/ibge_remote_datasource.dart';
import '../../data/models/candidato_model.dart';
import '../../data/models/candidato_stats_model.dart';
import '../../data/models/coligacao_detalhe_model.dart';
import '../../data/models/comparacao_model.dart';
import '../../data/models/estatisticas_model.dart';
import '../../data/models/filtros_model.dart';
import '../../data/models/partido_detalhe_model.dart';
import '../../data/models/hierarquia_nivel_model.dart';
import '../../data/models/ibge_municipio_model.dart';
import '../../data/models/municipio_eleitos_model.dart';
import '../../data/models/municipio_voto_model.dart';
import '../../data/models/ranking_model.dart';
import '../../data/models/selected_election_model.dart';
import '../../data/services/geo_service.dart';

// ─── Infraestrutura ──────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final eleitoralDatasourceProvider = Provider<EleitoralRemoteDatasource>(
  (ref) => EleitoralRemoteDatasource(ref.watch(apiClientProvider)),
);

final ibgeDatasourceProvider = Provider<IbgeRemoteDatasource>(
  (ref) => IbgeRemoteDatasource(ref.watch(apiClientProvider)),
);

// ─── Filtros (carregados da API) ─────────────────────────────────────────────

final filtrosProvider = FutureProvider<FiltrosModel>((ref) async {
  return ref.watch(eleitoralDatasourceProvider).getFiltros();
});

// ─── Eleição selecionada (persiste em Hive) ──────────────────────────────────

const _kHiveBoxElection = 'electoral_selection';
const _kHiveKeyElection = 'selected';

class SelectedElectionNotifier extends StateNotifier<SelectedElection?> {
  SelectedElectionNotifier() : super(null) {
    _load();
  }

  void _load() {
    try {
      final box = Hive.box<dynamic>(_kHiveBoxElection);
      final raw = box.get(_kHiveKeyElection) as String?;
      if (raw != null) {
        state = SelectedElection.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      }
    } catch (_) {
      state = null;
    }
  }

  Future<void> select(SelectedElection election) async {
    state = election;
    final box = Hive.box<dynamic>(_kHiveBoxElection);
    await box.put(_kHiveKeyElection, jsonEncode(election.toJson()));
  }

  Future<void> clear() async {
    state = null;
    final box = Hive.box<dynamic>(_kHiveBoxElection);
    await box.delete(_kHiveKeyElection);
  }
}

final selectedElectionProvider =
    StateNotifierProvider<SelectedElectionNotifier, SelectedElection?>(
  (_) => SelectedElectionNotifier(),
);

// ─── Estado dos filtros selecionados (busca/search inline) ───────────────────

class FiltrosSelecionados {
  final int ano;
  final String estado;
  final String cargo;
  final String search;

  const FiltrosSelecionados({
    this.ano = 2022,
    this.estado = 'BA',
    this.cargo = '',
    this.search = '',
  });

  FiltrosSelecionados copyWith({
    int? ano,
    String? estado,
    String? cargo,
    String? search,
  }) {
    return FiltrosSelecionados(
      ano: ano ?? this.ano,
      estado: estado ?? this.estado,
      cargo: cargo ?? this.cargo,
      search: search ?? this.search,
    );
  }
}

class FiltrosSelecionadosNotifier extends Notifier<FiltrosSelecionados> {
  @override
  FiltrosSelecionados build() {
    // Sincroniza com a eleição selecionada quando ela mudar
    ref.listen<SelectedElection?>(selectedElectionProvider, (_, election) {
      if (election != null) {
        state = FiltrosSelecionados(
          ano: election.ano,
          estado: election.uf,
          cargo: election.cargo,
          search: '',
        );
      }
    });
    // Inicializa a partir da eleição selecionada (se já carregou do Hive)
    final election = ref.read(selectedElectionProvider);
    if (election != null) {
      return FiltrosSelecionados(
        ano: election.ano,
        estado: election.uf,
        cargo: election.cargo,
      );
    }
    return const FiltrosSelecionados();
  }

  void setAno(int ano) => state = state.copyWith(ano: ano);
  void setEstado(String estado) => state = state.copyWith(estado: estado);
  void setCargo(String cargo) => state = state.copyWith(cargo: cargo);
  void setSearch(String search) => state = state.copyWith(search: search);
  void reset() => state = const FiltrosSelecionados();
}

final filtrosSelecionadosProvider =
    NotifierProvider<FiltrosSelecionadosNotifier, FiltrosSelecionados>(
  FiltrosSelecionadosNotifier.new,
);

/// Filtro por cidade (eleições municipais): nome parcial do município.
final cidadeFiltroProvider = StateProvider<String>((ref) => '');

// ─── Lista paginada de candidatos ────────────────────────────────────────────

class CandidatosListState {
  final List<CandidatoModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const CandidatosListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  CandidatosListState copyWith({
    List<CandidatoModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return CandidatosListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class CandidatosListNotifier extends Notifier<CandidatosListState> {
  @override
  CandidatosListState build() {
    ref.listen(filtrosSelecionadosProvider, (_, __) => refresh());
    ref.listen(cidadeFiltroProvider, (_, __) => refresh());
    return const CandidatosListState(isLoading: true);
  }

  Future<void> refresh() async {
    state = const CandidatosListState(isLoading: true);
    await _load(page: 1);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    await _load(page: state.currentPage + 1);
  }

  Future<void> _load({required int page}) async {
    try {
      final filtros = ref.read(filtrosSelecionadosProvider);
      final ds = ref.read(eleitoralDatasourceProvider);
      final result = await ds.getCandidatos(
        ano: filtros.ano,
        estado: filtros.estado,
        cargo: filtros.cargo,
        search: filtros.search,
        municipio: ref.read(cidadeFiltroProvider),
        page: page,
      );
      final newItems =
          page == 1 ? result.items : [...state.items, ...result.items];
      state = CandidatosListState(
        items: newItems,
        isLoading: false,
        isLoadingMore: false,
        hasMore: result.hasMore,
        currentPage: page,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }
}

final candidatosListProvider =
    NotifierProvider<CandidatosListNotifier, CandidatosListState>(
  CandidatosListNotifier.new,
);

// ─── Detalhe do candidato ────────────────────────────────────────────────────

final candidatoDetalheProvider =
    FutureProvider.family<CandidatoFullModel, String>((ref, sequencial) async {
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(eleitoralDatasourceProvider).getCandidatoDetalhe(
        sequencial: sequencial,
        ano: filtros.ano,
        estado: filtros.estado,
      );
});

// ─── Mapa do candidato ───────────────────────────────────────────────────────

final candidatoMapaProvider =
    FutureProvider.family<MapaMunicipiosData, String>((ref, sequencial) async {
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(eleitoralDatasourceProvider).getMapaCandidato(
        sequencial: sequencial,
        ano: filtros.ano,
        estado: filtros.estado,
      );
});

// ─── GeoFeatures (cache singleton) ───────────────────────────────────────────

final geoFeaturesProvider = FutureProvider((ref) async {
  return GeoService.instance.getFeatures();
});

// ─── Microrregião selecionada no mapa ────────────────────────────────────────
// Obs: a agregação de votos por microrregião é feita client-side no mapa
// (filtrando os municípios já carregados) — não há chamada extra ao backend.

final microrregiaoSelecionadaProvider = StateProvider<String?>((ref) => null);

// ─── Hierarquia ───────────────────────────────────────────────────────────────

class HierarquiaParams {
  final String sequencial;
  final String nivel;
  final String? paiId;

  const HierarquiaParams({
    required this.sequencial,
    required this.nivel,
    this.paiId,
  });

  @override
  bool operator ==(Object other) =>
      other is HierarquiaParams &&
      sequencial == other.sequencial &&
      nivel == other.nivel &&
      paiId == other.paiId;

  @override
  int get hashCode => Object.hash(sequencial, nivel, paiId);
}

final hierarquiaProvider = FutureProvider.autoDispose
    .family<HierarquiaNivelModel, HierarquiaParams>((ref, params) async {
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(eleitoralDatasourceProvider).getHierarquia(
        sequencial: params.sequencial,
        ano: filtros.ano,
        estado: filtros.estado,
        nivel: params.nivel,
        paiId: params.paiId,
      );
});

// ─── Comparação ──────────────────────────────────────────────────────────────

/// Family key = sequenciais separados por vírgula (String tem igualdade por
/// valor — usar List quebraria o cache do family a cada rebuild).
final comparacaoProvider =
    FutureProvider.autoDispose.family<ComparacaoModel, String>(
        (ref, sequenciaisCsv) async {
  final sequenciais =
      sequenciaisCsv.split(',').where((s) => s.isNotEmpty).toList();
  if (sequenciais.length < 2) throw Exception('Selecione 2 candidatos');
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(eleitoralDatasourceProvider).comparar(
        sequenciais: sequenciais,
        ano: filtros.ano,
        estado: filtros.estado,
      );
});

// ─── Rankings ────────────────────────────────────────────────────────────────

class RankingParams {
  final String tipo;
  final String cargo;

  const RankingParams({required this.tipo, required this.cargo});

  @override
  bool operator ==(Object other) =>
      other is RankingParams && tipo == other.tipo && cargo == other.cargo;

  @override
  int get hashCode => Object.hash(tipo, cargo);
}

final rankingProvider =
    FutureProvider.family<RankingModel, RankingParams>((ref, params) async {
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(eleitoralDatasourceProvider).getRanking(
        tipo: params.tipo,
        ano: filtros.ano,
        estado: filtros.estado,
        cargo: filtros.cargo.isEmpty ? params.cargo : filtros.cargo,
      );
});

// ─── Eleitos por município (drilldown do ranking) ──────────────────────────

final eleitosDoMunicipioProvider =
    FutureProvider.family<MunicipioEleitosModel, String>((ref, idMunicipio) async {
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(eleitoralDatasourceProvider).getEleitosDoMunicipio(
        idMunicipio: idMunicipio,
        ano: filtros.ano,
        estado: filtros.estado,
        cargo: filtros.cargo,
      );
});

// ─── IBGE ─────────────────────────────────────────────────────────────────────

final ibgeMunicipioProvider =
    FutureProvider.family<IbgeMunicipioModel, String>((ref, id) async {
  return ref.watch(ibgeDatasourceProvider).getMunicipio(id: id);
});

final ibgeMicrorregioesProvider =
    FutureProvider<List<IbgeMicrorregiao>>((ref) async {
  return ref.watch(ibgeDatasourceProvider).getMicrorregioes();
});

// ─── Candidato B para comparação (buscado por texto) ─────────────────────────

final comparacaoSearchProvider = StateProvider<String>((ref) => '');

final comparacaoCandidatoBuscaProvider =
    FutureProvider.autoDispose<CandidatosPage>((ref) async {
  final search = ref.watch(comparacaoSearchProvider);
  if (search.isEmpty) return CandidatosPage.fromJson(<String, dynamic>{'items': <dynamic>[], 'total': 0, 'page': 1, 'limit': 20, 'hasMore': false});
  final filtros = ref.read(filtrosSelecionadosProvider);
  return ref.watch(eleitoralDatasourceProvider).getCandidatos(
        ano: filtros.ano,
        estado: filtros.estado,
        cargo: filtros.cargo,
        search: search,
        limit: 10,
      );
});

// ─── Estatísticas da eleição (página Análise) ────────────────────────────────

final estatisticasProvider =
    FutureProvider.autoDispose<EstatisticasModel>((ref) async {
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(eleitoralDatasourceProvider).getEstatisticas(
        ano: filtros.ano,
        estado: filtros.estado,
        cargo: filtros.cargo,
      );
});

// ─── Detalhe de partido (drilldown dos rankings) ─────────────────────────────

final partidoDetalheProvider = FutureProvider.autoDispose
    .family<PartidoDetalheModel, String>((ref, sigla) async {
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(eleitoralDatasourceProvider).getPartidoDetalhe(
        sigla: sigla,
        ano: filtros.ano,
        estado: filtros.estado,
        cargo: filtros.cargo,
      );
});

// ─── Detalhe de coligação (drilldown dos rankings) ───────────────────────────

final coligacaoDetalheProvider = FutureProvider.autoDispose
    .family<ColigacaoDetalheModel, String>((ref, nome) async {
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(eleitoralDatasourceProvider).getColigacaoDetalhe(
        nome: nome,
        ano: filtros.ano,
        estado: filtros.estado,
        cargo: filtros.cargo,
      );
});

// ─── Showcase / onboarding flag ──────────────────────────────────────────────
// Gerenciado via SharedPreferences diretamente nas pages para simplicidade.
