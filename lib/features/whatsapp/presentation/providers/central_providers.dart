// Estado da Central de Atendimento.
//
// Tempo real: SSE como gatilho de refresh instantaneo + polling como
// fallback garantido (lista a cada 15s, chat aberto a cada 8s).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/central_remote_datasource.dart';
import '../../data/datasources/central_sse_service.dart';
import '../../data/models/central_models.dart';
import '../../../../core/network/friendly_error.dart';

final centralDataSourceProvider = Provider<CentralRemoteDataSource>((ref) {
  return CentralRemoteDataSource(ref.watch(apiClientProvider));
});

// ── Lista de conversas ─────────────────────────────────────────────────────

class ConversasState {
  final List<ConversaResumo> conversas;
  final Map<String, dynamic> stats;
  final int total;
  final bool carregando;
  final bool carregandoMais;
  final bool hasMore;
  final String? erro;
  final String filtroStatus; // csv aceito pela API
  final String busca;

  const ConversasState({
    this.conversas = const [],
    this.stats = const {},
    this.total = 0,
    this.carregando = false,
    this.carregandoMais = false,
    this.hasMore = false,
    this.erro,
    this.filtroStatus = 'waiting,active',
    this.busca = '',
  });

  ConversasState copyWith({
    List<ConversaResumo>? conversas,
    Map<String, dynamic>? stats,
    int? total,
    bool? carregando,
    bool? carregandoMais,
    bool? hasMore,
    String? erro,
    String? filtroStatus,
    String? busca,
    bool limparErro = false,
  }) => ConversasState(
    conversas: conversas ?? this.conversas,
    stats: stats ?? this.stats,
    total: total ?? this.total,
    carregando: carregando ?? this.carregando,
    carregandoMais: carregandoMais ?? this.carregandoMais,
    hasMore: hasMore ?? this.hasMore,
    erro: limparErro ? null : (erro ?? this.erro),
    filtroStatus: filtroStatus ?? this.filtroStatus,
    busca: busca ?? this.busca,
  );
}

class ConversasNotifier extends StateNotifier<ConversasState> {
  final CentralRemoteDataSource _ds;
  Timer? _pollTimer;
  CentralSseService? _sse;
  static const _pagina = 50;
  int _limite = _pagina; // cresce no scroll infinito; o poll re-busca a pagina toda

  ConversasNotifier(this._ds) : super(const ConversasState()) {
    carregar();
    // SSE dispara refresh instantaneo; o polling (mais lento) e o fallback.
    _sse = CentralSseService(_ds, onEvento: () => carregar(silencioso: true))
      ..conectar();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => carregar(silencioso: true),
    );
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) state = state.copyWith(carregando: true, limparErro: true);
    try {
      final r = await _ds.listarConversas(
        status: state.filtroStatus,
        search: state.busca.isEmpty ? null : state.busca,
        limit: _limite,
      );
      if (!mounted) return;
      state = state.copyWith(
        conversas: r.conversas,
        stats: r.stats,
        total: r.total,
        hasMore: r.hasMore,
        carregando: false,
        limparErro: true,
      );
    } catch (e) {
      if (!mounted) return;
      // Em polling silencioso mantem a lista atual; so registra o erro.
      state = state.copyWith(carregando: false, erro: mensagemAmigavel(e));
    }
  }

  /// Scroll infinito: aumenta a pagina e recarrega (mantem simples e compativel
  /// com o polling, que sempre busca a pagina inteira).
  Future<void> carregarMais() async {
    if (state.carregandoMais || !state.hasMore) return;
    state = state.copyWith(carregandoMais: true);
    _limite += _pagina;
    await carregar(silencioso: true);
    if (mounted) state = state.copyWith(carregandoMais: false);
  }

  void setFiltro(String statusCsv) {
    _limite = _pagina;
    state = state.copyWith(filtroStatus: statusCsv);
    carregar();
  }

  void setBusca(String texto) {
    _limite = _pagina;
    state = state.copyWith(busca: texto);
    carregar();
  }

  /// Remove a conversa da lista na hora (encerrada/arquivada). Sem isto ela
  /// ficava visivel ate o proximo tick do polling de 15s. O poll seguinte
  /// confirma o estado real do servidor.
  void removerConversa(int conversationId) {
    final restantes = state.conversas
        .where((c) => c.id != conversationId)
        .toList(growable: false);
    if (restantes.length == state.conversas.length) return;
    state = state.copyWith(
      conversas: restantes,
      total: state.total > 0 ? state.total - 1 : 0,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _sse?.fechar();
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
  final JanelaInfo? janela;
  final String provider;
  final bool hasWindowRestriction;

  /// Visitante do webchat digitando agora (via SSE typing_start/stop).
  final bool digitando;

  const ChatState({
    this.mensagens = const [],
    this.carregando = false,
    this.enviando = false,
    this.erro,
    this.janela,
    this.provider = 'unknown',
    this.hasWindowRestriction = false,
    this.digitando = false,
  });

  /// Bloqueio de envio livre só existe quando o provedor tem restrição de
  /// janela (Meta API) E a janela realmente expirou.
  bool get janelaExpirada =>
      hasWindowRestriction && janela != null && !janela!.withinWindow;

  ChatState copyWith({
    List<Mensagem>? mensagens,
    bool? carregando,
    bool? enviando,
    String? erro,
    JanelaInfo? janela,
    String? provider,
    bool? hasWindowRestriction,
    bool? digitando,
    bool limparErro = false,
  }) => ChatState(
    mensagens: mensagens ?? this.mensagens,
    carregando: carregando ?? this.carregando,
    enviando: enviando ?? this.enviando,
    erro: limparErro ? null : (erro ?? this.erro),
    janela: janela ?? this.janela,
    provider: provider ?? this.provider,
    hasWindowRestriction: hasWindowRestriction ?? this.hasWindowRestriction,
    digitando: digitando ?? this.digitando,
  );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final CentralRemoteDataSource _ds;
  final int conversationId;
  Timer? _pollTimer;
  CentralSseService? _sse;
  int _enviosLocais = 0; // ids negativos temporarios para otimismo

  Timer? _typingClear;

  ChatNotifier(this._ds, this.conversationId) : super(const ChatState()) {
    carregar();
    _sse = CentralSseService(
      _ds,
      onEvento: () => carregar(silencioso: true),
      onTyping: _aoDigitar,
    )..conectar();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => carregar(silencioso: true),
    );
  }

  /// Visitante digitando nesta conversa. `typing_start` some sozinho após 6s
  /// sem sinal novo (proteção contra "digitando" órfão se o stop se perder).
  void _aoDigitar(int convId, bool digitando) {
    if (convId != conversationId || !mounted) return;
    _typingClear?.cancel();
    if (digitando) {
      state = state.copyWith(digitando: true);
      _typingClear = Timer(const Duration(seconds: 6), () {
        if (mounted) state = state.copyWith(digitando: false);
      });
    } else {
      state = state.copyWith(digitando: false);
    }
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) state = state.copyWith(carregando: true, limparErro: true);
    try {
      final resultado = await _ds.listarMensagens(conversationId);
      if (!mounted) return;
      // Preserva mensagens otimistas (id negativo) ainda nao confirmadas.
      final pendentes = state.mensagens
          .where((m) => m.id < 0)
          .toList(growable: false);
      state = state.copyWith(
        mensagens: [...resultado.mensagens, ...pendentes],
        carregando: false,
        limparErro: true,
        janela: resultado.janela,
        provider: resultado.provider,
        hasWindowRestriction: resultado.hasWindowRestriction,
      );
    } catch (e) {
      if (!mounted) return;
      // Falha transitoria de rede no polling nao vira alarme visual: o
      // proximo tick (5s) resolve sozinho. So mostra erro quando ainda nao
      // ha nada na tela (falha real de carregamento inicial).
      if (state.mensagens.isEmpty) {
        state = state.copyWith(carregando: false, erro: mensagemAmigavel(e));
      } else {
        state = state.copyWith(carregando: false);
      }
    }
  }

  Future<void> enviarTexto(String texto, {int? contextMessageId}) async {
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
      final enviada = await _ds.enviarTexto(
        conversationId,
        limpo,
        contextMessageId: contextMessageId,
      );
      if (!mounted) return;
      final atualizadas = state.mensagens
          .map((m) => m.id == otimista.id ? enviada : m)
          .toList(growable: false);
      state = state.copyWith(mensagens: atualizadas, enviando: false);
    } catch (e) {
      if (!mounted) return;
      final atualizadas = state.mensagens
          .map(
            (m) =>
                m.id == otimista.id ? otimista.copyWith(status: 'failed') : m,
          )
          .toList(growable: false);
      state = state.copyWith(
        mensagens: atualizadas,
        enviando: false,
        erro: 'Falha ao enviar. ${mensagemAmigavel(e)}',
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
          .map(
            (m) =>
                m.id == otimista.id ? otimista.copyWith(status: 'failed') : m,
          )
          .toList(growable: false);
      state = state.copyWith(
        mensagens: atualizadas,
        enviando: false,
        erro: 'Falha ao enviar mídia. ${mensagemAmigavel(e)}',
      );
    }
  }

  /// Reabre a conversa fora da janela de 24h enviando um template Meta
  /// aprovado. Ao concluir, recarrega mensagens + janela (o template pode
  /// ter renovado a janela no servidor).
  Future<bool> enviarTemplateMeta({
    required String metaTemplateName,
    required String metaTemplateLanguage,
    Map<String, String>? templateVariables,
  }) async {
    if (state.enviando) return false;
    state = state.copyWith(enviando: true, limparErro: true);
    try {
      await _ds.enviarTemplateMeta(
        conversationId,
        metaTemplateName: metaTemplateName,
        metaTemplateLanguage: metaTemplateLanguage,
        templateVariables: templateVariables,
      );
      if (!mounted) return true;
      state = state.copyWith(enviando: false);
      await carregar();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        enviando: false,
        erro: 'Falha ao enviar template. ${mensagemAmigavel(e)}',
      );
      return false;
    }
  }

  /// Encaminha uma mensagem para outra conversa/numero.
  Future<bool> encaminhar(int messageId,
      {int? paraConversa, String? paraTelefone}) async {
    try {
      await _ds.encaminharMensagem(
        conversationId,
        messageId,
        paraConversa: paraConversa,
        paraTelefone: paraTelefone,
      );
      return true;
    } catch (e) {
      if (mounted) state = state.copyWith(erro: 'Falha ao encaminhar. ${mensagemAmigavel(e)}');
      return false;
    }
  }

  /// Exclui uma mensagem (some da central; Meta nao remove no destinatario).
  Future<void> excluir(int messageId) async {
    final antes = state.mensagens;
    // Remocao otimista.
    state = state.copyWith(
      mensagens: antes.where((m) => m.id != messageId).toList(growable: false),
    );
    try {
      await _ds.excluirMensagem(conversationId, messageId);
    } catch (e) {
      if (!mounted) return;
      // Reverte se falhar.
      state = state.copyWith(mensagens: antes, erro: 'Falha ao excluir. ${mensagemAmigavel(e)}');
    }
  }

  Future<bool> assumir(int userId) async {
    try {
      await _ds.assumirConversa(conversationId, userId);
      return true;
    } catch (e) {
      if (mounted) state = state.copyWith(erro: mensagemAmigavel(e));
      return false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingClear?.cancel();
    _sse?.fechar();
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

/// Catalogo de etiquetas do tenant (mantido em cache enquanto a central estiver
/// aberta). Mapa nome->hex fica em [catalogoCoresEtiquetasProvider].
final etiquetasCatalogoProvider =
    FutureProvider.autoDispose<List<Etiqueta>>((ref) {
      return ref.watch(centralDataSourceProvider).listarEtiquetas();
    });

/// Mapa nome->cor(hex) das etiquetas, para colorir os chips na lista/cabecalho.
/// Vazio enquanto carrega ou em erro (o chip cai na cor padrao).
final catalogoCoresEtiquetasProvider = Provider.autoDispose<Map<String, String>>(
  (ref) {
    final cat = ref.watch(etiquetasCatalogoProvider);
    return cat.maybeWhen(
      data: (lista) => {
        for (final e in lista)
          if (e.cor != null && e.cor!.isNotEmpty) e.nome: e.cor!,
      },
      orElse: () => const {},
    );
  },
);

/// Departamentos ativos do tenant (destino de transferencia).
final departamentosProvider =
    FutureProvider.autoDispose<List<Departamento>>((ref) {
      return ref.watch(centralDataSourceProvider).listarDepartamentos();
    });
