import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../electoral_data/presentation/providers/eleitoral_providers.dart';
import '../../data/datasources/ia_remote_datasource.dart';
import '../../data/models/ia_chat_models.dart';
import '../../data/models/ia_contexto_model.dart';
import '../../data/models/ia_models.dart';

// ─── Infraestrutura ──────────────────────────────────────────────────────────

final iaDatasourceProvider = Provider<IaRemoteDatasource>(
  (ref) => IaRemoteDatasource(ref.watch(apiClientProvider)),
);

// ─── Contexto (candidato em análise, persiste em Hive) ───────────────────────

const _kHiveBoxIa = 'command_center';
const _kHiveKeyContexto = 'contexto';

class IaContextoNotifier extends StateNotifier<IaContexto?> {
  IaContextoNotifier() : super(null) {
    _load();
  }

  void _load() {
    try {
      final box = Hive.box<dynamic>(_kHiveBoxIa);
      final raw = box.get(_kHiveKeyContexto) as String?;
      if (raw != null) {
        state = IaContexto.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      }
    } catch (_) {
      state = null;
    }
  }

  Future<void> select(IaContexto contexto) async {
    state = contexto;
    final box = Hive.box<dynamic>(_kHiveBoxIa);
    await box.put(_kHiveKeyContexto, jsonEncode(contexto.toJson()));
  }

  Future<void> clear() async {
    state = null;
    final box = Hive.box<dynamic>(_kHiveBoxIa);
    await box.delete(_kHiveKeyContexto);
  }
}

final iaContextoProvider =
    StateNotifierProvider<IaContextoNotifier, IaContexto?>(
  (_) => IaContextoNotifier(),
);

// ─── Cards do hub (insight, alertas, briefing, radar) ────────────────────────

final iaInsightProvider = FutureProvider.autoDispose<IaInsightModel>((ref) async {
  final contexto = ref.watch(iaContextoProvider);
  if (contexto == null) throw Exception('Selecione um candidato');
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(iaDatasourceProvider).getInsightDia(
        sequencial: contexto.sequencial,
        ano: filtros.ano,
      );
});

final iaAlertasProvider =
    FutureProvider.autoDispose<List<IaAlertaModel>>((ref) async {
  final contexto = ref.watch(iaContextoProvider);
  if (contexto == null) throw Exception('Selecione um candidato');
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(iaDatasourceProvider).getAlertas(
        sequencial: contexto.sequencial,
        ano: filtros.ano,
      );
});

final iaBriefingProvider =
    FutureProvider.autoDispose<IaBriefingModel>((ref) async {
  final contexto = ref.watch(iaContextoProvider);
  if (contexto == null) throw Exception('Selecione um candidato');
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(iaDatasourceProvider).getBriefing(
        sequencial: contexto.sequencial,
        ano: filtros.ano,
        uf: filtros.estado,
      );
});

final iaRadarProvider = FutureProvider.autoDispose<IaRadarModel>((ref) async {
  final contexto = ref.watch(iaContextoProvider);
  if (contexto == null) throw Exception('Selecione um candidato');
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(iaDatasourceProvider).getRadarTerritorial(
        sequencial: contexto.sequencial,
        ano: filtros.ano,
      );
});

// ─── Chat streaming ──────────────────────────────────────────────────────────

class IaChatState {
  final List<IaChatMessage> messages;
  final bool isStreaming;

  const IaChatState({this.messages = const [], this.isStreaming = false});

  IaChatState copyWith({List<IaChatMessage>? messages, bool? isStreaming}) {
    return IaChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class IaChatNotifier extends StateNotifier<IaChatState> {
  IaChatNotifier(this._ref) : super(const IaChatState());

  final Ref _ref;
  CancelToken? _cancelToken;
  StreamSubscription<IaChatEvent>? _subscription;

  /// Envia uma pergunta e consome o stream de eventos SSE.
  Future<void> send(String pergunta) async {
    if (state.isStreaming || pergunta.trim().isEmpty) return;

    final contexto = _ref.read(iaContextoProvider);
    if (contexto == null) return;
    final filtros = _ref.read(filtrosSelecionadosProvider);

    // Histórico: apenas turnos concluídos com texto (max 10 — o backend corta)
    final historico = state.messages
        .where((m) => !m.isStreaming && m.error == null && m.text.isNotEmpty)
        .map((m) => {'role': m.role, 'content': m.text})
        .toList();

    state = state.copyWith(
      messages: [
        ...state.messages,
        IaChatMessage(role: 'user', text: pergunta.trim()),
        const IaChatMessage(
          role: 'assistant',
          isStreaming: true,
          thinkingLabel: 'Analisando pergunta...',
        ),
      ],
      isStreaming: true,
    );

    _cancelToken = CancelToken();
    final stream = _ref.read(iaDatasourceProvider).chatStream(
          pergunta: pergunta.trim(),
          contexto: {
            'sequencial': contexto.sequencial,
            'ano': filtros.ano.toString(),
            'uf': filtros.estado,
            'cargo': contexto.cargo,
            'nome_candidato': contexto.nomeCandidato,
            'partido': contexto.siglaPartido,
          },
          historico: historico,
          cancelToken: _cancelToken,
        );

    _subscription = stream.listen(
      _onEvent,
      onError: (Object e) => _finish(error: _friendlyError(e)),
      onDone: () => _finish(),
      cancelOnError: true,
    );
  }

  void _onEvent(IaChatEvent event) {
    final current = state.messages.last;
    switch (event.type) {
      case 'thinking':
        _updateLast(current.copyWith(thinkingLabel: event.message));
      case 'tool_use':
        _updateLast(current.copyWith(
          tools: [
            ...current.tools,
            IaToolActivity(toolUseId: event.toolUseId, tool: event.tool),
          ],
          clearThinking: true,
        ));
      case 'tool_result':
        _updateLast(current.copyWith(
          tools: [
            for (final t in current.tools)
              if (t.toolUseId == event.toolUseId)
                t.complete(rowsCount: event.rowsCount)
              else
                t,
          ],
        ));
      case 'text_delta':
        _updateLast(current.copyWith(
          text: current.text + event.text,
          clearThinking: true,
        ));
      case 'visualization':
        _updateLast(current.copyWith(
          visualizations: [
            ...current.visualizations,
            IaVisualization(kind: event.vizKind, data: event.vizData),
          ],
        ));
      case 'done':
        _finish();
      case 'error':
        _finish(error: event.message);
    }
  }

  void _finish({String? error}) {
    if (state.messages.isEmpty) return;
    final current = state.messages.last;
    if (current.role == 'assistant' && current.isStreaming) {
      _updateLast(current.copyWith(
        isStreaming: false,
        clearThinking: true,
        error: error,
      ));
    }
    state = state.copyWith(isStreaming: false);
    _subscription = null;
    _cancelToken = null;
  }

  void _updateLast(IaChatMessage message) {
    state = state.copyWith(
      messages: [
        ...state.messages.sublist(0, state.messages.length - 1),
        message,
      ],
    );
  }

  /// Cancela o stream em andamento.
  void stop() {
    _subscription?.cancel();
    _cancelToken?.cancel();
    _finish();
  }

  void clearConversation() {
    stop();
    state = const IaChatState();
  }

  String _friendlyError(Object e) {
    if (e is DioException && CancelToken.isCancel(e)) {
      return 'Consulta cancelada';
    }
    final msg = e.toString().replaceFirst('Exception: ', '');
    return msg.isEmpty ? 'Erro na conexão com a IA' : msg;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }
}

final iaChatProvider = StateNotifierProvider<IaChatNotifier, IaChatState>(
  (ref) {
    final notifier = IaChatNotifier(ref);
    // Troca de candidato → conversa anterior deixa de fazer sentido
    ref.listen<IaContexto?>(iaContextoProvider, (prev, next) {
      if (prev != null && prev.sequencial != next?.sequencial) {
        notifier.clearConversation();
      }
    });
    return notifier;
  },
);
