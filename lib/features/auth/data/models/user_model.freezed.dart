// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  @JsonKey(fromJson: _parseId)
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;
  String? get tenant =>
      throw _privateConstructorUsedError; // Campos opcionais que podem vir da API
  String? get telefone => throw _privateConstructorUsedError;
  String? get cpf => throw _privateConstructorUsedError;
  @JsonKey(name: 'tenant_id')
  String? get tenantId => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool? get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  Map<String, dynamic>? get permissions => throw _privateConstructorUsedError;
  Map<String, dynamic>? get preferences => throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _parseId) int id,
    String name,
    String email,
    String role,
    String? avatar,
    String? tenant,
    String? telefone,
    String? cpf,
    @JsonKey(name: 'tenant_id') String? tenantId,
    @JsonKey(name: 'is_active') bool? isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    Map<String, dynamic>? permissions,
    Map<String, dynamic>? preferences,
  });
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
    Object? role = null,
    Object? avatar = freezed,
    Object? tenant = freezed,
    Object? telefone = freezed,
    Object? cpf = freezed,
    Object? tenantId = freezed,
    Object? isActive = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? permissions = freezed,
    Object? preferences = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
            avatar: freezed == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                      as String?,
            tenant: freezed == tenant
                ? _value.tenant
                : tenant // ignore: cast_nullable_to_non_nullable
                      as String?,
            telefone: freezed == telefone
                ? _value.telefone
                : telefone // ignore: cast_nullable_to_non_nullable
                      as String?,
            cpf: freezed == cpf
                ? _value.cpf
                : cpf // ignore: cast_nullable_to_non_nullable
                      as String?,
            tenantId: freezed == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                      as String?,
            isActive: freezed == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            permissions: freezed == permissions
                ? _value.permissions
                : permissions // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            preferences: freezed == preferences
                ? _value.preferences
                : preferences // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
    _$UserModelImpl value,
    $Res Function(_$UserModelImpl) then,
  ) = __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _parseId) int id,
    String name,
    String email,
    String role,
    String? avatar,
    String? tenant,
    String? telefone,
    String? cpf,
    @JsonKey(name: 'tenant_id') String? tenantId,
    @JsonKey(name: 'is_active') bool? isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    Map<String, dynamic>? permissions,
    Map<String, dynamic>? preferences,
  });
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
    _$UserModelImpl _value,
    $Res Function(_$UserModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
    Object? role = null,
    Object? avatar = freezed,
    Object? tenant = freezed,
    Object? telefone = freezed,
    Object? cpf = freezed,
    Object? tenantId = freezed,
    Object? isActive = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? permissions = freezed,
    Object? preferences = freezed,
  }) {
    return _then(
      _$UserModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        avatar: freezed == avatar
            ? _value.avatar
            : avatar // ignore: cast_nullable_to_non_nullable
                  as String?,
        tenant: freezed == tenant
            ? _value.tenant
            : tenant // ignore: cast_nullable_to_non_nullable
                  as String?,
        telefone: freezed == telefone
            ? _value.telefone
            : telefone // ignore: cast_nullable_to_non_nullable
                  as String?,
        cpf: freezed == cpf
            ? _value.cpf
            : cpf // ignore: cast_nullable_to_non_nullable
                  as String?,
        tenantId: freezed == tenantId
            ? _value.tenantId
            : tenantId // ignore: cast_nullable_to_non_nullable
                  as String?,
        isActive: freezed == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        permissions: freezed == permissions
            ? _value._permissions
            : permissions // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        preferences: freezed == preferences
            ? _value._preferences
            : preferences // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl({
    @JsonKey(fromJson: _parseId) required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.tenant,
    this.telefone,
    this.cpf,
    @JsonKey(name: 'tenant_id') this.tenantId,
    @JsonKey(name: 'is_active') this.isActive,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    final Map<String, dynamic>? permissions,
    final Map<String, dynamic>? preferences,
  }) : _permissions = permissions,
       _preferences = preferences;

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  @JsonKey(fromJson: _parseId)
  final int id;
  @override
  final String name;
  @override
  final String email;
  @override
  final String role;
  @override
  final String? avatar;
  @override
  final String? tenant;
  // Campos opcionais que podem vir da API
  @override
  final String? telefone;
  @override
  final String? cpf;
  @override
  @JsonKey(name: 'tenant_id')
  final String? tenantId;
  @override
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final Map<String, dynamic>? _permissions;
  @override
  Map<String, dynamic>? get permissions {
    final value = _permissions;
    if (value == null) return null;
    if (_permissions is EqualUnmodifiableMapView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _preferences;
  @override
  Map<String, dynamic>? get preferences {
    final value = _preferences;
    if (value == null) return null;
    if (_preferences is EqualUnmodifiableMapView) return _preferences;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $role, avatar: $avatar, tenant: $tenant, telefone: $telefone, cpf: $cpf, tenantId: $tenantId, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, permissions: $permissions, preferences: $preferences)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.tenant, tenant) || other.tenant == tenant) &&
            (identical(other.telefone, telefone) ||
                other.telefone == telefone) &&
            (identical(other.cpf, cpf) || other.cpf == cpf) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(
              other._permissions,
              _permissions,
            ) &&
            const DeepCollectionEquality().equals(
              other._preferences,
              _preferences,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    email,
    role,
    avatar,
    tenant,
    telefone,
    cpf,
    tenantId,
    isActive,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_permissions),
    const DeepCollectionEquality().hash(_preferences),
  );

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(this);
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel({
    @JsonKey(fromJson: _parseId) required final int id,
    required final String name,
    required final String email,
    required final String role,
    final String? avatar,
    final String? tenant,
    final String? telefone,
    final String? cpf,
    @JsonKey(name: 'tenant_id') final String? tenantId,
    @JsonKey(name: 'is_active') final bool? isActive,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
    final Map<String, dynamic>? permissions,
    final Map<String, dynamic>? preferences,
  }) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  @JsonKey(fromJson: _parseId)
  int get id;
  @override
  String get name;
  @override
  String get email;
  @override
  String get role;
  @override
  String? get avatar;
  @override
  String? get tenant; // Campos opcionais que podem vir da API
  @override
  String? get telefone;
  @override
  String? get cpf;
  @override
  @JsonKey(name: 'tenant_id')
  String? get tenantId;
  @override
  @JsonKey(name: 'is_active')
  bool? get isActive;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  Map<String, dynamic>? get permissions;
  @override
  Map<String, dynamic>? get preferences;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
