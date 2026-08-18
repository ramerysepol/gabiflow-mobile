// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recent_activity_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecentActivityModel {

 String get type; String get title; String get action; DateTime get createdAt; String? get referenceId;
/// Create a copy of RecentActivityModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentActivityModelCopyWith<RecentActivityModel> get copyWith => _$RecentActivityModelCopyWithImpl<RecentActivityModel>(this as RecentActivityModel, _$identity);

  /// Serializes this RecentActivityModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentActivityModel&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.action, action) || other.action == action)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.referenceId, referenceId) || other.referenceId == referenceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,title,action,createdAt,referenceId);

@override
String toString() {
  return 'RecentActivityModel(type: $type, title: $title, action: $action, createdAt: $createdAt, referenceId: $referenceId)';
}


}

/// @nodoc
abstract mixin class $RecentActivityModelCopyWith<$Res>  {
  factory $RecentActivityModelCopyWith(RecentActivityModel value, $Res Function(RecentActivityModel) _then) = _$RecentActivityModelCopyWithImpl;
@useResult
$Res call({
 String type, String title, String action, DateTime createdAt, String? referenceId
});




}
/// @nodoc
class _$RecentActivityModelCopyWithImpl<$Res>
    implements $RecentActivityModelCopyWith<$Res> {
  _$RecentActivityModelCopyWithImpl(this._self, this._then);

  final RecentActivityModel _self;
  final $Res Function(RecentActivityModel) _then;

/// Create a copy of RecentActivityModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? title = null,Object? action = null,Object? createdAt = null,Object? referenceId = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,referenceId: freezed == referenceId ? _self.referenceId : referenceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentActivityModel].
extension RecentActivityModelPatterns on RecentActivityModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecentActivityModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecentActivityModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecentActivityModel value)  $default,){
final _that = this;
switch (_that) {
case _RecentActivityModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecentActivityModel value)?  $default,){
final _that = this;
switch (_that) {
case _RecentActivityModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String title,  String action,  DateTime createdAt,  String? referenceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecentActivityModel() when $default != null:
return $default(_that.type,_that.title,_that.action,_that.createdAt,_that.referenceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String title,  String action,  DateTime createdAt,  String? referenceId)  $default,) {final _that = this;
switch (_that) {
case _RecentActivityModel():
return $default(_that.type,_that.title,_that.action,_that.createdAt,_that.referenceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String title,  String action,  DateTime createdAt,  String? referenceId)?  $default,) {final _that = this;
switch (_that) {
case _RecentActivityModel() when $default != null:
return $default(_that.type,_that.title,_that.action,_that.createdAt,_that.referenceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecentActivityModel implements RecentActivityModel {
  const _RecentActivityModel({required this.type, required this.title, required this.action, required this.createdAt, this.referenceId});
  factory _RecentActivityModel.fromJson(Map<String, dynamic> json) => _$RecentActivityModelFromJson(json);

@override final  String type;
@override final  String title;
@override final  String action;
@override final  DateTime createdAt;
@override final  String? referenceId;

/// Create a copy of RecentActivityModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecentActivityModelCopyWith<_RecentActivityModel> get copyWith => __$RecentActivityModelCopyWithImpl<_RecentActivityModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecentActivityModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecentActivityModel&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.action, action) || other.action == action)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.referenceId, referenceId) || other.referenceId == referenceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,title,action,createdAt,referenceId);

@override
String toString() {
  return 'RecentActivityModel(type: $type, title: $title, action: $action, createdAt: $createdAt, referenceId: $referenceId)';
}


}

/// @nodoc
abstract mixin class _$RecentActivityModelCopyWith<$Res> implements $RecentActivityModelCopyWith<$Res> {
  factory _$RecentActivityModelCopyWith(_RecentActivityModel value, $Res Function(_RecentActivityModel) _then) = __$RecentActivityModelCopyWithImpl;
@override @useResult
$Res call({
 String type, String title, String action, DateTime createdAt, String? referenceId
});




}
/// @nodoc
class __$RecentActivityModelCopyWithImpl<$Res>
    implements _$RecentActivityModelCopyWith<$Res> {
  __$RecentActivityModelCopyWithImpl(this._self, this._then);

  final _RecentActivityModel _self;
  final $Res Function(_RecentActivityModel) _then;

/// Create a copy of RecentActivityModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? title = null,Object? action = null,Object? createdAt = null,Object? referenceId = freezed,}) {
  return _then(_RecentActivityModel(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,referenceId: freezed == referenceId ? _self.referenceId : referenceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
