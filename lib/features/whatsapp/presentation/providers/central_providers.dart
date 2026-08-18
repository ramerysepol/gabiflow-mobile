// Estado da Central de Atendimento.
//
// Tempo real por polling (mesma estrategia de fallback da central web:
// lista a cada 10s, chat aberto a cada 5s). SSE entra numa iteracao futura
// reaproveitando o padrao ja existente no chat de IA.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/central_remote_datasource.dart';
import '../../data/models/central_models.dart';

final centralDataSourceProvider = Provider<CentralRemoteDataSource>((ref) {
  return CentralRemoteDataSource(ref.watch(apiClientProvider));
});

// ── Lista de conversas ─────────────────────────────────────────────────────

class ConversasState {
  final List<ConversaResumo> conversas;
  final Map<String, dynamic> stats;
  final bool carregando;
  final String? erro;
  final String filtroStatus; // csv aceito pela API
  final String busca;

  const ConversasState({
    this.conversas = const [],
    this.stats = const {},
    this.carregando = false,
    this.erro,
    this.filtroStatus = 'waiting,active',
    this.busca = '',
  });

  ConversasState copyWith({
    List<ConversaResumo>? conversas,
    Map<String, dynamic>? stats,
    bool? carregando,
    String? erro,
    String? filtroStatus,
    String? busca,
    bool limparErro = false,
  }) =>
      ConversasState(
        conversas: conversas ?? this.conversas,
        stats: stats ?? this.stats,
        carregando: carregando ?? this.carregando,
        erro: limparErro ? null : (erro ?? this.erro),
        filtroStatus: filtroStatus ?? this.filtroStatus,
        busca: busca ?? this.busca,
      );
}

class ConversasNotifier extends StateNotifier<ConversasState> {
  final CentralRemoteDataSource _ds;
  Timer? _pollTimer;

  ConversasNotifier(this._ds) : super(const ConversasState()) {
    carregar();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => carregar(silencioso: true),
    );
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) state = state.copyWith(carregando: true, limparErro: true);
    try {
      final r = await _ds.listarConversas(
        status: state.filtroStatus,
        search: state.busca.isEmpty ? null : state.busca,
      );
      if (!mounted) return;
      state = state.copyWith(
        conversas: r.conversas,
        stats: r.stats,
        carregando: false,
        limparErro: true,
      );
    } catch (e) {
      if (!mounted) return;
      // Em polling silencioso mantem a lista atual; so registra o erro.
      state = state.copyWith(carregando: false, erro: e.toString());
    }
  }

  void setFiltro(String statusCsv) {
    state = state.copyWith(filtroStatus: statusCsv);
    carregar();
  }

  void setBusca(String texto) {
    state = state.copyWith(busca: texto);
    carregar();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final conversasProvider =
    StateNotifierProvider.autoDispose<ConversasNotifier, ConversasState>((ref) {
  return ConversasNotifier(ref.watch(centralDataSourceProvider));
});

// ── Chat de uma conversa ───────────────────────────────────────────────────

class ChatState {
  final List<Mensagem> mensagens;
  final bool carregando;
  final bool enviando;
  final String? erro;

  const ChatState({
    this.mensagens = const [],
    this.carregando = false,
    this.enviando = false,
    this.erro,
  });

  ChatState copyWith({
    List<Mensagem>? mensagens,
    bool? carregando,
    bool? enviando,
    String? erro,
    bool limparErro = false,
  }) =>
      ChatState(
        mensagens: mensagens ?? this.mensagens,
        carregando: carregando ?? this.carregando,
        enviando: enviando ?? this.enviando,
        erro: limparErro ? null : (erro ?? this.erro),
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final CentralRemoteDataSource _ds;
  final int conversationId;
  Timer? _pollTimer;
  int _enviosLocais = 0; // ids negativos temporarios para otimismo

  ChatNotifier(this._ds, this.conversationId) : super(const ChatState()) {
    carregar();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => carregar(silencioso: true),
    );
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) state = state.copyWith(carregando: true, limparErro: true);
    try {
      final mensagens = await _ds.listarMensagens(conversationId);
      if (!mounted) return;
      // Preserva mensagens otimistas (id negativo) ainda nao confirmadas.
      final pendentes =
          state.mensagens.where((m) => m.id < 0).toList(growable: false);
      state = state.copyWith(
        mensagens: [...mensagens, ...pendentes],
        carregando: false,
        limparErro: true,
      );
    } catch (e) {
      if (!mounted) return;
      // Falha transitoria de rede no polling nao vira alarme visual: o
      // proximo tick (5s) resolve sozinho. So mostra erro quando ainda nao
      // ha nada na tela (falha real de carregamento inicial).
      if (state.mensagens.isEmpty) {
        state = state.copyWith(carregando: false, erro: e.toString());
      } else {
        state = state.copyWith(carregando: false);
      }
    }
  }

  Future<void> enviarTexto(String texto) async {
    final limpo = texto.trim();
    if (limpo.isEmpty || state.enviando) return;

    // Bolha otimista imediata (relogio), como no WhatsApp.
    _enviosLocais++;
    final otimista = Mensagem(
      id: -_enviosLocais,
      conversationId: conversationId,
      direction: 'outbound',
      contentType: 'text',
      textContent: limpo,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      mensagens: [...state.mensagens, otimista],
      enviando: true,
      limparErro: true,
    );

    try {
      final enviada = await _ds.enviarTexto(conversationId, limpo);
      if (!mounted) return;
      final atualizadas = state.mensagens
          .map((m) => m.id == otimista.id ? enviada : m)
          .toList(growable: false);
      state = state.copyWith(mensagens: atualizadas, enviando: false);
    } catch (e) {
      if (!mounted) return;
      final atualizadas = state.mensagens
          .map((m) =>
              m.id == otimista.id ? otimista.copyWith(status: 'failed') : m)
          .toList(growable: false);
      state = state.copyWith(
        mensagens: atualizadas,
        enviando: false,
        erro: 'Falha ao enviar: $e',
      );
    }
  }

  /// Envia midia com bolha otimista mostrando o arquivo local.
  Future<void> enviarMidia({
    required String filePath,
    required String tipo,
    String? caption,
    String? filename,
  }) async {
    _enviosLocais++;
    final otimista = Mensagem(
      id: -_enviosLocais,
      conversationId: conversationId,
      direction: 'outbound',
      contentType: tipo,
      caption: caption,
      mediaFilename: filename,
      status: 'pending',
      createdAt: DateTime.now(),
      localFilePath: filePath,
    );
    state = state.copyWith(
      mensagens: [...state.mensagens, otimista],
      enviando: true,
      limparErro: true,
    );
    try {
      final enviada = await _ds.enviarMidia(
        conversationId,
        filePath: filePath,
        tipo: tipo,
        caption: caption,
        filename: filename,
      );
      if (!mounted) return;
      final atualizadas = state.mensagens
          .map((m) => m.id == otimista.id ? enviada : m)
          .toList(growable: false);
      state = state.copyWith(mensagens: atualizadas, enviando: false);
    } catch (e) {
      if (!mounted) return;
      final atualizadas = state.mensagens
          .map((m) =>
              m.id == otimista.id ? otimista.copyWith(status: 'failed') : m)
          .toList(growable: false);
      state = state.copyWith(
        mensagens: atualizadas,
        enviando: false,
        erro: 'Falha ao enviar mídia: $e',
      );
    }
  }

  Future<bool> assumir(int userId) async {
    try {
      await _ds.assumirConversa(conversationId, userId);
      return true;
    } catch (e) {
      if (mounted) state = state.copyWith(erro: e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider.autoDispose
    .family<ChatNotifier, ChatState, int>((ref, conversationId) {
  return ChatNotifier(ref.watch(centralDataSourceProvider), conversationId);
});

/// Respostas rapidas do tenant (carrega uma vez por sessao de tela).
final respostasRapidasProvider =
    FutureProvider.autoDispose<List<RespostaRapida>>((ref) {
  return ref.watch(centralDataSourceProvider).respostasRapidas();
});
