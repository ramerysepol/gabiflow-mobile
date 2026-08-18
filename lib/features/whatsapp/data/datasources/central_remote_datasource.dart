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
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
      'X-Tenant-ID': tenantId,
    });
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
    final lista = (data['conversations'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ConversaResumo.fromJson)
        .toList();
    return ConversasResult(
      conversas: lista,
      total: (data['total'] as num?)?.toInt() ?? lista.length,
      hasMore: data['hasMore'] == true,
      stats: data['stats'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// Busca mensagens; com [markRead] o servidor ja marca como lidas
  /// (mesmo comportamento da central web).
  Future<List<Mensagem>> listarMensagens(
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
      var m = Mensagem.fromJson(item);
      final abs = await _absoluta(m.mediaUrl);
      if (abs != m.mediaUrl) {
        m = Mensagem(
          id: m.id,
          conversationId: m.conversationId,
          direction: m.direction,
          contentType: m.contentType,
          textContent: m.textContent,
          caption: m.caption,
          mediaUrl: abs,
          mediaMimeType: m.mediaMimeType,
          mediaFilename: m.mediaFilename,
          status: m.status,
          errorMessage: m.errorMessage,
          sentByUserName: m.sentByUserName,
          quotedMessagePreview: m.quotedMessagePreview,
          createdAt: m.createdAt,
        );
      }
      mensagens.add(m);
    }
    // Ordena por data crescente para renderizar do topo para baixo.
    mensagens.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      return cmp != 0 ? cmp : a.id.compareTo(b.id);
    });
    return mensagens;
  }

  /// Envia texto. O servidor decide provedor/canal e devolve a mensagem criada.
  Future<Mensagem> enviarTexto(int conversationId, String texto) async {
    final response = await _apiClient.post<dynamic>(
      '/api/whatsapp/conversations/$conversationId/messages',
      data: {'type': 'text', 'text': texto},
      options: await _authOptions(),
    );
    final data = _unwrap(response, 'enviar mensagem');
    final msg = data['message'];
    if (msg is Map<String, dynamic>) return Mensagem.fromJson(msg);
    throw Exception('Resposta sem mensagem ao enviar');
  }

  /// Assume a conversa para o usuario logado (atendimento ativo).
  Future<void> assumirConversa(int conversationId, int userId) async {
    final response = await _apiClient.patch<dynamic>(
      '/api/whatsapp/conversations/$conversationId',
      data: {'assignedTo': userId, 'status': 'active'},
      options: await _authOptions(),
    );
    _unwrap(response, 'assumir conversa');
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
