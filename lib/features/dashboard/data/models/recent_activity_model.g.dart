// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_activity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecentActivityModelImpl _$$RecentActivityModelImplFromJson(
  Map<String, dynamic> json,
) => _$RecentActivityModelImpl(
  type: json['type'] as String,
  title: json['title'] as String,
  action: json['action'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  referenceId: json['referenceId'] as String?,
);

Map<String, dynamic> _$$RecentActivityModelImplToJson(
  _$RecentActivityModelImpl instance,
) => <String, dynamic>{
  'type': instance.type,
  'title': instance.title,
  'action': instance.action,
  'createdAt': instance.createdAt.toIso8601String(),
  'referenceId': instance.referenceId,
};
