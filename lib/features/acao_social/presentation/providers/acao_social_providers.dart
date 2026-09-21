import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/friendly_error.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/datasources/acao_social_remote_datasource.dart';
import '../../data/models/acao_social_models.dart';

// ── DataSource ──────────────────────────────────────────────────────────────

final acaoSocialDataSourceProvider =
    Provider<AcaoSocialRemoteDataSource>((ref) {
  return AcaoSocialRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

/// Mensagem curta para SnackBar/tela: usa a do backend quando for legivel
/// ({success:false, error:'Vagas esgotadas...'}), senao a amigavel de rede.
String mensagemErroAcaoSocial(Object e) {
  final msg = e.toString().replaceFirst('Exception: ', '');
  if (msg.length < 140 && !msg.contains('DioException')) return msg;
  return mensagemAmigavel(e);
}

// ── Eventos ─────────────────────────────────────────────────────────────────

class EventosState {
  final List<EventoAcaoSocial> items;
  final bool isLoading;
  final String? error;

  /// 'ativo' | 'finalizado' | 'todos'
  final String filtro;

  const EventosState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.filtro = 'ativo',
  });

  EventosState copyWith({
    List<EventoAcaoSocial>? items,
    bool? isLoading,
    String? error,
    String? filtro,
  }) =>
      EventosState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        filtro: filtro ?? this.filtro,
      );
}

class EventosNotifier extends StateNotifier<EventosState> {
  final AcaoSocialRemoteDataSource _ds;

  EventosNotifier(this._ds) : super(const EventosState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _ds.listarEventos(
        status: state.filtro == 'todos' ? null : state.filtro,
      );
      if (!mounted) return;
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state =
          state.copyWith(isLoading: false, error: mensagemErroAcaoSocial(e));
    }
  }

  Future<void> setFiltro(String filtro) async {
    if (filtro == state.filtro) return;
    state = state.copyWith(filtro: filtro);
    await fetch();
  }

  Future<void> refresh() => fetch();
}

/// autoDispose: a lista morre ao sair da tela e nasce de novo ao entrar.
/// Sem isso ela sobrevivia a uma troca de tenant (sair do robson, entrar no
/// samuel) e mostrava os eventos do gabinete anterior — abrir um deles dava
/// 404 "Evento nao encontrado" no tenant novo.
final eventosAcaoSocialProvider =
    StateNotifierProvider.autoDispose<EventosNotifier, EventosState>((ref) {
  return EventosNotifier(ref.watch(acaoSocialDataSourceProvider));
});

/// Detalhe do evento (traz especialidades e totais).
final eventoAcaoSocialProvider =
    FutureProvider.autoDispose.family<EventoAcaoSocial, String>((ref, id) {
  return ref.watch(acaoSocialDataSourceProvider).obterEvento(id);
});

/// Vagas por especialidade do evento (rota dedicada, sempre fresca).
final especialidadesEventoProvider = FutureProvider.autoDispose
    .family<List<EspecialidadeEvento>, String>((ref, eventoId) {
  return ref.watch(acaoSocialDataSourceProvider).listarEspecialidades(eventoId);
});

// ── Cadastrados (municipes com a tag do evento) ─────────────────────────────

class CadastradosState {
  final List<Cadastrado> items;
  final bool isLoading;
  final String? error;
  final String busca;

  /// Total de cadastrados do evento SEM filtro de busca (para o cabecalho
  /// nao "encolher" quando o usuario digita na busca). Null ate a primeira
  /// carga sem filtro.
  final int? totalGeral;

  const CadastradosState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.busca = '',
    this.totalGeral,
  });

  CadastradosState copyWith({
    List<Cadastrado>? items,
    bool? isLoading,
    String? error,
    String? busca,
    int? totalGeral,
  }) =>
      CadastradosState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        busca: busca ?? this.busca,
        totalGeral: totalGeral ?? this.totalGeral,
      );
}

class CadastradosNotifier extends StateNotifier<CadastradosState> {
  final AcaoSocialRemoteDataSource _ds;
  final String tag;
  Timer? _debounce;

  CadastradosNotifier(this._ds, this.tag) : super(const CadastradosState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _ds.listarCadastrados(tag, busca: state.busca);
      LoggerService.i(
          '[AcaoSocial] cadastrados tag=$tag busca="${state.busca}" → ${items.length} itens (mounted=$mounted)');
      if (!mounted) return;
      state = state.copyWith(
        items: items,
        isLoading: false,
        // so' a carga sem busca representa o total do evento
        totalGeral: state.busca.isEmpty ? items.length : null,
      );
    } catch (e) {
      if (!mounted) return;
      state =
          state.copyWith(isLoading: false, error: mensagemErroAcaoSocial(e));
    }
  }

  /// Busca server-side (nome ou telefone) com atraso para nao disparar uma
  /// requisicao por tecla.
  void buscar(String termo) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final t = termo.trim();
      if (t == state.busca) return;
      state = state.copyWith(busca: t);
      fetch();
    });
  }

  Future<void> refresh() => fetch();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final cadastradosProvider = StateNotifierProvider.autoDispose
    .family<CadastradosNotifier, CadastradosState, String>((ref, tag) {
  return CadastradosNotifier(ref.watch(acaoSocialDataSourceProvider), tag);
});

// ── Atendimentos ────────────────────────────────────────────────────────────

/// Todos os atendimentos do evento (a aba agrupa por paciente).
final atendimentosEventoProvider = FutureProvider.autoDispose
    .family<List<Atendimento>, String>((ref, eventoId) {
  return ref.watch(acaoSocialDataSourceProvider).listarAtendimentos(eventoId);
});

typedef PacienteKey = ({String eventoId, int eleitorId});

/// Atendimentos de UM paciente no evento (ficha).
final atendimentosPacienteProvider = FutureProvider.autoDispose
    .family<List<Atendimento>, PacienteKey>((ref, key) {
  return ref
      .watch(acaoSocialDataSourceProvider)
      .listarAtendimentos(key.eventoId, eleitorId: key.eleitorId);
});

// ── Acoes (reservar vaga, ficha, concluir, cancelar, cadastrar) ─────────────

class ResultadoReserva {
  final List<Atendimento> criados;

  /// nome da especialidade → motivo da falha (ex.: vagas esgotadas)
  final Map<String, String> falhas;

  const ResultadoReserva({required this.criados, required this.falhas});

  bool get algumSucesso => criados.isNotEmpty;
}

class AcaoSocialAcoesState {
  final bool isLoading;
  final String? error;
  const AcaoSocialAcoesState({this.isLoading = false, this.error});
}

class AcaoSocialAcoesNotifier extends StateNotifier<AcaoSocialAcoesState> {
  final Ref _ref;
  AcaoSocialAcoesNotifier(this._ref) : super(const AcaoSocialAcoesState());

  AcaoSocialRemoteDataSource get _ds => _ref.read(acaoSocialDataSourceProvider);

  static const _chaveLocal = 'acao_social_local_atendimento';

  /// Local do atendimento lembrado entre fichas (como o painel faz com
  /// localStorage) — o atendente nao redigita a cada paciente.
  String? get localLembrado => StorageService.getString(_chaveLocal);

  /// Tudo que mostra vagas/atendimentos do evento precisa recarregar.
  void _invalidarEvento(String eventoId) {
    _ref.invalidate(eventoAcaoSocialProvider(eventoId));
    _ref.invalidate(especialidadesEventoProvider(eventoId));
    _ref.invalidate(atendimentosEventoProvider(eventoId));
    // invalidate (e nao read+refresh): com autoDispose, ler o notifier sem
    // ninguem escutando criaria e descartaria uma instancia a toa.
    _ref.invalidate(eventosAcaoSocialProvider);
  }

  /// Cria um atendimento por especialidade. O servidor reserva a vaga de
  /// forma atomica e responde 409 quando esgotou — cada especialidade e'
  /// independente, entao uma falha nao cancela as outras.
  Future<ResultadoReserva> reservarVagas({
    required String eventoId,
    required int eleitorId,
    required List<EspecialidadeEvento> especialidades,
  }) async {
    state = const AcaoSocialAcoesState(isLoading: true);
    final criados = <Atendimento>[];
    final falhas = <String, String>{};
    for (final esp in especialidades) {
      try {
        criados.add(await _ds.criarAtendimento(
          eventoId: eventoId,
          especialidadeId: esp.id,
          eleitorId: eleitorId,
        ));
      } catch (e) {
        falhas[esp.nome] = mensagemErroAcaoSocial(e);
      }
    }
    _invalidarEvento(eventoId);
    _ref.invalidate(
        atendimentosPacienteProvider((eventoId: eventoId, eleitorId: eleitorId)));
    state = const AcaoSocialAcoesState();
    return ResultadoReserva(criados: criados, falhas: falhas);
  }

  /// A anamnese e' do PACIENTE, nao da especialidade: replica o mesmo payload
  /// em todos os atendimentos nao cancelados dele no evento (comportamento
  /// do painel). [concluir] tambem fecha os que estao em atendimento.
  Future<bool> salvarFicha({
    required String eventoId,
    required int eleitorId,
    required List<Atendimento> atendimentos,
    required Map<String, dynamic> ficha,
    bool concluir = false,
  }) async {
    state = const AcaoSocialAcoesState(isLoading: true);
    try {
      final local = ficha['local_atendimento'];
      if (local is String && local.trim().isNotEmpty) {
        await StorageService.saveString(_chaveLocal, local.trim());
      }
      for (final a in atendimentos.where((a) => !a.cancelado)) {
        final body = Map<String, dynamic>.from(ficha);
        if (concluir && a.emAtendimento) body['status'] = 'concluido';
        await _ds.atualizarAtendimento(a.id, body);
      }
      _invalidarEvento(eventoId);
      _ref.invalidate(atendimentosPacienteProvider(
          (eventoId: eventoId, eleitorId: eleitorId)));
      state = const AcaoSocialAcoesState();
      return true;
    } catch (e) {
      state = AcaoSocialAcoesState(error: mensagemErroAcaoSocial(e));
      return false;
    }
  }

  /// Concluir todos os atendimentos pendentes do paciente (sem mexer na ficha).
  Future<bool> concluirTodos({
    required String eventoId,
    required int eleitorId,
    required List<Atendimento> atendimentos,
  }) async {
    state = const AcaoSocialAcoesState(isLoading: true);
    try {
      for (final a in atendimentos.where((a) => a.emAtendimento)) {
        await _ds.atualizarAtendimento(a.id, {'status': 'concluido'});
      }
      _invalidarEvento(eventoId);
      _ref.invalidate(atendimentosPacienteProvider(
          (eventoId: eventoId, eleitorId: eleitorId)));
      state = const AcaoSocialAcoesState();
      return true;
    } catch (e) {
      state = AcaoSocialAcoesState(error: mensagemErroAcaoSocial(e));
      return false;
    }
  }

  /// Cancela UM atendimento (o servidor devolve a vaga).
  Future<bool> cancelarAtendimento(Atendimento a) =>
      alterarStatus(a, 'cancelado');

  /// Muda o status de UM atendimento: 'em_atendimento' (reabrir),
  /// 'concluido' ou 'cancelado' (devolve a vaga). Nao "descancela": o
  /// servidor nao reservaria a vaga de novo; para isso existe o Atender.
  Future<bool> alterarStatus(Atendimento a, String status) async {
    state = const AcaoSocialAcoesState(isLoading: true);
    try {
      await _ds.atualizarAtendimento(a.id, {'status': status});
      _invalidarEvento(a.eventoId);
      _ref.invalidate(atendimentosPacienteProvider(
          (eventoId: a.eventoId, eleitorId: a.eleitorId)));
      state = const AcaoSocialAcoesState();
      return true;
    } catch (e) {
      state = AcaoSocialAcoesState(error: mensagemErroAcaoSocial(e));
      return false;
    }
  }

  /// Baixa o PDF da ficha do paciente. Retorna null em erro (mensagem em
  /// [state.error]).
  Future<List<int>?> baixarFichaPdf(String atendimentoId) async {
    state = const AcaoSocialAcoesState(isLoading: true);
    try {
      final bytes = await _ds.baixarFichaPdf(atendimentoId);
      state = const AcaoSocialAcoesState();
      return bytes;
    } catch (e) {
      state = AcaoSocialAcoesState(error: mensagemErroAcaoSocial(e));
      return null;
    }
  }

  /// Upsert por telefone no servidor + tag do evento. Retorna null em erro
  /// (mensagem fica em [state.error]).
  Future<CadastroPresencialResult?> cadastrarMunicipe(
    EventoAcaoSocial evento,
    Map<String, dynamic> dados,
  ) async {
    state = const AcaoSocialAcoesState(isLoading: true);
    try {
      final r = await _ds.cadastroPresencial({
        'eventoId': evento.id,
        'eventoTag': evento.tag,
        'eventoNome': evento.nome,
        ...dados,
      });
      _ref.invalidate(cadastradosProvider(evento.tag));
      state = const AcaoSocialAcoesState();
      return r;
    } catch (e) {
      state = AcaoSocialAcoesState(error: mensagemErroAcaoSocial(e));
      return null;
    }
  }
}

final acaoSocialAcoesProvider =
    StateNotifierProvider<AcaoSocialAcoesNotifier, AcaoSocialAcoesState>(
        (ref) => AcaoSocialAcoesNotifier(ref));
