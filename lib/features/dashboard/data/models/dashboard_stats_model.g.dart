// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DashboardStatsModel _$DashboardStatsModelFromJson(Map<String, dynamic> json) =>
    _DashboardStatsModel(
      totalConstituents: (json['totalConstituents'] as num).toInt(),
      newConstituentsToday: (json['newConstituentsToday'] as num).toInt(),
      totalDemands: (json['totalDemands'] as num).toInt(),
      openDemands: (json['openDemands'] as num).toInt(),
      resolvedDemandsToday: (json['resolvedDemandsToday'] as num).toInt(),
      upcomingEvents: (json['upcomingEvents'] as num).toInt(),
      eventsThisWeek: (json['eventsThisWeek'] as num).toInt(),
      messagestoday: (json['messagestoday'] as num).toInt(),
      messagesSent: (json['messagesSent'] as num).toInt(),
      atendimentosRecebidosHoje:
          (json['atendimentosRecebidosHoje'] as num?)?.toInt() ?? 0,
      atendimentosAguardando:
          (json['atendimentosAguardando'] as num?)?.toInt() ?? 0,
      atendimentosEmAtendimento:
          (json['atendimentosEmAtendimento'] as num?)?.toInt() ?? 0,
      atendimentosAtendidosHoje:
          (json['atendimentosAtendidosHoje'] as num?)?.toInt() ?? 0,
      atendimentosArquivadosHoje:
          (json['atendimentosArquivadosHoje'] as num?)?.toInt() ?? 0,
      recentActivities:
          (json['recentActivities'] as List<dynamic>?)
              ?.map(
                (e) => RecentActivityModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DashboardStatsModelToJson(
  _DashboardStatsModel instance,
) => <String, dynamic>{
  'totalConstituents': instance.totalConstituents,
  'newConstituentsToday': instance.newConstituentsToday,
  'totalDemands': instance.totalDemands,
  'openDemands': instance.openDemands,
  'resolvedDemandsToday': instance.resolvedDemandsToday,
  'upcomingEvents': instance.upcomingEvents,
  'eventsThisWeek': instance.eventsThisWeek,
  'messagestoday': instance.messagestoday,
  'messagesSent': instance.messagesSent,
  'atendimentosRecebidosHoje': instance.atendimentosRecebidosHoje,
  'atendimentosAguardando': instance.atendimentosAguardando,
  'atendimentosEmAtendimento': instance.atendimentosEmAtendimento,
  'atendimentosAtendidosHoje': instance.atendimentosAtendidosHoje,
  'atendimentosArquivadosHoje': instance.atendimentosArquivadosHoje,
  'recentActivities': instance.recentActivities,
};
