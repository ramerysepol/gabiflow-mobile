import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/friendly_error.dart';
import '../../../electoral_data/presentation/providers/eleitoral_providers.dart';
import '../../data/datasources/transferencia_remote_datasource.dart';
import '../../data/models/transferencia_models.dart';
import 'command_center_providers.dart';

const maxApoiadores = 10;

final transferenciaDatasourceProvider = Provider<TransferenciaRemoteDatasource>(
  (ref) => TransferenciaRemoteDatasource(ref.watch(apiClientProvider)),
);

class TransferenciaState {
  const TransferenciaState({
    this.municipio = '',
    this.termo = '',
    this.resultados = const [],
    this.buscou = false,
    this.buscando = false,
    this.selecionados = const [],
    this.sugestoes,
    this.sugerindo = false,
    this.erro,
  });

  final String municipio;
  final String termo;
  final List<ApoiadorModel> resultados;
  final bool buscou;
  final bool buscando;
  final List<ApoiadorModel> selecionados;
  final List<SugestaoApoiadorModel>? sugestoes;
  final bool sugerindo;
  final String? erro;

  TransferenciaState copyWith({
    String? municipio,
    String? termo,
    List<ApoiadorModel>? resultados,
    bool? buscou,
    bool? buscando,
    List<ApoiadorModel>? selecionados,
    List<SugestaoApoiadorModel>? sugestoes,
    bool limparSugestoes = false,
    bool? sugerindo,
    String? erro,
    bool limparErro = false,
  }) =>
      TransferenciaState(
        municipio: municipio ?? this.municipio,
        termo: termo ?? this.termo,
        resultados: resultados ?? this.resultados,
        buscou: buscou ?? this.buscou,
        buscando: buscando ?? this.buscando,
        selecionados: selecionados ?? this.selecionados,
        sugestoes: limparSugestoes ? null : (sugestoes ?? this.sugestoes),
        sugerindo: sugerindo ?? this.sugerindo,
        erro: limparErro ? null : (erro ?? this.erro),
      );
}

class TransferenciaNotifier extends AutoDisposeNotifier<TransferenciaState> {
  Timer? _debounce;
  int _buscaId = 0;

  @override
  TransferenciaState build() {
    ref.onDispose(() => _debounce?.cancel());
    // Troca de candidato zera tudo (igual à web).
    ref.listen(iaContextoProvider, (prev, next) {
      if (prev?.sequencial != next?.sequencial) {
        _debounce?.cancel();
        state = const TransferenciaState();
      }
    });
    return const TransferenciaState();
  }

  int get anoApoio => ref.read(filtrosSelecionadosProvider).ano - 2;

  _Ctx? get _ctx {
    final c = ref.read(iaContextoProvider);
    if (c == null) return null;
    final f = ref.read(filtrosSelecionadosProvider);
    return _Ctx(c.sequencial, f.ano, f.estado);
  }

  /// Município alterado: zera seleção, sugestões e busca.
  void setMunicipio(String v) {
    _debounce?.cancel();
    state = TransferenciaState(municipio: v);
  }

  void setTermo(String v) {
    state = state.copyWith(termo: v, limparErro: true);
    _debounce?.cancel();
    if (v.trim().length < 2) {
      state = state.copyWith(resultados: const [], buscou: false, buscando: false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _buscar);
  }

  Future<void> _buscar() async {
    final ctx = _ctx;
    if (ctx == null) return;
    final id = ++_buscaId;
    state = state.copyWith(buscando: true);
    try {
      final r = await ref.read(transferenciaDatasourceProvider).buscarApoiadores(
            sequencial: ctx.sequencial,
            ano: ctx.ano,
            uf: ctx.uf,
            anoApoio: ctx.ano - 2,
            termo: state.termo.trim(),
            municipio: state.municipio,
          );
      if (id != _buscaId) return;
      state = state.copyWith(resultados: r, buscou: true, buscando: false);
    } catch (e) {
      if (id != _buscaId) return;
      state = state.copyWith(
          resultados: const [],
          buscando: false,
          buscou: false,
          erro: mensagemAmigavel(e));
    }
  }

  void adicionar(ApoiadorModel a) {
    final l = state.selecionados;
    if (l.length >= maxApoiadores || l.any((x) => x.sequencial == a.sequencial)) {
      return;
    }
    state = state.copyWith(
      selecionados: [...l, a],
      termo: '',
      resultados: const [],
      buscou: false,
    );
  }

  void remover(String sequencial) {
    state = state.copyWith(
      selecionados:
          state.selecionados.where((x) => x.sequencial != sequencial).toList(),
    );
  }

  Future<void> sugerir() async {
    final ctx = _ctx;
    if (ctx == null) return;
    state = state.copyWith(sugerindo: true, limparErro: true);
    try {
      final r = await ref.read(transferenciaDatasourceProvider).sugerir(
            sequencial: ctx.sequencial,
            ano: ctx.ano,
            uf: ctx.uf,
            anoApoio: ctx.ano - 2,
            municipio: state.municipio,
          );
      state = state.copyWith(sugestoes: r, sugerindo: false);
    } catch (e) {
      state = state.copyWith(
          sugestoes: const [], sugerindo: false, erro: mensagemAmigavel(e));
    }
  }

  /// Aplica todas as sugestões como seleção (até o máximo).
  void aplicarSugestoes() {
    final s = state.sugestoes;
    if (s == null) return;
    final l = [...state.selecionados];
    for (final x in s) {
      if (l.length >= maxApoiadores) break;
      if (!l.any((y) => y.sequencial == x.apoiador.sequencial)) {
        l.add(x.apoiador);
      }
    }
    state = state.copyWith(selecionados: l);
  }

  void setErro(String? e) =>
      state = e == null ? state.copyWith(limparErro: true) : state.copyWith(erro: e);
}

class _Ctx {
  const _Ctx(this.sequencial, this.ano, this.uf);
  final String sequencial;
  final int ano;
  final String uf;
}

final transferenciaProvider =
    NotifierProvider.autoDispose<TransferenciaNotifier, TransferenciaState>(
  TransferenciaNotifier.new,
);
