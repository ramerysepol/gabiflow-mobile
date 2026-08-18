// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_stats_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DashboardStatsModel {

 int get totalConstituents; int get newConstituentsToday; int get totalDemands; int get openDemands; int get resolvedDemandsToday; int get upcomingEvents; int get eventsThisWeek; int get messagestoday; int get messagesSent; List<RecentActivityModel> get recentActivities;
/// Create a copy of DashboardStatsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardStatsModelCopyWith<DashboardStatsModel> get copyWith => _$DashboardStatsModelCopyWithImpl<DashboardStatsModel>(this as DashboardStatsModel, _$identity);

  /// Serializes this DashboardStatsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardStatsModel&&(identical(other.totalConstituents, totalConstituents) || other.totalConstituents == totalConstituents)&&(identical(other.newConstituentsToday, newConstituentsToday) || other.newConstituentsToday == newConstituentsToday)&&(identical(other.totalDemands, totalDemands) || other.totalDemands == totalDemands)&&(identical(other.openDemands, openDemands) || other.openDemands == openDemands)&&(identical(other.resolvedDemandsToday, resolvedDemandsToday) || other.resolvedDemandsToday == resolvedDemandsToday)&&(identical(other.upcomingEvents, upcomingEvents) || other.upcomingEvents == upcomingEvents)&&(identical(other.eventsThisWeek, eventsThisWeek) || other.eventsThisWeek == eventsThisWeek)&&(identical(other.messagestoday, messagestoday) || other.messagestoday == messagestoday)&&(identical(other.messagesSent, messagesSent) || other.messagesSent == messagesSent)&&const DeepCollectionEquality().equals(other.recentActivities, recentActivities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalConstituents,newConstituentsToday,totalDemands,openDemands,resolvedDemandsToday,upcomingEvents,eventsThisWeek,messagestoday,messagesSent,const DeepCollectionEquality().hash(recentActivities));

@override
String toString() {
  return 'DashboardStatsModel(totalConstituents: $totalConstituents, newConstituentsToday: $newConstituentsToday, totalDemands: $totalDemands, openDemands: $openDemands, resolvedDemandsToday: $resolvedDemandsToday, upcomingEvents: $upcomingEvents, eventsThisWeek: $eventsThisWeek, messagestoday: $messagestoday, messagesSent: $messagesSent, recentActivities: $recentActivities)';
}


}

/// @nodoc
abstract mixin class $DashboardStatsModelCopyWith<$Res>  {
  factory $DashboardStatsModelCopyWith(DashboardStatsModel value, $Res Function(DashboardStatsModel) _then) = _$DashboardStatsModelCopyWithImpl;
@useResult
$Res call({
 int totalConstituents, int newConstituentsToday, int totalDemands, int openDemands, int resolvedDemandsToday, int upcomingEvents, int eventsThisWeek, int messagestoday, int messagesSent, List<RecentActivityModel> recentActivities
});




}
/// @nodoc
class _$DashboardStatsModelCopyWithImpl<$Res>
    implements $DashboardStatsModelCopyWith<$Res> {
  _$DashboardStatsModelCopyWithImpl(this._self, this._then);

  final DashboardStatsModel _self;
  final $Res Function(DashboardStatsModel) _then;

/// Create a copy of DashboardStatsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalConstituents = null,Object? newConstituentsToday = null,Object? totalDemands = null,Object? openDemands = null,Object? resolvedDemandsToday = null,Object? upcomingEvents = null,Object? eventsThisWeek = null,Object? messagestoday = null,Object? messagesSent = null,Object? recentActivities = null,}) {
  return _then(_self.copyWith(
totalConstituents: null == totalConstituents ? _self.totalConstituents : totalConstituents // ignore: cast_nullable_to_non_nullable
as int,newConstituentsToday: null == newConstituentsToday ? _self.newConstituentsToday : newConstituentsToday // ignore: cast_nullable_to_non_nullable
as int,totalDemands: null == totalDemands ? _self.totalDemands : totalDemands // ignore: cast_nullable_to_non_nullable
as int,openDemands: null == openDemands ? _self.openDemands : openDemands // ignore: cast_nullable_to_non_nullable
as int,resolvedDemandsToday: null == resolvedDemandsToday ? _self.resolvedDemandsToday : resolvedDemandsToday // ignore: cast_nullable_to_non_nullable
as int,upcomingEvents: null == upcomingEvents ? _self.upcomingEvents : upcomingEvents // ignore: cast_nullable_to_non_nullable
as int,eventsThisWeek: null == eventsThisWeek ? _self.eventsThisWeek : eventsThisWeek // ignore: cast_nullable_to_non_nullable
as int,messagestoday: null == messagestoday ? _self.messagestoday : messagestoday // ignore: cast_nullable_to_non_nullable
as int,messagesSent: null == messagesSent ? _self.messagesSent : messagesSent // ignore: cast_nullable_to_non_nullable
as int,recentActivities: null == recentActivities ? _self.recentActivities : recentActivities // ignore: cast_nullable_to_non_nullable
as List<RecentActivityModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardStatsModel].
extension DashboardStatsModelPatterns on DashboardStatsModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardStatsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardStatsModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardStatsModel value)  $default,){
final _that = this;
switch (_that) {
case _DashboardStatsModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardStatsModel value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardStatsModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalConstituents,  int newConstituentsToday,  int totalDemands,  int openDemands,  int resolvedDemandsToday,  int upcomingEvents,  int eventsThisWeek,  int messagestoday,  int messagesSent,  List<RecentActivityModel> recentActivities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardStatsModel() when $default != null:
return $default(_that.totalConstituents,_that.newConstituentsToday,_that.totalDemands,_that.openDemands,_that.resolvedDemandsToday,_that.upcomingEvents,_that.eventsThisWeek,_that.messagestoday,_that.messagesSent,_that.recentActivities);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalConstituents,  int newConstituentsToday,  int totalDemands,  int openDemands,  int resolvedDemandsToday,  int upcomingEvents,  int eventsThisWeek,  int messagestoday,  int messagesSent,  List<RecentActivityModel> recentActivities)  $default,) {final _that = this;
switch (_that) {
case _DashboardStatsModel():
return $default(_that.totalConstituents,_that.newConstituentsToday,_that.totalDemands,_that.openDemands,_that.resolvedDemandsToday,_that.upcomingEvents,_that.eventsThisWeek,_that.messagestoday,_that.messagesSent,_that.recentActivities);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalConstituents,  int newConstituentsToday,  int totalDemands,  int openDemands,  int resolvedDemandsToday,  int upcomingEvents,  int eventsThisWeek,  int messagestoday,  int messagesSent,  List<RecentActivityModel> recentActivities)?  $default,) {final _that = this;
switch (_that) {
case _DashboardStatsModel() when $default != null:
return $default(_that.totalConstituents,_that.newConstituentsToday,_that.totalDemands,_that.openDemands,_that.resolvedDemandsToday,_that.upcomingEvents,_that.eventsThisWeek,_that.messagestoday,_that.messagesSent,_that.recentActivities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardStatsModel implements DashboardStatsModel {
  const _DashboardStatsModel({required this.totalConstituents, required this.newConstituentsToday, required this.totalDemands, required this.openDemands, required this.resolvedDemandsToday, required this.upcomingEvents, required this.eventsThisWeek, required this.messagestoday, required this.messagesSent, final  List<RecentActivityModel> recentActivities = const []}): _recentActivities = recentActivities;
  factory _DashboardStatsModel.fromJson(Map<String, dynamic> json) => _$DashboardStatsModelFromJson(json);

@override final  int totalConstituents;
@override final  int newConstituentsToday;
@override final  int totalDemands;
@override final  int openDemands;
@override final  int resolvedDemandsToday;
@override final  int upcomingEvents;
@override final  int eventsThisWeek;
@override final  int messagestoday;
@override final  int messagesSent;
 final  List<RecentActivityModel> _recentActivities;
@override@JsonKey() List<RecentActivityModel> get recentActivities {
  if (_recentActivities is EqualUnmodifiableListView) return _recentActivities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentActivities);
}


/// Create a copy of DashboardStatsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardStatsModelCopyWith<_DashboardStatsModel> get copyWith => __$DashboardStatsModelCopyWithImpl<_DashboardStatsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardStatsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardStatsModel&&(identical(other.totalConstituents, totalConstituents) || other.totalConstituents == totalConstituents)&&(identical(other.newConstituentsToday, newConstituentsToday) || other.newConstituentsToday == newConstituentsToday)&&(identical(other.totalDemands, totalDemands) || other.totalDemands == totalDemands)&&(identical(other.openDemands, openDemands) || other.openDemands == openDemands)&&(identical(other.resolvedDemandsToday, resolvedDemandsToday) || other.resolvedDemandsToday == resolvedDemandsToday)&&(identical(other.upcomingEvents, upcomingEvents) || other.upcomingEvents == upcomingEvents)&&(identical(other.eventsThisWeek, eventsThisWeek) || other.eventsThisWeek == eventsThisWeek)&&(identical(other.messagestoday, messagestoday) || other.messagestoday == messagestoday)&&(identical(other.messagesSent, messagesSent) || other.messagesSent == messagesSent)&&const DeepCollectionEquality().equals(other._recentActivities, _recentActivities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalConstituents,newConstituentsToday,totalDemands,openDemands,resolvedDemandsToday,upcomingEvents,eventsThisWeek,messagestoday,messagesSent,const DeepCollectionEquality().hash(_recentActivities));

@override
String toString() {
  return 'DashboardStatsModel(totalConstituents: $totalConstituents, newConstituentsToday: $newConstituentsToday, totalDemands: $totalDemands, openDemands: $openDemands, resolvedDemandsToday: $resolvedDemandsToday, upcomingEvents: $upcomingEvents, eventsThisWeek: $eventsThisWeek, messagestoday: $messagestoday, messagesSent: $messagesSent, recentActivities: $recentActivities)';
}


}

/// @nodoc
abstract mixin class _$DashboardStatsModelCopyWith<$Res> implements $DashboardStatsModelCopyWith<$Res> {
  factory _$DashboardStatsModelCopyWith(_DashboardStatsModel value, $Res Function(_DashboardStatsModel) _then) = __$DashboardStatsModelCopyWithImpl;
@override @useResult
$Res call({
 int totalConstituents, int newConstituentsToday, int totalDemands, int openDemands, int resolvedDemandsToday, int upcomingEvents, int eventsThisWeek, int messagestoday, int messagesSent, List<RecentActivityModel> recentActivities
});




}
/// @nodoc
class __$DashboardStatsModelCopyWithImpl<$Res>
    implements _$DashboardStatsModelCopyWith<$Res> {
  __$DashboardStatsModelCopyWithImpl(this._self, this._then);

  final _DashboardStatsModel _self;
  final $Res Function(_DashboardStatsModel) _then;

/// Create a copy of DashboardStatsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalConstituents = null,Object? newConstituentsToday = null,Object? totalDemands = null,Object? openDemands = null,Object? resolvedDemandsToday = null,Object? upcomingEvents = null,Object? eventsThisWeek = null,Object? messagestoday = null,Object? messagesSent = null,Object? recentActivities = null,}) {
  return _then(_DashboardStatsModel(
totalConstituents: null == totalConstituents ? _self.totalConstituents : totalConstituents // ignore: cast_nullable_to_non_nullable
as int,newConstituentsToday: null == newConstituentsToday ? _self.newConstituentsToday : newConstituentsToday // ignore: cast_nullable_to_non_nullable
as int,totalDemands: null == totalDemands ? _self.totalDemands : totalDemands // ignore: cast_nullable_to_non_nullable
as int,openDemands: null == openDemands ? _self.openDemands : openDemands // ignore: cast_nullable_to_non_nullable
as int,resolvedDemandsToday: null == resolvedDemandsToday ? _self.resolvedDemandsToday : resolvedDemandsToday // ignore: cast_nullable_to_non_nullable
as int,upcomingEvents: null == upcomingEvents ? _self.upcomingEvents : upcomingEvents // ignore: cast_nullable_to_non_nullable
as int,eventsThisWeek: null == eventsThisWeek ? _self.eventsThisWeek : eventsThisWeek // ignore: cast_nullable_to_non_nullable
as int,messagestoday: null == messagestoday ? _self.messagestoday : messagestoday // ignore: cast_nullable_to_non_nullable
as int,messagesSent: null == messagesSent ? _self.messagesSent : messagesSent // ignore: cast_nullable_to_non_nullable
as int,recentActivities: null == recentActivities ? _self._recentActivities : recentActivities // ignore: cast_nullable_to_non_nullable
as List<RecentActivityModel>,
  ));
}


}

// dart format on
