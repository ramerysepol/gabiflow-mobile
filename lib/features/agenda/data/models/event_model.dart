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
  final String type;
  final int participantCount;
  final List<EventParticipantModel> participants;
  final String? createdAt;

  const EventModel({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.startDate,
    this.endDate,
    this.location,
    this.type = 'reuniao',
    this.participantCount = 0,
    this.participants = const [],
    this.createdAt,
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
      type: json['type']?.toString() ?? 'reuniao',
      participantCount: _parseInt(json['participant_count']),
      participants: participants,
      createdAt: json['created_at']?.toString(),
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
