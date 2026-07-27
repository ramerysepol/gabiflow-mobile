import 'package:freezed_annotation/freezed_annotation.dart';
import 'recent_activity_model.dart';

part 'dashboard_stats_model.freezed.dart';
part 'dashboard_stats_model.g.dart';

@freezed
class DashboardStatsModel with _$DashboardStatsModel {
  const factory DashboardStatsModel({
    required int totalConstituents,
    required int newConstituentsToday,
    required int totalDemands,
    required int openDemands,
    required int resolvedDemandsToday,
    required int upcomingEvents,
    required int eventsThisWeek,
    required int messagestoday,
    required int messagesSent,
    @Default([]) List<RecentActivityModel> recentActivities,
  }) = _DashboardStatsModel;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsModelFromJson(json);
}