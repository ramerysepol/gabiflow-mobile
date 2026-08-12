/// Models de demanda — sem geração de código.
class DemandNoteModel {
  final String id;
  final String content;
  final String? createdAt;
  final String? userName;

  const DemandNoteModel({
    required this.id,
    required this.content,
    this.createdAt,
    this.userName,
  });

  factory DemandNoteModel.fromJson(Map<String, dynamic> json) =>
      DemandNoteModel(
        id: json['id']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        createdAt: json['created_at']?.toString(),
        userName: json['user_name']?.toString(),
      );
}

class DemandActivityModel {
  final String id;
  final String type;
  final String description;
  final String? createdAt;
  final String? userName;

  const DemandActivityModel({
    required this.id,
    required this.type,
    required this.description,
    this.createdAt,
    this.userName,
  });

  factory DemandActivityModel.fromJson(Map<String, dynamic> json) =>
      DemandActivityModel(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        createdAt: json['created_at']?.toString(),
        userName: json['user_name']?.toString(),
      );
}

class DemandStatusCounts {
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;

  const DemandStatusCounts({
    this.pending = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.cancelled = 0,
  });

  factory DemandStatusCounts.fromJson(Map<String, dynamic> json) =>
      DemandStatusCounts(
        pending: _parseInt(json['pending']),
        inProgress: _parseInt(json['in_progress']),
        completed: _parseInt(json['completed']),
        cancelled: _parseInt(json['cancelled']),
      );
}

class DemandModel {
  final String id;
  final String titulo;
  final String? descricao;
  final String status;
  final String prioridade;
  final String? constituentId;
  final String? constituentNome;
  final String? deadline;
  final String? categoria;
  final List<DemandNoteModel> notes;
  final List<DemandActivityModel> activities;
  final String? createdAt;
  final String? updatedAt;

  const DemandModel({
    required this.id,
    required this.titulo,
    this.descricao,
    this.status = 'pending',
    this.prioridade = 'medium',
    this.constituentId,
    this.constituentNome,
    this.deadline,
    this.categoria,
    this.notes = const [],
    this.activities = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory DemandModel.fromJson(Map<String, dynamic> json) {
    final rawNotes = json['notes'];
    final notes = rawNotes is List
        ? rawNotes
            .map((e) => DemandNoteModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <DemandNoteModel>[];

    final rawActivities = json['activities'];
    final activities = rawActivities is List
        ? rawActivities
            .map((e) =>
                DemandActivityModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <DemandActivityModel>[];

    return DemandModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? json['title']?.toString() ?? '',
      descricao: json['descricao']?.toString() ??
          json['description']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      prioridade: json['prioridade']?.toString() ??
          json['priority']?.toString() ??
          'medium',
      constituentId: json['constituent_id']?.toString(),
      constituentNome: json['constituent_nome']?.toString() ??
          json['constituent_name']?.toString(),
      deadline: json['deadline']?.toString(),
      categoria: json['categoria']?.toString() ??
          json['category']?.toString(),
      notes: notes,
      activities: activities,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class DemandListResponse {
  final List<DemandModel> items;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final DemandStatusCounts? statusCounts;

  const DemandListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.statusCounts,
  });

  factory DemandListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .map((e) => DemandModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <DemandModel>[];

    final rawCounts = json['statusCounts'];
    final counts = rawCounts is Map<String, dynamic>
        ? DemandStatusCounts.fromJson(rawCounts)
        : null;

    return DemandListResponse(
      items: items,
      total: _parseInt(json['total']),
      page: _parseInt(json['page']),
      limit: _parseInt(json['limit']),
      hasMore: json['hasMore'] as bool? ?? false,
      statusCounts: counts,
    );
  }
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// Anexo de uma demanda. Espelha o retorno de
/// GET/POST /api/mobile/demands/{id}/attachments
class DemandAttachment {
  final String id;
  final String filename;
  /// Caminho servido pelo servidor, ex.: /uploads/demands/12/1754-foto.jpg
  final String url;
  final String? fileType;
  final int fileSize;
  final DateTime? createdAt;

  const DemandAttachment({
    required this.id,
    required this.filename,
    required this.url,
    this.fileType,
    this.fileSize = 0,
    this.createdAt,
  });

  bool get isImage => (fileType ?? '').startsWith('image/');

  /// Tamanho legivel para exibir na lista.
  String get tamanhoLegivel {
    if (fileSize <= 0) return '';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(0)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory DemandAttachment.fromJson(Map<String, dynamic> json) {
    return DemandAttachment(
      id: json['id']?.toString() ?? '',
      filename: json['filename'] as String? ?? 'anexo',
      url: json['url'] as String? ?? '',
      fileType: json['fileType'] as String?,
      fileSize: _parseInt(json['fileSize']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
