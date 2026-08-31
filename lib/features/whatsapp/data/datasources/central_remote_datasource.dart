// Central de Atendimento — consome as MESMAS rotas da central web
// (/api/whatsapp/conversations/*), que aceitam Authorization: Bearer.
// Nenhuma logica de negocio aqui: janela 24h, provedor Meta×Z-API e
// marcacao de lida sao decididos pelo servidor (maduro).

import 'package:dio/dio.dart';

import '../../../../core/constants/env_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../models/central_models.dart';

class CentralRemoteDataSource {
  final ApiClient _apiClient;

  CentralRemoteDataSource(this._apiClient);

  Future<Options> _authOptions() async {
    final token = await StorageService.getAccessToken();
    final tenantConfig = await StorageService.getTenantConfig();
    final tenantId = tenantConfig?['subdomain'] as String? ?? '';
    return Options(
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'X-Tenant-ID': tenantId,
      },
    );
  }

  /// Prefixa URLs relativas (/uploads/..., /api/whatsapp/media/...) com a URL
  /// do tenant, para Image.network/players conseguirem carregar.
  Future<String?> _absoluta(String? url) async {
    if (url == null || url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final tenantConfig = await StorageService.getTenantConfig();
    final sub = tenantConfig?['subdomain'] as String? ?? '';
    final base = EnvConfig.getTenantUrl(sub);
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  Map<String, dynamic> _unwrap(Response<dynamic> response, String contexto) {
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    final erro = data is Map<String, dynamic> ? data['error'] : null;
    throw Exception(erro?.toString() ?? 'Falha em $contexto');
  }

  /// Lista conversas. [status] em csv: 'waiting,active' etc.
  Future<ConversasResult> listarConversas({
    String status = 'waiting,active',
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.get<dynamic>(
      '/api/whatsapp/conversations',
      queryParameters: {
        'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'limit': limit,
        'offset': offset,
        'include_stats': 'true',
      },
      options: await _authOptions(),
    );
    final data = _unwrap(response, 'listar conversas');
    final lista = <ConversaResumo>[];
    for (final item in (data['conversations'] as List<dynamic>? ?? const [])) {
      if (item is! Map<String, dynamic>) continue;
      // Foto de perfil pode vir relativa (proxy local de midia da Meta)
      final abs = await _absoluta(item['profilePictureUrl'] as String?);
      if (abs != null) item['profilePictureUrl'] = abs;
      lista.add(ConversaResumo.fromJson(item));
    }
    return ConversasResult(
      conversas: lista,
      total: (data['total'] as num?)?.toInt() ?? lista.length,
      hasMore: data['hasMore'] == true,
      stats: data['stats'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// Busca mensagens; com [markRead] o servidor ja marca como lidas
  /// (mesmo comportamento da central web). Tambem devolve o status da
  /// janela de 24h e o provedor ativo — a mesma resposta do GET usado
  /// pela central web (ver `messages/route.ts`).
  Future<MensagensResult> listarMensagens(
    int conversationId, {
    bool markRead = true,
    int limit = 100,
    int? beforeId,
  }) async {
    final response = await _apiClient.get<dynamic>(
      '/api/whatsapp/conversations/$conversationId/messages',
      queryParameters: {
        'limit': limit,
        if (markRead) 'mark_read': 'true',
        if (beforeId != null) 'before_id': beforeId,
      },
      options: await _authOptions(),
    );
    final data = _unwrap(response, 'buscar mensagens');
    final mensagens = <Mensagem>[];
    for (final item in (data['messages'] as List<dynamic>? ?? const [])) {
      if (item is! Map<String, dynamic>) continue;
      final abs = await _absoluta(item['mediaUrl'] as String?);
      if (abs != null) item['mediaUrl'] = abs;
      mensagens.add(Mensagem.fromJson(item));
    }
    // Ordena por data crescente para renderizar do topo para baixo.
    mensagens.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      return cmp != 0 ? cmp : a.id.compareTo(b.id);
    });
    final janelaJson = data['window'];
    return MensagensResult(
      mensagens: mensagens,
      janela: janelaJson is Map<String, dynamic>
          ? JanelaInfo.fromJson(janelaJson)
          : null,
      provider: data['provider']?.toString() ?? 'unknown',
      hasWindowRestriction: data['hasWindowRestriction'] == true,
    );
  }

  /// Envia texto. Com [contextMessageId] a mensagem cita/responde outra
  /// (paridade com o reply do web). O servidor decide provedor/canal.
  Future<Mensagem> enviarTexto(
    int conversationId,
    String texto, {
    int? contextMessageId,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations/$conversationId/messages',
      data: {
        'type': 'text',
        'text': texto,
        if (contextMessageId != null) 'contextMessageId': contextMessageId,
      },
      options: await _authOptions(),
    );
    final data = _unwrap(response, 'enviar mensagem');
    final msg = data['message'];
    if (msg is Map<String, dynamic>) return Mensagem.fromJson(msg);
    throw Exception('Resposta sem mensagem ao enviar');
  }

  /// Encaminha uma mensagem para outra conversa (por id) ou numero (por telefone).
  Future<void> encaminharMensagem(
    int conversationId,
    int messageId, {
    int? paraConversa,
    String? paraTelefone,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations/$conversationId/messages/$messageId/forward',
      data: {
        if (paraConversa != null) 'targetConversationId': paraConversa,
        if (paraTelefone != null && paraTelefone.isNotEmpty)
          'targetPhone': paraTelefone,
      },
      options: await _authOptions(),
    );
    _unwrap(response, 'encaminhar mensagem');
  }

  /// Exclui uma mensagem (Meta nao remove no destinatario; some so da central).
  Future<void> excluirMensagem(int conversationId, int messageId) async {
    final response = await _apiClient.delete<dynamic>(
      '/api/whatsapp/conversations/$conversationId/messages/$messageId',
      options: await _authOptions(),
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == false) {
      throw Exception(data['error']?.toString() ?? 'Falha ao excluir mensagem');
    }
  }

  /// Cria (ou reabre) uma conversa por telefone/canal. Retorna o id.
  Future<int> criarConversa({
    required String telefone,
    String? nomeContato,
    String canal = 'whatsapp',
    String? contaCanal,
    String? mensagemInicial,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations',
      data: {
        'phone': telefone,
        if (nomeContato != null && nomeContato.isNotEmpty)
          'contactName': nomeContato,
        'channel': canal,
        if (contaCanal != null) 'channelAccountId': contaCanal,
        if (mensagemInicial != null && mensagemInicial.trim().isNotEmpty)
          'initialMessage': mensagemInicial.trim(),
      },
      options: await _authOptions(),
    );
    final data = _unwrap(response, 'criar conversa');
    final conv = data['conversation'];
    if (conv is Map<String, dynamic> && conv['id'] != null) {
      return (conv['id'] as num).toInt();
    }
    if (data['id'] != null) return (data['id'] as num).toInt();
    throw Exception('Resposta sem id da conversa criada');
  }

  /// Envia template Meta aprovado para reabrir a conversa fora da janela
  /// de 24h. [templateVariables] usa chaves numericas em string ("1", "2"…)
  /// na mesma ordem das variaveis {{1}}, {{2}} do corpo do template — o
  /// servidor monta os `components` de envio a partir delas (mesmo payload
  /// do `ChatPanel.tsx` da central web).
  Future<Mensagem> enviarTemplateMeta(
    int conversationId, {
    required String metaTemplateName,
    required String metaTemplateLanguage,
    Map<String, String>? templateVariables,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations/$conversationId/messages',
      data: {
        'type': 'template',
        'metaTemplateName': metaTemplateName,
        'metaTemplateLanguage': metaTemplateLanguage,
        if (templateVariables != null && templateVariables.isNotEmpty)
          'templateVariables': templateVariables,
      },
      options: await _authOptions(),
    );
    final data = _unwrap(response, 'enviar template');
    final msg = data['message'];
    if (msg is Map<String, dynamic>) return Mensagem.fromJson(msg);
    throw Exception('Resposta sem mensagem ao enviar template');
  }

  /// Envia midia (imagem/video/documento/audio) via multipart. O servidor
  /// valida tamanho/extensao e transcodifica audio para OGG/Opus (voz).
  Future<Mensagem> enviarMidia(
    int conversationId, {
    required String filePath,
    required String tipo, // image | video | audio | document
    String? caption,
    String? filename,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
      'type': tipo,
      if (caption != null && caption.trim().isNotEmpty)
        'caption': caption.trim(),
    });
    final base = await _authOptions();
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations/$conversationId/messages/media',
      data: form,
      options: base.copyWith(contentType: 'multipart/form-data'),
    );
    final data = _unwrap(response, 'enviar midia');
    final msg = data['message'];
    if (msg is Map<String, dynamic>) {
      final abs = await _absoluta(msg['mediaUrl'] as String?);
      if (abs != null) msg['mediaUrl'] = abs;
      return Mensagem.fromJson(msg);
    }
    throw Exception('Resposta sem mensagem ao enviar midia');
  }

  /// Detalhe completo da conversa (status, prioridade, departamento, notas,
  /// tags, janela, constituinte). Usado no painel de Informacoes.
  Future<ConversaDetalhe> detalheConversa(int conversationId) async {
    final response = await _apiClient.get<dynamic>(
      '/api/whatsapp/conversations/$conversationId',
      options: await _authOptions(),
    );
    final data = _unwrap(response, 'detalhe da conversa');
    final conv = data['conversation'];
    final mapa = conv is Map<String, dynamic> ? conv : data;
    final abs = await _absoluta(mapa['profilePictureUrl'] as String?);
    if (abs != null) mapa['profilePictureUrl'] = abs;
    return ConversaDetalhe.fromJson(mapa);
  }

  /// Atualiza campos da conversa (status, prioridade, departamento, notas).
  /// PATCH parcial — envia so o que for informado.
  Future<void> atualizarConversa(
    int conversationId, {
    String? status,
    String? prioridade,
    String? departamento,
    String? notasInternas,
  }) async {
    final response = await _apiClient.patch<dynamic>(
      '/api/whatsapp/conversations/$conversationId',
      data: {
        if (status != null) 'status': status,
        if (prioridade != null) 'priority': prioridade,
        if (departamento != null) 'department': departamento,
        if (notasInternas != null) 'internalNotes': notasInternas,
      },
      options: await _authOptions(),
    );
    _unwrap(response, 'atualizar conversa');
  }

  /// Pausa/retoma o atendimento da conversa.
  Future<void> pausarConversa(int conversationId, bool pausar) async {
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations/$conversationId/pause',
      data: {'paused': pausar},
      options: await _authOptions(),
    );
    _unwrap(response, 'pausar conversa');
  }

  /// Historico de protocolos/atendimentos anteriores do contato.
  Future<List<ProtocoloHistorico>> historicoProtocolos(
      int conversationId) async {
    final response = await _apiClient.get<dynamic>(
      '/api/whatsapp/conversations/$conversationId/history',
      options: await _authOptions(),
    );
    final data = _unwrap(response, 'historico');
    final lista = data['history'] ?? data['protocols'] ?? data['conversations'];
    if (lista is List) {
      return lista
          .whereType<Map<String, dynamic>>()
          .map(ProtocoloHistorico.fromJson)
          .toList();
    }
    return const [];
  }

  /// Assume a conversa para o usuario logado (atendimento ativo).
  /// Usa a rota /privacy (mesma do web): busca a conversa SEM o filtro de
  /// visibilidade por departamento — o PATCH direto retornava "nao encontrada".
  Future<void> assumirConversa(int conversationId, int userId) async {
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations/$conversationId/privacy',
      data: const <String, dynamic>{},
      options: await _authOptions(),
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == false) {
      throw Exception(data['error']?.toString() ?? 'Falha ao assumir conversa');
    }
  }

  /// Encerra a conversa (mesma rota do web). [resolucao] em
  /// resolved|unresolved|inactive; [notas] = observacoes do encerramento.
  Future<void> encerrarConversa(
    int conversationId, {
    String? motivo,
    String? resolucao,
    String? notas,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations/$conversationId/close',
      data: {
        'reason': motivo ?? 'Resolvido',
        if (resolucao != null) 'resolution': resolucao,
        if (notas != null && notas.trim().isNotEmpty) 'notes': notas.trim(),
      },
      options: await _authOptions(),
    );
    _unwrap(response, 'encerrar conversa');
  }

  /// Arquiva a conversa.
  Future<void> arquivarConversa(int conversationId) async {
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations/$conversationId/archive',
      data: const <String, dynamic>{},
      options: await _authOptions(),
    );
    _unwrap(response, 'arquivar conversa');
  }

  /// Transfere a conversa. Informe [paraUsuario] (atendente) OU
  /// [paraDepartamento] (id ou nome do departamento). [motivo] vira o `reason`
  /// registrado (mensagem de sistema + nota interna, igual ao web).
  Future<void> transferirConversa(
    int conversationId, {
    int? paraUsuario,
    String? paraDepartamento,
    String? motivo,
    String? notas,
  }) async {
    assert(paraUsuario != null || paraDepartamento != null,
        'informe atendente ou departamento');
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations/$conversationId/transfer',
      data: {
        if (paraUsuario != null) 'toUserId': paraUsuario,
        if (paraDepartamento != null && paraDepartamento.isNotEmpty)
          'toDepartment': paraDepartamento,
        'reason': (motivo != null && motivo.trim().isNotEmpty)
            ? motivo.trim()
            : 'Transferida pelo aplicativo',
        if (notas != null && notas.trim().isNotEmpty) 'notes': notas.trim(),
        'notifyUser': true,
      },
      options: await _authOptions(),
    );
    _unwrap(response, 'transferir conversa');
  }

  /// Departamentos ativos do tenant (destino de transferencia).
  Future<List<Departamento>> listarDepartamentos() async {
    final response = await _apiClient.get<dynamic>(
      '/api/whatsapp/departments',
      queryParameters: {'active_only': 'true'},
      options: await _authOptions(),
    );
    final raw = response.data;
    List<dynamic> lista = const [];
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'];
      if (inner is List<dynamic>) {
        lista = inner;
      } else if (inner is Map<String, dynamic> &&
          inner['departments'] is List<dynamic>) {
        lista = inner['departments'] as List<dynamic>;
      } else if (raw['departments'] is List<dynamic>) {
        lista = raw['departments'] as List<dynamic>;
      }
    }
    return lista
        .whereType<Map<String, dynamic>>()
        .map(Departamento.fromJson)
        .toList();
  }

  /// Catalogo de etiquetas (tags) do tenant, com cores.
  Future<List<Etiqueta>> listarEtiquetas() async {
    final response = await _apiClient
        .get<dynamic>(
          '/api/whatsapp/conversations/tags',
          options: await _authOptions(),
        )
        .timeout(const Duration(seconds: 12));
    final raw = response.data;
    List<dynamic> lista = const [];
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'];
      if (inner is List<dynamic>) {
        lista = inner;
      } else if (inner is Map<String, dynamic> && inner['tags'] is List) {
        lista = inner['tags'] as List<dynamic>;
      } else if (raw['tags'] is List<dynamic>) {
        lista = raw['tags'] as List<dynamic>;
      }
    }
    return lista
        .whereType<Map<String, dynamic>>()
        .map(Etiqueta.fromJson)
        .where((e) => e.nome.isNotEmpty)
        .toList();
  }

  /// Etiquetas atualmente aplicadas a uma conversa (nomes).
  /// O backend responde `{success:true, data:[...]}` — `data` e a LISTA de nomes.
  Future<List<String>> etiquetasDaConversa(int conversationId) async {
    final response = await _apiClient.get<dynamic>(
      '/api/whatsapp/conversations/$conversationId/tags',
      options: await _authOptions(),
    );
    final raw = response.data;
    final inner = raw is Map<String, dynamic> ? raw['data'] : null;
    final tags = inner is List
        ? inner
        : (inner is Map && inner['tags'] is List ? inner['tags'] as List : null);
    if (tags == null) return const [];
    return tags.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  /// Substitui as etiquetas aplicadas a uma conversa (PUT substitui o array).
  Future<void> atualizarEtiquetasConversa(
    int conversationId,
    List<String> etiquetas,
  ) async {
    final response = await _apiClient.put<dynamic>(
      '/api/whatsapp/conversations/$conversationId/tags',
      data: {'tags': etiquetas},
      options: await _authOptions(),
    );
    _unwrap(response, 'atualizar etiquetas');
  }

  /// Cria (ou faz upsert por nome) uma etiqueta no catalogo do tenant.
  Future<void> criarEtiqueta(String nome, {String? cor}) async {
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations/tags',
      data: {'name': nome, if (cor != null) 'color': cor},
      options: await _authOptions(),
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == false) {
      throw Exception(data['error']?.toString() ?? 'Falha ao criar etiqueta');
    }
  }

  /// Lista atendentes do tenant (para transferencia).
  Future<List<AtendenteResumo>> listarAtendentes() async {
    final response = await _apiClient.get<dynamic>(
      '/api/whatsapp/users',
      options: await _authOptions(),
    );
    final raw = response.data;
    List<dynamic> lista = const [];
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'];
      if (inner is List<dynamic>) {
        lista = inner;
      } else if (inner is Map<String, dynamic> &&
          inner['users'] is List<dynamic>) {
        lista = inner['users'] as List<dynamic>;
      }
    }
    return lista
        .whereType<Map<String, dynamic>>()
        .map(AtendenteResumo.fromJson)
        .toList();
  }

  /// Cadastra resposta rapida (mesma rota do web: shortcut normalizado la).
  Future<void> criarRespostaRapida({
    required String atalho,
    required String conteudo,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/quick-replies',
      data: {'shortcut': atalho, 'content': conteudo},
      options: await _authOptions(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic> || data['success'] != true) {
      final erro = data is Map<String, dynamic> ? data['error'] : null;
      throw Exception(erro?.toString() ?? 'Falha ao cadastrar resposta rapida');
    }
  }

  /// Abre o stream SSE da central (/api/whatsapp/sse). O chamador consome
  /// `.stream` para reagir a eventos em tempo real.
  Future<ResponseBody> conectarSse(CancelToken cancelToken) async {
    final resp = await _apiClient.getStream(
      '/api/whatsapp/sse',
      options: await _authOptions(),
      cancelToken: cancelToken,
    );
    return resp.data!;
  }

  /// Agenda uma mensagem para envio futuro.
  Future<void> agendarMensagem(
    int conversationId, {
    required String mensagem,
    required DateTime quando,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations/$conversationId/schedule',
      data: {
        'message': mensagem,
        'scheduledAt': quando.toUtc().toIso8601String(),
      },
      options: await _authOptions(),
    );
    _unwrap(response, 'agendar mensagem');
  }

  /// URL da conversa em PDF/imprimivel (abrir no navegador com o token do tenant).
  Future<String> urlExportarPdf(int conversationId) async {
    final tenantConfig = await StorageService.getTenantConfig();
    final sub = tenantConfig?['subdomain'] as String? ?? '';
    final base = EnvConfig.getTenantUrl(sub);
    return '$base/api/whatsapp/conversations/$conversationId/export-pdf';
  }

  /// Sugestoes de resposta geradas por IA. Backend: `{success:true, data:[...]}`
  /// — `data` e a LISTA de sugestoes (strings ou objetos com text/suggestion).
  Future<List<String>> sugestoesIA(int conversationId) async {
    final response = await _apiClient.get<dynamic>(
      '/api/whatsapp/conversations/$conversationId/suggestions',
      options: await _authOptions(),
    );
    final raw = response.data;
    final inner = raw is Map<String, dynamic> ? raw['data'] : null;
    final s = inner is List
        ? inner
        : (inner is Map
            ? (inner['suggestions'] ?? inner['suggestion'])
            : null);
    if (s is List) {
      return s
          .map((e) => e is Map
              ? (e['text'] ?? e['suggestion'] ?? e['content'] ?? e['message'] ?? '')
                  .toString()
              : e.toString())
          .where((t) => t.trim().isNotEmpty)
          .toList();
    }
    if (s is String && s.trim().isNotEmpty) return [s];
    return const [];
  }

  /// Atualiza uma resposta rapida existente.
  Future<void> atualizarRespostaRapida(
    int id, {
    required String atalho,
    required String conteudo,
  }) async {
    final response = await _apiClient.put<dynamic>(
      '/api/whatsapp/quick-replies',
      data: {'id': id, 'shortcut': atalho, 'content': conteudo},
      options: await _authOptions(),
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == false) {
      throw Exception(data['error']?.toString() ?? 'Falha ao atualizar');
    }
  }

  /// Exclui uma resposta rapida.
  Future<void> excluirRespostaRapida(int id) async {
    final response = await _apiClient.delete<dynamic>(
      '/api/whatsapp/quick-replies',
      queryParameters: {'id': id},
      options: await _authOptions(),
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == false) {
      throw Exception(data['error']?.toString() ?? 'Falha ao excluir');
    }
  }

  Future<List<RespostaRapida>> respostasRapidas() async {
    final response = await _apiClient.get<dynamic>(
      '/api/whatsapp/quick-replies',
      options: await _authOptions(),
    );
    final raw = response.data;
    List<dynamic> lista = const [];
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'];
      if (inner is List<dynamic>) {
        lista = inner;
      } else if (inner is Map<String, dynamic> &&
          inner['quickReplies'] is List<dynamic>) {
        lista = inner['quickReplies'] as List<dynamic>;
      }
    }
    return lista
        .whereType<Map<String, dynamic>>()
        .map(RespostaRapida.fromJson)
        .where((r) => r.conteudo.isNotEmpty)
        .toList();
  }
}
