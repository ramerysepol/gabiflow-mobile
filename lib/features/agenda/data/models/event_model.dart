/// Models de eventos — sem geração de código.
class EventParticipantModel {
  final String id;
  final String nome;
  final String? telefone;

  const EventParticipantModel({
    required this.id,
    required this.nome,
    this.telefone,
  });

  factory EventParticipantModel.fromJson(Map<String, dynamic> json) =>
      EventParticipantModel(
        id: json['id']?.toString() ?? '',
        nome: json['nome']?.toString() ?? json['name']?.toString() ?? '',
        telefone: json['telefone']?.toString() ??
            json['telefone']?.toString(),
      );
}

class EventModel {
  final String id;
  final String titulo;
  final String? descricao;
  final String startDate;
  final String? endDate;
  final String? location;

  /// Valor de `agendas.agenda_tipo` — ver [agendaTipos] para a lista oficial.
  final String type;
  final int participantCount;
  final List<EventParticipantModel> participants;
  final String? createdAt;

  /// Compromisso que ocupa o dia inteiro: nao mostrar horario.
  final bool diaTodo;

  /// Visivel apenas para a equipe; nao vai para a agenda publica.
  final bool privado;

  /// Tem vinculo com o Google Calendar (`google_event_id` preenchido). O app
  /// exibe um selo para deixar claro que a alteracao vai repercutir la'.
  final bool sincronizadoGoogle;

  final String? status;
  final String? notasInternas;
  final String? urlEvento;

  const EventModel({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.startDate,
    this.endDate,
    this.location,
    this.type = 'outro',
    this.participantCount = 0,
    this.participants = const [],
    this.createdAt,
    this.diaTodo = false,
    this.privado = false,
    this.sincronizadoGoogle = false,
    this.status,
    this.notasInternas,
    this.urlEvento,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'];
    final participants = rawParticipants is List
        ? rawParticipants
            .map((e) =>
                EventParticipantModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <EventParticipantModel>[];

    return EventModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? json['title']?.toString() ?? '',
      descricao: json['descricao']?.toString() ??
          json['description']?.toString(),
      startDate:
          json['start_date']?.toString() ?? DateTime.now().toIso8601String(),
      endDate: json['end_date']?.toString(),
      location: json['location']?.toString(),
      // A API devolve `agenda_tipo` sob a chave `type` (ver mapEventListRow).
      type: json['type']?.toString() ?? json['agenda_tipo']?.toString() ?? 'outro',
      participantCount: _parseInt(json['participant_count']),
      participants: participants,
      createdAt: json['created_at']?.toString(),
      diaTodo: json['dia_todo'] == true,
      privado: json['privado'] == true,
      sincronizadoGoogle: json['sincronizado_google'] == true,
      status: json['status']?.toString(),
      notasInternas: json['notas_internas']?.toString(),
      urlEvento: json['url_evento']?.toString(),
    );
  }
}

class EventListResponse {
  final List<EventModel> items;

  const EventListResponse({required this.items});

  factory EventListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <EventModel>[];
    return EventListResponse(items: items);
  }
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
