// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recent_activity_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RecentActivityModel _$RecentActivityModelFromJson(Map<String, dynamic> json) {
  return _RecentActivityModel.fromJson(json);
}

/// @nodoc
mixin _$RecentActivityModel {
  String get type => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get referenceId => throw _privateConstructorUsedError;

  /// Serializes this RecentActivityModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecentActivityModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecentActivityModelCopyWith<RecentActivityModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecentActivityModelCopyWith<$Res> {
  factory $RecentActivityModelCopyWith(
    RecentActivityModel value,
    $Res Function(RecentActivityModel) then,
  ) = _$RecentActivityModelCopyWithImpl<$Res, RecentActivityModel>;
  @useResult
  $Res call({
    String type,
    String title,
    String action,
    DateTime createdAt,
    String? referenceId,
  });
}

/// @nodoc
class _$RecentActivityModelCopyWithImpl<$Res, $Val extends RecentActivityModel>
    implements $RecentActivityModelCopyWith<$Res> {
  _$RecentActivityModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecentActivityModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? title = null,
    Object? action = null,
    Object? createdAt = null,
    Object? referenceId = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            action: null == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            referenceId: freezed == referenceId
                ? _value.referenceId
                : referenceId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecentActivityModelImplCopyWith<$Res>
    implements $RecentActivityModelCopyWith<$Res> {
  factory _$$RecentActivityModelImplCopyWith(
    _$RecentActivityModelImpl value,
    $Res Function(_$RecentActivityModelImpl) then,
  ) = __$$RecentActivityModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String type,
    String title,
    String action,
    DateTime createdAt,
    String? referenceId,
  });
}

/// @nodoc
class __$$RecentActivityModelImplCopyWithImpl<$Res>
    extends _$RecentActivityModelCopyWithImpl<$Res, _$RecentActivityModelImpl>
    implements _$$RecentActivityModelImplCopyWith<$Res> {
  __$$RecentActivityModelImplCopyWithImpl(
    _$RecentActivityModelImpl _value,
    $Res Function(_$RecentActivityModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecentActivityModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? title = null,
    Object? action = null,
    Object? createdAt = null,
    Object? referenceId = freezed,
  }) {
    return _then(
      _$RecentActivityModelImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        action: null == action
            ? _value.action
            : action // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        referenceId: freezed == referenceId
            ? _value.referenceId
            : referenceId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecentActivityModelImpl implements _RecentActivityModel {
  const _$RecentActivityModelImpl({
    required this.type,
    required this.title,
    required this.action,
    required this.createdAt,
    this.referenceId,
  });

  factory _$RecentActivityModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecentActivityModelImplFromJson(json);

  @override
  final String type;
  @override
  final String title;
  @override
  final String action;
  @override
  final DateTime createdAt;
  @override
  final String? referenceId;

  @override
  String toString() {
    return 'RecentActivityModel(type: $type, title: $title, action: $action, createdAt: $createdAt, referenceId: $referenceId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecentActivityModelImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, title, action, createdAt, referenceId);

  /// Create a copy of RecentActivityModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecentActivityModelImplCopyWith<_$RecentActivityModelImpl> get copyWith =>
      __$$RecentActivityModelImplCopyWithImpl<_$RecentActivityModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RecentActivityModelImplToJson(this);
  }
}

abstract class _RecentActivityModel implements RecentActivityModel {
  const factory _RecentActivityModel({
    required final String type,
    required final String title,
    required final String action,
    required final DateTime createdAt,
    final String? referenceId,
  }) = _$RecentActivityModelImpl;

  factory _RecentActivityModel.fromJson(Map<String, dynamic> json) =
      _$RecentActivityModelImpl.fromJson;

  @override
  String get type;
  @override
  String get title;
  @override
  String get action;
  @override
  DateTime get createdAt;
  @override
  String? get referenceId;

  /// Create a copy of RecentActivityModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecentActivityModelImplCopyWith<_$RecentActivityModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
