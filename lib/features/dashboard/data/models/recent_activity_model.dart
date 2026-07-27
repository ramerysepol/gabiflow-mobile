import 'package:freezed_annotation/freezed_annotation.dart';

part 'recent_activity_model.freezed.dart';
part 'recent_activity_model.g.dart';

@freezed
class RecentActivityModel with _$RecentActivityModel {
  const factory RecentActivityModel({
    required String type,
    required String title,
    required String action,
    required DateTime createdAt,
    String? referenceId,
  }) = _RecentActivityModel;

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) =>
      _$RecentActivityModelFromJson(json);
}

extension RecentActivityModelX on RecentActivityModel {
  String get displayTitle {
    switch (type) {
      case 'constituent_created':
        return 'Novo munícipe cadastrado';
      case 'demand_resolved':
        return 'Demanda resolvida';
      case 'event_created':
        return 'Evento agendado';
      default:
        return 'Atividade';
    }
  }
  
  String get displaySubtitle {
    switch (type) {
      case 'constituent_created':
        return '$title foi cadastrado(a)';
      case 'demand_resolved':
        return title;
      case 'event_created':
        return title;
      default:
        return title;
    }
  }
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} d';
    } else {
      return '${createdAt.day}/${createdAt.month}';
    }
  }
}