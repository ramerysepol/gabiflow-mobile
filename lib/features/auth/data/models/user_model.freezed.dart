// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {

@JsonKey(fromJson: _parseId) int get id; String get name; String get email; String get role; String? get avatar; String? get tenant;// Campos opcionais que podem vir da API
 String? get telefone; String? get cpf;@JsonKey(name: 'tenant_id') String? get tenantId;@JsonKey(name: 'is_active') bool? get isActive;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(fromJson: _parsePermissions) List<String> get permissions;@JsonKey(fromJson: _parsePreferences) Map<String, dynamic>? get preferences;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.tenant, tenant) || other.tenant == tenant)&&(identical(other.telefone, telefone) || other.telefone == telefone)&&(identical(other.cpf, cpf) || other.cpf == cpf)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.permissions, permissions)&&const DeepCollectionEquality().equals(other.preferences, preferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,role,avatar,tenant,telefone,cpf,tenantId,isActive,createdAt,updatedAt,const DeepCollectionEquality().hash(permissions),const DeepCollectionEquality().hash(preferences));

@override
String toString() {
  return 'UserModel(id: $id, name: $name, email: $email, role: $role, avatar: $avatar, tenant: $tenant, telefone: $telefone, cpf: $cpf, tenantId: $tenantId, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, permissions: $permissions, preferences: $preferences)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _parseId) int id, String name, String email, String role, String? avatar, String? tenant, String? telefone, String? cpf,@JsonKey(name: 'tenant_id') String? tenantId,@JsonKey(name: 'is_active') bool? isActive,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(fromJson: _parsePermissions) List<String> permissions,@JsonKey(fromJson: _parsePreferences) Map<String, dynamic>? preferences
});




}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? role = null,Object? avatar = freezed,Object? tenant = freezed,Object? telefone = freezed,Object? cpf = freezed,Object? tenantId = freezed,Object? isActive = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? permissions = null,Object? preferences = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,tenant: freezed == tenant ? _self.tenant : tenant // ignore: cast_nullable_to_non_nullable
as String?,telefone: freezed == telefone ? _self.telefone : telefone // ignore: cast_nullable_to_non_nullable
as String?,cpf: freezed == cpf ? _self.cpf : cpf // ignore: cast_nullable_to_non_nullable
as String?,tenantId: freezed == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,preferences: freezed == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _parseId)  int id,  String name,  String email,  String role,  String? avatar,  String? tenant,  String? telefone,  String? cpf, @JsonKey(name: 'tenant_id')  String? tenantId, @JsonKey(name: 'is_active')  bool? isActive, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(fromJson: _parsePermissions)  List<String> permissions, @JsonKey(fromJson: _parsePreferences)  Map<String, dynamic>? preferences)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.role,_that.avatar,_that.tenant,_that.telefone,_that.cpf,_that.tenantId,_that.isActive,_that.createdAt,_that.updatedAt,_that.permissions,_that.preferences);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _parseId)  int id,  String name,  String email,  String role,  String? avatar,  String? tenant,  String? telefone,  String? cpf, @JsonKey(name: 'tenant_id')  String? tenantId, @JsonKey(name: 'is_active')  bool? isActive, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(fromJson: _parsePermissions)  List<String> permissions, @JsonKey(fromJson: _parsePreferences)  Map<String, dynamic>? preferences)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.id,_that.name,_that.email,_that.role,_that.avatar,_that.tenant,_that.telefone,_that.cpf,_that.tenantId,_that.isActive,_that.createdAt,_that.updatedAt,_that.permissions,_that.preferences);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _parseId)  int id,  String name,  String email,  String role,  String? avatar,  String? tenant,  String? telefone,  String? cpf, @JsonKey(name: 'tenant_id')  String? tenantId, @JsonKey(name: 'is_active')  bool? isActive, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(fromJson: _parsePermissions)  List<String> permissions, @JsonKey(fromJson: _parsePreferences)  Map<String, dynamic>? preferences)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.role,_that.avatar,_that.tenant,_that.telefone,_that.cpf,_that.tenantId,_that.isActive,_that.createdAt,_that.updatedAt,_that.permissions,_that.preferences);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserModel implements UserModel {
  const _UserModel({@JsonKey(fromJson: _parseId) required this.id, required this.name, required this.email, required this.role, this.avatar, this.tenant, this.telefone, this.cpf, @JsonKey(name: 'tenant_id') this.tenantId, @JsonKey(name: 'is_active') this.isActive, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(fromJson: _parsePermissions) final  List<String> permissions = const <String>[], @JsonKey(fromJson: _parsePreferences) final  Map<String, dynamic>? preferences}): _permissions = permissions,_preferences = preferences;
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override@JsonKey(fromJson: _parseId) final  int id;
@override final  String name;
@override final  String email;
@override final  String role;
@override final  String? avatar;
@override final  String? tenant;
// Campos opcionais que podem vir da API
@override final  String? telefone;
@override final  String? cpf;
@override@JsonKey(name: 'tenant_id') final  String? tenantId;
@override@JsonKey(name: 'is_active') final  bool? isActive;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
 final  List<String> _permissions;
@override@JsonKey(fromJson: _parsePermissions) List<String> get permissions {
  if (_permissions is EqualUnmodifiableListView) return _permissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_permissions);
}

 final  Map<String, dynamic>? _preferences;
@override@JsonKey(fromJson: _parsePreferences) Map<String, dynamic>? get preferences {
  final value = _preferences;
  if (value == null) return null;
  if (_preferences is EqualUnmodifiableMapView) return _preferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.tenant, tenant) || other.tenant == tenant)&&(identical(other.telefone, telefone) || other.telefone == telefone)&&(identical(other.cpf, cpf) || other.cpf == cpf)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._permissions, _permissions)&&const DeepCollectionEquality().equals(other._preferences, _preferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,role,avatar,tenant,telefone,cpf,tenantId,isActive,createdAt,updatedAt,const DeepCollectionEquality().hash(_permissions),const DeepCollectionEquality().hash(_preferences));

@override
String toString() {
  return 'UserModel(id: $id, name: $name, email: $email, role: $role, avatar: $avatar, tenant: $tenant, telefone: $telefone, cpf: $cpf, tenantId: $tenantId, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, permissions: $permissions, preferences: $preferences)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _parseId) int id, String name, String email, String role, String? avatar, String? tenant, String? telefone, String? cpf,@JsonKey(name: 'tenant_id') String? tenantId,@JsonKey(name: 'is_active') bool? isActive,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(fromJson: _parsePermissions) List<String> permissions,@JsonKey(fromJson: _parsePreferences) Map<String, dynamic>? preferences
});




}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? role = null,Object? avatar = freezed,Object? tenant = freezed,Object? telefone = freezed,Object? cpf = freezed,Object? tenantId = freezed,Object? isActive = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? permissions = null,Object? preferences = freezed,}) {
  return _then(_UserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,tenant: freezed == tenant ? _self.tenant : tenant // ignore: cast_nullable_to_non_nullable
as String?,telefone: freezed == telefone ? _self.telefone : telefone // ignore: cast_nullable_to_non_nullable
as String?,cpf: freezed == cpf ? _self.cpf : cpf // ignore: cast_nullable_to_non_nullable
as String?,tenantId: freezed == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,permissions: null == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,preferences: freezed == preferences ? _self._preferences : preferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
