import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/apuracao_remote_datasource.dart';
import '../../data/models/apuracao_busca_model.dart';
import '../../data/models/apuracao_candidato_model.dart';
import '../../data/models/apuracao_evento_model.dart';
import '../../data/models/apuracao_municipio_model.dart';
import '../../data/models/apuracao_ranking_model.dart';
import '../../data/models/apuracao_resumo_model.dart';
import '../../data/models/apuracao_seguir_model.dart';
import '../../data/models/apuracao_status_model.dart';
import '../../data/models/apuracao_territorio_model.dart';

// ─── Infraestrutura ──────────────────────────────────────────────────────────

final apuracaoDatasourceProvider = Provider<ApuracaoRemoteDatasource>(
  (ref) => ApuracaoRemoteDatasource(ref.watch(apiClientProvider)),
);

// ─── Status geral da apuração ────────────────────────────────────────────────

final apuracaoStatusProvider = FutureProvider<ApuracaoStatusModel>((ref) async {
  return ref.watch(apuracaoDatasourceProvider).getStatus();
});

// ─── Candidatos acompanhados pelo gabinete ───────────────────────────────────

class ApuracaoSeguidosNotifier extends AsyncNotifier<ApuracaoSeguirModel> {
  ApuracaoRemoteDatasource get _ds => ref.read(apuracaoDatasourceProvider);

  @override
  Future<ApuracaoSeguirModel> build() => _ds.getSeguir();

  /// Recarrega sem piscar a tela de loading quando [silencioso] (poll de
  /// 30s / retomada do app) — mantém os dados atuais visíveis até o novo
  /// resultado chegar.
  Future<void> recarregar({bool silencioso = false}) async {
    if (!silencioso) {
      state = const AsyncValue<ApuracaoSeguirModel>.loading().copyWithPrevious(
        state,
      );
    }
    try {
      final novo = await _ds.getSeguir();
      state = AsyncValue.data(novo);
    } catch (e, st) {
      state = AsyncValue<ApuracaoSeguirModel>.error(
        e,
        st,
      ).copyWithPrevious(state);
    }
  }

  Future<void> seguir(String sqcand, {bool principal = false}) async {
    final atual = await _ds.seguir(sqcand: sqcand, principal: principal);
    state = AsyncValue.data(atual);
  }

  Future<void> deixarDeSeguir(String sqcand) async {
    final atual = await _ds.deixarDeSeguir(sqcand);
    state = AsyncValue.data(atual);
  }

  /// Define o candidato como "meu candidato" (principal do gabinete).
  Future<void> tornarPrincipal(String sqcand) =>
      seguir(sqcand, principal: true);
}

final apuracaoSeguidosProvider =
    AsyncNotifierProvider<ApuracaoSeguidosNotifier, ApuracaoSeguirModel>(
      ApuracaoSeguidosNotifier.new,
    );

// ─── Ranking de votação por cargo/UF/município ───────────────────────────────

class ApuracaoRankingParams {
  final int cargo;
  final String? uf;
  final String? municipio;
  final String q;
  final int limit;

  /// Filtro de situação: '' (todos) | 'eleito' | 'suplente' | 'nao_eleito'.
  final String projecao;

  const ApuracaoRankingParams({
    required this.cargo,
    this.uf,
    this.municipio,
    this.q = '',
    this.limit = 50,
    this.projecao = '',
  });

  ApuracaoRankingParams copyWith({
    int? cargo,
    String? uf,
    String? municipio,
    bool limparMunicipio = false,
    String? q,
    int? limit,
    String? projecao,
  }) {
    return ApuracaoRankingParams(
      cargo: cargo ?? this.cargo,
      uf: uf ?? this.uf,
      municipio: limparMunicipio ? null : (municipio ?? this.municipio),
      q: q ?? this.q,
      limit: limit ?? this.limit,
      projecao: projecao ?? this.projecao,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ApuracaoRankingParams &&
      cargo == other.cargo &&
      uf == other.uf &&
      municipio == other.municipio &&
      q == other.q &&
      limit == other.limit &&
      projecao == other.projecao;

  @override
  int get hashCode => Object.hash(cargo, uf, municipio, q, limit, projecao);
}

final apuracaoRankingProvider = FutureProvider.autoDispose
    .family<ApuracaoRankingModel, ApuracaoRankingParams>((ref, params) async {
      return ref
          .watch(apuracaoDatasourceProvider)
          .getRanking(
            cargo: params.cargo,
            uf: params.cargo == 1 ? null : params.uf,
            limit: params.limit,
            q: params.q,
            municipio: params.municipio,
            projecao: params.projecao,
          );
    });

// ─── Resumo / vagas por partido ──────────────────────────────────────────────

class ApuracaoResumoParams {
  final int cargo;
  final String? uf;
  final String? municipio;

  const ApuracaoResumoParams({required this.cargo, this.uf, this.municipio});

  @override
  bool operator ==(Object other) =>
      other is ApuracaoResumoParams &&
      cargo == other.cargo &&
      uf == other.uf &&
      municipio == other.municipio;

  @override
  int get hashCode => Object.hash(cargo, uf, municipio);
}

final apuracaoResumoProvider = FutureProvider.autoDispose
    .family<ApuracaoResumoDetalheModel, ApuracaoResumoParams>((
      ref,
      params,
    ) async {
      return ref
          .watch(apuracaoDatasourceProvider)
          .getResumo(
            cargo: params.cargo,
            uf: params.cargo == 1 ? null : params.uf,
            municipio: params.municipio,
          );
    });

// ─── Ficha do candidato ───────────────────────────────────────────────────────

final apuracaoCandidatoProvider = FutureProvider.autoDispose
    .family<ApuracaoCandidatoModel, String>((ref, sqcand) async {
      return ref.watch(apuracaoDatasourceProvider).getCandidato(sqcand);
    });

// ─── "Onde está o voto que falta" (projeção final + comparativo 2022) ───────

/// Mais pesado que o resto da ficha do candidato — quem chama o poll de
/// 30s da tela decide se invalida a cada tick ou só a cada dois (60s).
final apuracaoTerritorioProvider = FutureProvider.autoDispose
    .family<ApuracaoTerritorioModel, String>((ref, sqcand) async {
      return ref.watch(apuracaoDatasourceProvider).getTerritorio(sqcand);
    });

// ─── Busca de candidato (chooser + busca livre) ──────────────────────────────

class ApuracaoBuscaParams {
  final String q;
  final String? uf;
  final int? cargo;
  final int limit;

  const ApuracaoBuscaParams({
    required this.q,
    this.uf,
    this.cargo,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      other is ApuracaoBuscaParams &&
      q == other.q &&
      uf == other.uf &&
      cargo == other.cargo &&
      limit == other.limit;

  @override
  int get hashCode => Object.hash(q, uf, cargo, limit);
}

final apuracaoBuscaProvider = FutureProvider.autoDispose
    .family<ApuracaoBuscaModel, ApuracaoBuscaParams>((ref, params) async {
      if (params.q.trim().isEmpty) return const ApuracaoBuscaModel();
      return ref
          .watch(apuracaoDatasourceProvider)
          .busca(
            q: params.q,
            uf: params.uf,
            cargo: params.cargo,
            limit: params.limit,
          );
    });

// ─── Municípios de uma UF/cargo (seletor de filtro) ──────────────────────────

class ApuracaoMunicipioParams {
  final String? uf;
  final int? cargo;

  const ApuracaoMunicipioParams({this.uf, this.cargo});

  @override
  bool operator ==(Object other) =>
      other is ApuracaoMunicipioParams &&
      uf == other.uf &&
      cargo == other.cargo;

  @override
  int get hashCode => Object.hash(uf, cargo);
}

final apuracaoMunicipiosProvider = FutureProvider.autoDispose
    .family<ApuracaoMunicipiosModel, ApuracaoMunicipioParams>((
      ref,
      params,
    ) async {
      return ref
          .watch(apuracaoDatasourceProvider)
          .getMunicipios(uf: params.uf, cargo: params.cargo);
    });

// ─── Feed "Acontecendo agora" (eventos/alertas) ──────────────────────────────

/// Mantém a lista de eventos mesclada e sem duplicados por [ApuracaoEvento.id],
/// sempre do mais novo para o mais antigo. A carga inicial não envia `desde`;
/// [atualizar] (chamado pelo poll de 30s da [ApuracaoPage]) busca só os
/// eventos novos a partir do mais recente já visto e funde no estado atual.
class ApuracaoEventosNotifier extends AsyncNotifier<List<ApuracaoEvento>> {
  ApuracaoRemoteDatasource get _ds => ref.read(apuracaoDatasourceProvider);

  @override
  Future<List<ApuracaoEvento>> build() async {
    final resp = await _ds.getEventos();
    return _ordenados(resp.itens);
  }

  List<ApuracaoEvento> _ordenados(Iterable<ApuracaoEvento> itens) =>
      itens.toList()..sort((a, b) => b.em.compareTo(a.em));

  /// Busca eventos novos desde o último recebido e funde com a lista atual
  /// (best-effort: uma falha aqui não deve acender erro na tela principal,
  /// que já tem seus próprios providers de status/ranking/resumo).
  Future<void> atualizar() async {
    final atuais = state.valueOrNull ?? const <ApuracaoEvento>[];
    final desde = atuais.isEmpty ? null : atuais.first.em;
    try {
      final resp = await _ds.getEventos(desde: desde);
      if (resp.itens.isEmpty) return;
      final mapa = {for (final e in atuais) e.id: e};
      for (final e in resp.itens) {
        mapa[e.id] = e;
      }
      state = AsyncValue.data(_ordenados(mapa.values));
    } catch (_) {
      // Silencioso de propósito — ver comentário acima.
    }
  }
}

final apuracaoEventosProvider =
    AsyncNotifierProvider<ApuracaoEventosNotifier, List<ApuracaoEvento>>(
      ApuracaoEventosNotifier.new,
    );
