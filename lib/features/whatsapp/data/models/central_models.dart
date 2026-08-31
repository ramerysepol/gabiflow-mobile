/// Modelos da Central de Atendimento (paridade com a central web).
///
/// A API devolve os objetos ja mapeados em camelCase por
/// `lib/conversations/types-and-mappers.ts` do backend. O parse aqui e
/// deliberadamente tolerante (campos ausentes viram null/zero) porque o
/// contrato pertence ao web e pode ganhar campos novos a qualquer momento.
library;

DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

/// Conversa na lista da central.
class ConversaResumo {
  final int id;
  final String whatsappPhone;
  final String? contactName;
  final String? profilePictureUrl;
  final String
  status; // waiting | active | closed | archived | template_pending
  final int? assignedTo;
  final String? assignedToName;
  final String department;
  final String channel; // whatsapp | instagram | messenger | webchat
  final String? channelAccountId; // 'app' distingue App de Site (webchat)
  final bool withinWindow;
  final DateTime? windowExpiresAt;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final List<String> tags;
  final bool isPrivate;

  const ConversaResumo({
    required this.id,
    required this.whatsappPhone,
    this.contactName,
    this.profilePictureUrl,
    required this.status,
    this.assignedTo,
    this.assignedToName,
    required this.department,
    required this.channel,
    this.channelAccountId,
    required this.withinWindow,
    this.windowExpiresAt,
    required this.unreadCount,
    this.lastMessage,
    this.lastMessageAt,
    required this.tags,
    required this.isPrivate,
  });

  String get displayName => (contactName?.trim().isNotEmpty ?? false)
      ? contactName!.trim()
      : whatsappPhone;

  /// Canal efetivo p/ exibicao: webchat+conta 'app' vira 'app' (App), senao o
  /// proprio canal. Espelha `effectiveChannel()` da central web.
  String get canalEfetivo => (channel == 'webchat' && channelAccountId == 'app')
      ? 'app'
      : channel;

  /// Conversa vinda do app ou do site (canal webchat) — habilita "copiar nome".
  bool get ehAppOuSite =>
      canalEfetivo == 'app' || canalEfetivo == 'webchat';

  factory ConversaResumo.fromJson(Map<String, dynamic> json) => ConversaResumo(
    id: _int(json['id']),
    whatsappPhone: json['whatsappPhone']?.toString() ?? '',
    contactName: json['contactName'] as String?,
    profilePictureUrl: json['profilePictureUrl'] as String?,
    status: json['status']?.toString() ?? 'waiting',
    assignedTo: json['assignedTo'] == null ? null : _int(json['assignedTo']),
    assignedToName: json['assignedToName'] as String?,
    department: json['department']?.toString() ?? '',
    channel: json['channel']?.toString() ?? 'whatsapp',
    channelAccountId:
        (json['channelAccountId'] ?? json['channel_account_id'])?.toString(),
    withinWindow: json['withinWindow'] == true,
    windowExpiresAt: _dt(json['windowExpiresAt']),
    unreadCount: _int(json['unreadCount'] ??
        json['calculated_unread_count'] ??
        json['unread_count']),
    lastMessage: json['lastMessage'] as String?,
    lastMessageAt: _dt(json['lastMessageAt'] ?? json['lastCustomerMessageAt']),
    tags: (json['tags'] as List<dynamic>? ?? const [])
        .map((dynamic e) => e.toString())
        .toList(),
    isPrivate: json['isPrivate'] == true,
  );
}

/// Mensagem dentro de uma conversa.
class Mensagem {
  final int id;
  final int conversationId;
  final String direction; // inbound | outbound | system
  final String
  contentType; // text | image | audio | video | document | template | ...
  final String? textContent;
  final String? caption;
  final String? mediaUrl;
  final String? mediaMimeType;
  final String? mediaFilename;
  final String status; // pending | sent | delivered | read | played | failed
  final String? errorMessage;
  final String? sentByUserName;
  final String? quotedMessagePreview;
  final String? reactionEmoji;
  final DateTime createdAt;
  final String? localFilePath; // preview otimista de midia recem-enviada

  const Mensagem({
    required this.id,
    required this.conversationId,
    required this.direction,
    required this.contentType,
    this.textContent,
    this.caption,
    this.mediaUrl,
    this.mediaMimeType,
    this.mediaFilename,
    required this.status,
    this.errorMessage,
    this.sentByUserName,
    this.quotedMessagePreview,
    this.reactionEmoji,
    required this.createdAt,
    this.localFilePath,
  });

  bool get minha => direction == 'outbound';
  bool get sistema => direction == 'system';

  /// Texto exibido na bolha (ou descricao da midia quando nao ha texto).
  String get previewTexto {
    final t = textContent?.trim();
    if (t != null && t.isNotEmpty) return t;
    final c = caption?.trim();
    if (c != null && c.isNotEmpty) return c;
    switch (contentType) {
      case 'image':
        return '📷 Foto';
      case 'audio':
      case 'ptt':
      case 'voice':
        return '🎤 Áudio';
      case 'video':
        return '🎬 Vídeo';
      case 'document':
        return '📄 ${mediaFilename ?? 'Documento'}';
      case 'sticker':
        return 'Figurinha';
      case 'location':
        return '📍 Localização';
      case 'reaction':
        return '${reactionEmoji ?? '👍'} Reagiu a uma mensagem';
      default:
        return contentType;
    }
  }

  factory Mensagem.fromJson(Map<String, dynamic> json) => Mensagem(
    id: _int(json['id']),
    conversationId: _int(json['conversationId']),
    direction: json['direction']?.toString() ?? 'inbound',
    contentType: json['contentType']?.toString() ?? 'text',
    textContent: json['textContent'] as String?,
    caption: json['caption'] as String?,
    mediaUrl: json['mediaUrl'] as String?,
    mediaMimeType: json['mediaMimeType'] as String?,
    mediaFilename: json['mediaFilename'] as String?,
    status: json['status']?.toString() ?? 'sent',
    errorMessage: json['errorMessage'] as String?,
    sentByUserName: json['sentByUserName'] as String?,
    quotedMessagePreview: json['quotedMessagePreview'] as String?,
    reactionEmoji: json['reactionEmoji'] as String?,
    createdAt: _dt(json['createdAt']) ?? DateTime.now(),
  );

  Mensagem copyWith({int? id, String? status}) => Mensagem(
    id: id ?? this.id,
    conversationId: conversationId,
    direction: direction,
    contentType: contentType,
    textContent: textContent,
    caption: caption,
    mediaUrl: mediaUrl,
    mediaMimeType: mediaMimeType,
    mediaFilename: mediaFilename,
    status: status ?? this.status,
    errorMessage: errorMessage,
    sentByUserName: sentByUserName,
    quotedMessagePreview: quotedMessagePreview,
    reactionEmoji: reactionEmoji,
    createdAt: createdAt,
    localFilePath: localFilePath,
  );
}

/// Status da janela de 24h da Meta para a conversa (paridade com
/// `lib/whatsapp-window-manager.ts` do backend). Só é relevante quando o
/// canal é whatsapp e o provedor não é Z-API (ver [MensagensResult.
/// hasWindowRestriction]).
class JanelaInfo {
  final bool withinWindow;
  final bool canSendFreeMessage;
  final bool needsTemplate;
  final DateTime? windowExpiresAt;
  final String status; // active | expiring_soon | expired | never_started

  const JanelaInfo({
    required this.withinWindow,
    required this.canSendFreeMessage,
    required this.needsTemplate,
    this.windowExpiresAt,
    required this.status,
  });

  factory JanelaInfo.fromJson(Map<String, dynamic> json) => JanelaInfo(
    withinWindow: json['withinWindow'] == true,
    canSendFreeMessage: json['canSendFreeMessage'] == true,
    needsTemplate: json['needsTemplate'] == true,
    windowExpiresAt: _dt(json['windowExpiresAt']),
    status: json['status']?.toString() ?? 'active',
  );
}

/// Resultado da busca de mensagens: mensagens + status da janela 24h,
/// provedor ativo e se a conversa tem restrição de janela (só Meta API).
class MensagensResult {
  final List<Mensagem> mensagens;
  final JanelaInfo? janela;
  final String provider;
  final bool hasWindowRestriction;

  const MensagensResult({
    required this.mensagens,
    this.janela,
    required this.provider,
    required this.hasWindowRestriction,
  });
}

/// Resultado paginado da lista de conversas.
class ConversasResult {
  final List<ConversaResumo> conversas;
  final int total;
  final bool hasMore;
  final Map<String, dynamic> stats;

  const ConversasResult({
    required this.conversas,
    required this.total,
    required this.hasMore,
    required this.stats,
  });
}

/// Atendente disponivel para transferencia.
class AtendenteResumo {
  final int id;
  final String nome;

  const AtendenteResumo({required this.id, required this.nome});

  factory AtendenteResumo.fromJson(Map<String, dynamic> json) =>
      AtendenteResumo(
        id: _int(json['id']),
        nome: (json['name'] ?? json['nome'] ?? json['email'] ?? 'Atendente')
            .toString(),
      );
}

/// Detalhe completo de uma conversa (painel de Informacoes).
class ConversaDetalhe {
  final int id;
  final String? contactName;
  final String whatsappPhone;
  final String? profilePictureUrl;
  final String status;
  final String priority; // high | medium | normal | low
  final String department;
  final String channel;
  final String? channelAccountId;
  final String? internalNotes;
  final List<String> tags;
  final bool withinWindow;
  final DateTime? windowExpiresAt;
  final int? assignedTo;
  final String? assignedToName;
  final bool isPrivate;
  final bool isPaused;
  final int? constituentId;
  final String? constituentName;

  const ConversaDetalhe({
    required this.id,
    this.contactName,
    required this.whatsappPhone,
    this.profilePictureUrl,
    required this.status,
    required this.priority,
    required this.department,
    required this.channel,
    this.channelAccountId,
    this.internalNotes,
    required this.tags,
    required this.withinWindow,
    this.windowExpiresAt,
    this.assignedTo,
    this.assignedToName,
    required this.isPrivate,
    required this.isPaused,
    this.constituentId,
    this.constituentName,
  });

  String get canalEfetivo => (channel == 'webchat' && channelAccountId == 'app')
      ? 'app'
      : channel;

  factory ConversaDetalhe.fromJson(Map<String, dynamic> json) => ConversaDetalhe(
    id: _int(json['id']),
    contactName: json['contactName'] as String?,
    whatsappPhone: json['whatsappPhone']?.toString() ?? '',
    profilePictureUrl: json['profilePictureUrl'] as String?,
    status: json['status']?.toString() ?? 'waiting',
    priority: json['priority']?.toString() ?? 'normal',
    department: json['department']?.toString() ?? '',
    channel: json['channel']?.toString() ?? 'whatsapp',
    channelAccountId:
        (json['channelAccountId'] ?? json['channel_account_id'])?.toString(),
    internalNotes: (json['internalNotes'] ?? json['internal_notes']) as String?,
    tags: (json['tags'] as List<dynamic>? ?? const [])
        .map((dynamic e) => e.toString())
        .toList(),
    withinWindow: json['withinWindow'] == true,
    windowExpiresAt: _dt(json['windowExpiresAt']),
    assignedTo: json['assignedTo'] == null ? null : _int(json['assignedTo']),
    assignedToName: json['assignedToName'] as String?,
    isPrivate: json['isPrivate'] == true,
    isPaused: json['isPaused'] == true || json['paused'] == true,
    constituentId:
        (json['constituentId'] ?? json['constituent_id']) == null
            ? null
            : _int(json['constituentId'] ?? json['constituent_id']),
    constituentName:
        (json['constituentName'] ?? json['constituent_name']) as String?,
  );
}

/// Item do historico de protocolos/atendimentos anteriores do contato.
class ProtocoloHistorico {
  final int id;
  final String? protocolo;
  final String status;
  final DateTime? criadoEm;
  final DateTime? encerradoEm;
  final String? resumo;

  const ProtocoloHistorico({
    required this.id,
    this.protocolo,
    required this.status,
    this.criadoEm,
    this.encerradoEm,
    this.resumo,
  });

  factory ProtocoloHistorico.fromJson(Map<String, dynamic> json) =>
      ProtocoloHistorico(
        id: _int(json['id']),
        protocolo: (json['protocol'] ?? json['protocolo'] ?? json['ticket'])
            ?.toString(),
        status: json['status']?.toString() ?? '',
        criadoEm: _dt(json['createdAt'] ?? json['created_at']),
        encerradoEm: _dt(json['closedAt'] ?? json['closed_at']),
        resumo: (json['aiSummary'] ?? json['summary'] ?? json['lastMessage'])
            ?.toString(),
      );
}

/// Etiqueta (tag) do catalogo do tenant.
class Etiqueta {
  final int? id;
  final String nome;
  final String? cor; // hex "#RRGGBB"

  const Etiqueta({this.id, required this.nome, this.cor});

  factory Etiqueta.fromJson(Map<String, dynamic> json) => Etiqueta(
    id: json['id'] == null ? null : _int(json['id']),
    nome: (json['name'] ?? json['nome'] ?? '').toString(),
    cor: (json['color'] ?? json['cor'])?.toString(),
  );
}

/// Departamento/fila do tenant (destino de transferencia).
class Departamento {
  final String id; // pode vir numerico ou string; a rota aceita id ou nome
  final String nome;
  final String? cor;
  final bool ehIA;

  const Departamento({
    required this.id,
    required this.nome,
    this.cor,
    this.ehIA = false,
  });

  factory Departamento.fromJson(Map<String, dynamic> json) => Departamento(
    id: (json['id'] ?? json['name'] ?? '').toString(),
    nome: (json['name'] ?? json['nome'] ?? 'Departamento').toString(),
    cor: (json['color'] ?? json['cor'])?.toString(),
    ehIA: json['is_ai_department'] == true || json['isAiDepartment'] == true,
  );
}

/// Resposta rapida cadastrada no tenant.
class RespostaRapida {
  final int id;
  final String titulo;
  final String conteudo;

  const RespostaRapida({
    required this.id,
    required this.titulo,
    required this.conteudo,
  });

  factory RespostaRapida.fromJson(Map<String, dynamic> json) => RespostaRapida(
    id: _int(json['id']),
    titulo: (json['title'] ?? json['shortcut'] ?? json['name'] ?? '')
        .toString(),
    conteudo: (json['content'] ?? json['message'] ?? json['text'] ?? '')
        .toString(),
  );
}
