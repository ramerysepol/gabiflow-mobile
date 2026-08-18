// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tenant_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TenantModel {

 int get id; String get nome; String get subdomain;@JsonKey(name: 'razao_social') String get razaoSocial; String get cnpj; String? get email; String? get telefone; String? get endereco; String? get cidade; String? get estado; String? get cep; bool get ativo;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;// Configurações específicas
 Map<String, dynamic>? get configuracoes;// URLs e endpoints  
@JsonKey(name: 'logo_url') String? get logoUrl;@JsonKey(name: 'website_url') String? get websiteUrl;// Cores do tema
@JsonKey(name: 'primary_color') String? get primaryColor;@JsonKey(name: 'secondary_color') String? get secondaryColor;
/// Create a copy of TenantModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TenantModelCopyWith<TenantModel> get copyWith => _$TenantModelCopyWithImpl<TenantModel>(this as TenantModel, _$identity);

  /// Serializes this TenantModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TenantModel&&(identical(other.id, id) || other.id == id)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.subdomain, subdomain) || other.subdomain == subdomain)&&(identical(other.razaoSocial, razaoSocial) || other.razaoSocial == razaoSocial)&&(identical(other.cnpj, cnpj) || other.cnpj == cnpj)&&(identical(other.email, email) || other.email == email)&&(identical(other.telefone, telefone) || other.telefone == telefone)&&(identical(other.endereco, endereco) || other.endereco == endereco)&&(identical(other.cidade, cidade) || other.cidade == cidade)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.cep, cep) || other.cep == cep)&&(identical(other.ativo, ativo) || other.ativo == ativo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.configuracoes, configuracoes)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.websiteUrl, websiteUrl) || other.websiteUrl == websiteUrl)&&(identical(other.primaryColor, primaryColor) || other.primaryColor == primaryColor)&&(identical(other.secondaryColor, secondaryColor) || other.secondaryColor == secondaryColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,nome,subdomain,razaoSocial,cnpj,email,telefone,endereco,cidade,estado,cep,ativo,createdAt,updatedAt,const DeepCollectionEquality().hash(configuracoes),logoUrl,websiteUrl,primaryColor,secondaryColor]);

@override
String toString() {
  return 'TenantModel(id: $id, nome: $nome, subdomain: $subdomain, razaoSocial: $razaoSocial, cnpj: $cnpj, email: $email, telefone: $telefone, endereco: $endereco, cidade: $cidade, estado: $estado, cep: $cep, ativo: $ativo, createdAt: $createdAt, updatedAt: $updatedAt, configuracoes: $configuracoes, logoUrl: $logoUrl, websiteUrl: $websiteUrl, primaryColor: $primaryColor, secondaryColor: $secondaryColor)';
}


}

/// @nodoc
abstract mixin class $TenantModelCopyWith<$Res>  {
  factory $TenantModelCopyWith(TenantModel value, $Res Function(TenantModel) _then) = _$TenantModelCopyWithImpl;
@useResult
$Res call({
 int id, String nome, String subdomain,@JsonKey(name: 'razao_social') String razaoSocial, String cnpj, String? email, String? telefone, String? endereco, String? cidade, String? estado, String? cep, bool ativo,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt, Map<String, dynamic>? configuracoes,@JsonKey(name: 'logo_url') String? logoUrl,@JsonKey(name: 'website_url') String? websiteUrl,@JsonKey(name: 'primary_color') String? primaryColor,@JsonKey(name: 'secondary_color') String? secondaryColor
});




}
/// @nodoc
class _$TenantModelCopyWithImpl<$Res>
    implements $TenantModelCopyWith<$Res> {
  _$TenantModelCopyWithImpl(this._self, this._then);

  final TenantModel _self;
  final $Res Function(TenantModel) _then;

/// Create a copy of TenantModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nome = null,Object? subdomain = null,Object? razaoSocial = null,Object? cnpj = null,Object? email = freezed,Object? telefone = freezed,Object? endereco = freezed,Object? cidade = freezed,Object? estado = freezed,Object? cep = freezed,Object? ativo = null,Object? createdAt = null,Object? updatedAt = freezed,Object? configuracoes = freezed,Object? logoUrl = freezed,Object? websiteUrl = freezed,Object? primaryColor = freezed,Object? secondaryColor = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,subdomain: null == subdomain ? _self.subdomain : subdomain // ignore: cast_nullable_to_non_nullable
as String,razaoSocial: null == razaoSocial ? _self.razaoSocial : razaoSocial // ignore: cast_nullable_to_non_nullable
as String,cnpj: null == cnpj ? _self.cnpj : cnpj // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,telefone: freezed == telefone ? _self.telefone : telefone // ignore: cast_nullable_to_non_nullable
as String?,endereco: freezed == endereco ? _self.endereco : endereco // ignore: cast_nullable_to_non_nullable
as String?,cidade: freezed == cidade ? _self.cidade : cidade // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,cep: freezed == cep ? _self.cep : cep // ignore: cast_nullable_to_non_nullable
as String?,ativo: null == ativo ? _self.ativo : ativo // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,configuracoes: freezed == configuracoes ? _self.configuracoes : configuracoes // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,websiteUrl: freezed == websiteUrl ? _self.websiteUrl : websiteUrl // ignore: cast_nullable_to_non_nullable
as String?,primaryColor: freezed == primaryColor ? _self.primaryColor : primaryColor // ignore: cast_nullable_to_non_nullable
as String?,secondaryColor: freezed == secondaryColor ? _self.secondaryColor : secondaryColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TenantModel].
extension TenantModelPatterns on TenantModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TenantModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TenantModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TenantModel value)  $default,){
final _that = this;
switch (_that) {
case _TenantModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TenantModel value)?  $default,){
final _that = this;
switch (_that) {
case _TenantModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String nome,  String subdomain, @JsonKey(name: 'razao_social')  String razaoSocial,  String cnpj,  String? email,  String? telefone,  String? endereco,  String? cidade,  String? estado,  String? cep,  bool ativo, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt,  Map<String, dynamic>? configuracoes, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'website_url')  String? websiteUrl, @JsonKey(name: 'primary_color')  String? primaryColor, @JsonKey(name: 'secondary_color')  String? secondaryColor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TenantModel() when $default != null:
return $default(_that.id,_that.nome,_that.subdomain,_that.razaoSocial,_that.cnpj,_that.email,_that.telefone,_that.endereco,_that.cidade,_that.estado,_that.cep,_that.ativo,_that.createdAt,_that.updatedAt,_that.configuracoes,_that.logoUrl,_that.websiteUrl,_that.primaryColor,_that.secondaryColor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String nome,  String subdomain, @JsonKey(name: 'razao_social')  String razaoSocial,  String cnpj,  String? email,  String? telefone,  String? endereco,  String? cidade,  String? estado,  String? cep,  bool ativo, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt,  Map<String, dynamic>? configuracoes, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'website_url')  String? websiteUrl, @JsonKey(name: 'primary_color')  String? primaryColor, @JsonKey(name: 'secondary_color')  String? secondaryColor)  $default,) {final _that = this;
switch (_that) {
case _TenantModel():
return $default(_that.id,_that.nome,_that.subdomain,_that.razaoSocial,_that.cnpj,_that.email,_that.telefone,_that.endereco,_that.cidade,_that.estado,_that.cep,_that.ativo,_that.createdAt,_that.updatedAt,_that.configuracoes,_that.logoUrl,_that.websiteUrl,_that.primaryColor,_that.secondaryColor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String nome,  String subdomain, @JsonKey(name: 'razao_social')  String razaoSocial,  String cnpj,  String? email,  String? telefone,  String? endereco,  String? cidade,  String? estado,  String? cep,  bool ativo, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt,  Map<String, dynamic>? configuracoes, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'website_url')  String? websiteUrl, @JsonKey(name: 'primary_color')  String? primaryColor, @JsonKey(name: 'secondary_color')  String? secondaryColor)?  $default,) {final _that = this;
switch (_that) {
case _TenantModel() when $default != null:
return $default(_that.id,_that.nome,_that.subdomain,_that.razaoSocial,_that.cnpj,_that.email,_that.telefone,_that.endereco,_that.cidade,_that.estado,_that.cep,_that.ativo,_that.createdAt,_that.updatedAt,_that.configuracoes,_that.logoUrl,_that.websiteUrl,_that.primaryColor,_that.secondaryColor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TenantModel implements TenantModel {
  const _TenantModel({required this.id, required this.nome, required this.subdomain, @JsonKey(name: 'razao_social') required this.razaoSocial, required this.cnpj, this.email, this.telefone, this.endereco, this.cidade, this.estado, this.cep, required this.ativo, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, final  Map<String, dynamic>? configuracoes, @JsonKey(name: 'logo_url') this.logoUrl, @JsonKey(name: 'website_url') this.websiteUrl, @JsonKey(name: 'primary_color') this.primaryColor, @JsonKey(name: 'secondary_color') this.secondaryColor}): _configuracoes = configuracoes;
  factory _TenantModel.fromJson(Map<String, dynamic> json) => _$TenantModelFromJson(json);

@override final  int id;
@override final  String nome;
@override final  String subdomain;
@override@JsonKey(name: 'razao_social') final  String razaoSocial;
@override final  String cnpj;
@override final  String? email;
@override final  String? telefone;
@override final  String? endereco;
@override final  String? cidade;
@override final  String? estado;
@override final  String? cep;
@override final  bool ativo;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
// Configurações específicas
 final  Map<String, dynamic>? _configuracoes;
// Configurações específicas
@override Map<String, dynamic>? get configuracoes {
  final value = _configuracoes;
  if (value == null) return null;
  if (_configuracoes is EqualUnmodifiableMapView) return _configuracoes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// URLs e endpoints  
@override@JsonKey(name: 'logo_url') final  String? logoUrl;
@override@JsonKey(name: 'website_url') final  String? websiteUrl;
// Cores do tema
@override@JsonKey(name: 'primary_color') final  String? primaryColor;
@override@JsonKey(name: 'secondary_color') final  String? secondaryColor;

/// Create a copy of TenantModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TenantModelCopyWith<_TenantModel> get copyWith => __$TenantModelCopyWithImpl<_TenantModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TenantModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TenantModel&&(identical(other.id, id) || other.id == id)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.subdomain, subdomain) || other.subdomain == subdomain)&&(identical(other.razaoSocial, razaoSocial) || other.razaoSocial == razaoSocial)&&(identical(other.cnpj, cnpj) || other.cnpj == cnpj)&&(identical(other.email, email) || other.email == email)&&(identical(other.telefone, telefone) || other.telefone == telefone)&&(identical(other.endereco, endereco) || other.endereco == endereco)&&(identical(other.cidade, cidade) || other.cidade == cidade)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.cep, cep) || other.cep == cep)&&(identical(other.ativo, ativo) || other.ativo == ativo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._configuracoes, _configuracoes)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.websiteUrl, websiteUrl) || other.websiteUrl == websiteUrl)&&(identical(other.primaryColor, primaryColor) || other.primaryColor == primaryColor)&&(identical(other.secondaryColor, secondaryColor) || other.secondaryColor == secondaryColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,nome,subdomain,razaoSocial,cnpj,email,telefone,endereco,cidade,estado,cep,ativo,createdAt,updatedAt,const DeepCollectionEquality().hash(_configuracoes),logoUrl,websiteUrl,primaryColor,secondaryColor]);

@override
String toString() {
  return 'TenantModel(id: $id, nome: $nome, subdomain: $subdomain, razaoSocial: $razaoSocial, cnpj: $cnpj, email: $email, telefone: $telefone, endereco: $endereco, cidade: $cidade, estado: $estado, cep: $cep, ativo: $ativo, createdAt: $createdAt, updatedAt: $updatedAt, configuracoes: $configuracoes, logoUrl: $logoUrl, websiteUrl: $websiteUrl, primaryColor: $primaryColor, secondaryColor: $secondaryColor)';
}


}

/// @nodoc
abstract mixin class _$TenantModelCopyWith<$Res> implements $TenantModelCopyWith<$Res> {
  factory _$TenantModelCopyWith(_TenantModel value, $Res Function(_TenantModel) _then) = __$TenantModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String nome, String subdomain,@JsonKey(name: 'razao_social') String razaoSocial, String cnpj, String? email, String? telefone, String? endereco, String? cidade, String? estado, String? cep, bool ativo,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt, Map<String, dynamic>? configuracoes,@JsonKey(name: 'logo_url') String? logoUrl,@JsonKey(name: 'website_url') String? websiteUrl,@JsonKey(name: 'primary_color') String? primaryColor,@JsonKey(name: 'secondary_color') String? secondaryColor
});




}
/// @nodoc
class __$TenantModelCopyWithImpl<$Res>
    implements _$TenantModelCopyWith<$Res> {
  __$TenantModelCopyWithImpl(this._self, this._then);

  final _TenantModel _self;
  final $Res Function(_TenantModel) _then;

/// Create a copy of TenantModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nome = null,Object? subdomain = null,Object? razaoSocial = null,Object? cnpj = null,Object? email = freezed,Object? telefone = freezed,Object? endereco = freezed,Object? cidade = freezed,Object? estado = freezed,Object? cep = freezed,Object? ativo = null,Object? createdAt = null,Object? updatedAt = freezed,Object? configuracoes = freezed,Object? logoUrl = freezed,Object? websiteUrl = freezed,Object? primaryColor = freezed,Object? secondaryColor = freezed,}) {
  return _then(_TenantModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,subdomain: null == subdomain ? _self.subdomain : subdomain // ignore: cast_nullable_to_non_nullable
as String,razaoSocial: null == razaoSocial ? _self.razaoSocial : razaoSocial // ignore: cast_nullable_to_non_nullable
as String,cnpj: null == cnpj ? _self.cnpj : cnpj // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,telefone: freezed == telefone ? _self.telefone : telefone // ignore: cast_nullable_to_non_nullable
as String?,endereco: freezed == endereco ? _self.endereco : endereco // ignore: cast_nullable_to_non_nullable
as String?,cidade: freezed == cidade ? _self.cidade : cidade // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,cep: freezed == cep ? _self.cep : cep // ignore: cast_nullable_to_non_nullable
as String?,ativo: null == ativo ? _self.ativo : ativo // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,configuracoes: freezed == configuracoes ? _self._configuracoes : configuracoes // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,websiteUrl: freezed == websiteUrl ? _self.websiteUrl : websiteUrl // ignore: cast_nullable_to_non_nullable
as String?,primaryColor: freezed == primaryColor ? _self.primaryColor : primaryColor // ignore: cast_nullable_to_non_nullable
as String?,secondaryColor: freezed == secondaryColor ? _self.secondaryColor : secondaryColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
