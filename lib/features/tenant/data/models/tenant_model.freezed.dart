// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tenant_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TenantModel _$TenantModelFromJson(Map<String, dynamic> json) {
  return _TenantModel.fromJson(json);
}

/// @nodoc
mixin _$TenantModel {
  int get id => throw _privateConstructorUsedError;
  String get nome => throw _privateConstructorUsedError;
  String get subdomain => throw _privateConstructorUsedError;
  @JsonKey(name: 'razao_social')
  String get razaoSocial => throw _privateConstructorUsedError;
  String get cnpj => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get telefone => throw _privateConstructorUsedError;
  String? get endereco => throw _privateConstructorUsedError;
  String? get cidade => throw _privateConstructorUsedError;
  String? get estado => throw _privateConstructorUsedError;
  String? get cep => throw _privateConstructorUsedError;
  bool get ativo => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError; // Configurações específicas
  Map<String, dynamic>? get configuracoes =>
      throw _privateConstructorUsedError; // URLs e endpoints
  @JsonKey(name: 'logo_url')
  String? get logoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'website_url')
  String? get websiteUrl => throw _privateConstructorUsedError; // Cores do tema
  @JsonKey(name: 'primary_color')
  String? get primaryColor => throw _privateConstructorUsedError;
  @JsonKey(name: 'secondary_color')
  String? get secondaryColor => throw _privateConstructorUsedError;

  /// Serializes this TenantModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TenantModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TenantModelCopyWith<TenantModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TenantModelCopyWith<$Res> {
  factory $TenantModelCopyWith(
    TenantModel value,
    $Res Function(TenantModel) then,
  ) = _$TenantModelCopyWithImpl<$Res, TenantModel>;
  @useResult
  $Res call({
    int id,
    String nome,
    String subdomain,
    @JsonKey(name: 'razao_social') String razaoSocial,
    String cnpj,
    String? email,
    String? telefone,
    String? endereco,
    String? cidade,
    String? estado,
    String? cep,
    bool ativo,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    Map<String, dynamic>? configuracoes,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'website_url') String? websiteUrl,
    @JsonKey(name: 'primary_color') String? primaryColor,
    @JsonKey(name: 'secondary_color') String? secondaryColor,
  });
}

/// @nodoc
class _$TenantModelCopyWithImpl<$Res, $Val extends TenantModel>
    implements $TenantModelCopyWith<$Res> {
  _$TenantModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TenantModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nome = null,
    Object? subdomain = null,
    Object? razaoSocial = null,
    Object? cnpj = null,
    Object? email = freezed,
    Object? telefone = freezed,
    Object? endereco = freezed,
    Object? cidade = freezed,
    Object? estado = freezed,
    Object? cep = freezed,
    Object? ativo = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? configuracoes = freezed,
    Object? logoUrl = freezed,
    Object? websiteUrl = freezed,
    Object? primaryColor = freezed,
    Object? secondaryColor = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            nome: null == nome
                ? _value.nome
                : nome // ignore: cast_nullable_to_non_nullable
                      as String,
            subdomain: null == subdomain
                ? _value.subdomain
                : subdomain // ignore: cast_nullable_to_non_nullable
                      as String,
            razaoSocial: null == razaoSocial
                ? _value.razaoSocial
                : razaoSocial // ignore: cast_nullable_to_non_nullable
                      as String,
            cnpj: null == cnpj
                ? _value.cnpj
                : cnpj // ignore: cast_nullable_to_non_nullable
                      as String,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            telefone: freezed == telefone
                ? _value.telefone
                : telefone // ignore: cast_nullable_to_non_nullable
                      as String?,
            endereco: freezed == endereco
                ? _value.endereco
                : endereco // ignore: cast_nullable_to_non_nullable
                      as String?,
            cidade: freezed == cidade
                ? _value.cidade
                : cidade // ignore: cast_nullable_to_non_nullable
                      as String?,
            estado: freezed == estado
                ? _value.estado
                : estado // ignore: cast_nullable_to_non_nullable
                      as String?,
            cep: freezed == cep
                ? _value.cep
                : cep // ignore: cast_nullable_to_non_nullable
                      as String?,
            ativo: null == ativo
                ? _value.ativo
                : ativo // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            configuracoes: freezed == configuracoes
                ? _value.configuracoes
                : configuracoes // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            logoUrl: freezed == logoUrl
                ? _value.logoUrl
                : logoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            websiteUrl: freezed == websiteUrl
                ? _value.websiteUrl
                : websiteUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            primaryColor: freezed == primaryColor
                ? _value.primaryColor
                : primaryColor // ignore: cast_nullable_to_non_nullable
                      as String?,
            secondaryColor: freezed == secondaryColor
                ? _value.secondaryColor
                : secondaryColor // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TenantModelImplCopyWith<$Res>
    implements $TenantModelCopyWith<$Res> {
  factory _$$TenantModelImplCopyWith(
    _$TenantModelImpl value,
    $Res Function(_$TenantModelImpl) then,
  ) = __$$TenantModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String nome,
    String subdomain,
    @JsonKey(name: 'razao_social') String razaoSocial,
    String cnpj,
    String? email,
    String? telefone,
    String? endereco,
    String? cidade,
    String? estado,
    String? cep,
    bool ativo,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    Map<String, dynamic>? configuracoes,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'website_url') String? websiteUrl,
    @JsonKey(name: 'primary_color') String? primaryColor,
    @JsonKey(name: 'secondary_color') String? secondaryColor,
  });
}

/// @nodoc
class __$$TenantModelImplCopyWithImpl<$Res>
    extends _$TenantModelCopyWithImpl<$Res, _$TenantModelImpl>
    implements _$$TenantModelImplCopyWith<$Res> {
  __$$TenantModelImplCopyWithImpl(
    _$TenantModelImpl _value,
    $Res Function(_$TenantModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TenantModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nome = null,
    Object? subdomain = null,
    Object? razaoSocial = null,
    Object? cnpj = null,
    Object? email = freezed,
    Object? telefone = freezed,
    Object? endereco = freezed,
    Object? cidade = freezed,
    Object? estado = freezed,
    Object? cep = freezed,
    Object? ativo = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? configuracoes = freezed,
    Object? logoUrl = freezed,
    Object? websiteUrl = freezed,
    Object? primaryColor = freezed,
    Object? secondaryColor = freezed,
  }) {
    return _then(
      _$TenantModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        nome: null == nome
            ? _value.nome
            : nome // ignore: cast_nullable_to_non_nullable
                  as String,
        subdomain: null == subdomain
            ? _value.subdomain
            : subdomain // ignore: cast_nullable_to_non_nullable
                  as String,
        razaoSocial: null == razaoSocial
            ? _value.razaoSocial
            : razaoSocial // ignore: cast_nullable_to_non_nullable
                  as String,
        cnpj: null == cnpj
            ? _value.cnpj
            : cnpj // ignore: cast_nullable_to_non_nullable
                  as String,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        telefone: freezed == telefone
            ? _value.telefone
            : telefone // ignore: cast_nullable_to_non_nullable
                  as String?,
        endereco: freezed == endereco
            ? _value.endereco
            : endereco // ignore: cast_nullable_to_non_nullable
                  as String?,
        cidade: freezed == cidade
            ? _value.cidade
            : cidade // ignore: cast_nullable_to_non_nullable
                  as String?,
        estado: freezed == estado
            ? _value.estado
            : estado // ignore: cast_nullable_to_non_nullable
                  as String?,
        cep: freezed == cep
            ? _value.cep
            : cep // ignore: cast_nullable_to_non_nullable
                  as String?,
        ativo: null == ativo
            ? _value.ativo
            : ativo // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        configuracoes: freezed == configuracoes
            ? _value._configuracoes
            : configuracoes // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        logoUrl: freezed == logoUrl
            ? _value.logoUrl
            : logoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        websiteUrl: freezed == websiteUrl
            ? _value.websiteUrl
            : websiteUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        primaryColor: freezed == primaryColor
            ? _value.primaryColor
            : primaryColor // ignore: cast_nullable_to_non_nullable
                  as String?,
        secondaryColor: freezed == secondaryColor
            ? _value.secondaryColor
            : secondaryColor // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TenantModelImpl implements _TenantModel {
  const _$TenantModelImpl({
    required this.id,
    required this.nome,
    required this.subdomain,
    @JsonKey(name: 'razao_social') required this.razaoSocial,
    required this.cnpj,
    this.email,
    this.telefone,
    this.endereco,
    this.cidade,
    this.estado,
    this.cep,
    required this.ativo,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    final Map<String, dynamic>? configuracoes,
    @JsonKey(name: 'logo_url') this.logoUrl,
    @JsonKey(name: 'website_url') this.websiteUrl,
    @JsonKey(name: 'primary_color') this.primaryColor,
    @JsonKey(name: 'secondary_color') this.secondaryColor,
  }) : _configuracoes = configuracoes;

  factory _$TenantModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TenantModelImplFromJson(json);

  @override
  final int id;
  @override
  final String nome;
  @override
  final String subdomain;
  @override
  @JsonKey(name: 'razao_social')
  final String razaoSocial;
  @override
  final String cnpj;
  @override
  final String? email;
  @override
  final String? telefone;
  @override
  final String? endereco;
  @override
  final String? cidade;
  @override
  final String? estado;
  @override
  final String? cep;
  @override
  final bool ativo;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  // Configurações específicas
  final Map<String, dynamic>? _configuracoes;
  // Configurações específicas
  @override
  Map<String, dynamic>? get configuracoes {
    final value = _configuracoes;
    if (value == null) return null;
    if (_configuracoes is EqualUnmodifiableMapView) return _configuracoes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // URLs e endpoints
  @override
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @override
  @JsonKey(name: 'website_url')
  final String? websiteUrl;
  // Cores do tema
  @override
  @JsonKey(name: 'primary_color')
  final String? primaryColor;
  @override
  @JsonKey(name: 'secondary_color')
  final String? secondaryColor;

  @override
  String toString() {
    return 'TenantModel(id: $id, nome: $nome, subdomain: $subdomain, razaoSocial: $razaoSocial, cnpj: $cnpj, email: $email, telefone: $telefone, endereco: $endereco, cidade: $cidade, estado: $estado, cep: $cep, ativo: $ativo, createdAt: $createdAt, updatedAt: $updatedAt, configuracoes: $configuracoes, logoUrl: $logoUrl, websiteUrl: $websiteUrl, primaryColor: $primaryColor, secondaryColor: $secondaryColor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TenantModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nome, nome) || other.nome == nome) &&
            (identical(other.subdomain, subdomain) ||
                other.subdomain == subdomain) &&
            (identical(other.razaoSocial, razaoSocial) ||
                other.razaoSocial == razaoSocial) &&
            (identical(other.cnpj, cnpj) || other.cnpj == cnpj) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.telefone, telefone) ||
                other.telefone == telefone) &&
            (identical(other.endereco, endereco) ||
                other.endereco == endereco) &&
            (identical(other.cidade, cidade) || other.cidade == cidade) &&
            (identical(other.estado, estado) || other.estado == estado) &&
            (identical(other.cep, cep) || other.cep == cep) &&
            (identical(other.ativo, ativo) || other.ativo == ativo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(
              other._configuracoes,
              _configuracoes,
            ) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.websiteUrl, websiteUrl) ||
                other.websiteUrl == websiteUrl) &&
            (identical(other.primaryColor, primaryColor) ||
                other.primaryColor == primaryColor) &&
            (identical(other.secondaryColor, secondaryColor) ||
                other.secondaryColor == secondaryColor));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    nome,
    subdomain,
    razaoSocial,
    cnpj,
    email,
    telefone,
    endereco,
    cidade,
    estado,
    cep,
    ativo,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_configuracoes),
    logoUrl,
    websiteUrl,
    primaryColor,
    secondaryColor,
  ]);

  /// Create a copy of TenantModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TenantModelImplCopyWith<_$TenantModelImpl> get copyWith =>
      __$$TenantModelImplCopyWithImpl<_$TenantModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TenantModelImplToJson(this);
  }
}

abstract class _TenantModel implements TenantModel {
  const factory _TenantModel({
    required final int id,
    required final String nome,
    required final String subdomain,
    @JsonKey(name: 'razao_social') required final String razaoSocial,
    required final String cnpj,
    final String? email,
    final String? telefone,
    final String? endereco,
    final String? cidade,
    final String? estado,
    final String? cep,
    required final bool ativo,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
    final Map<String, dynamic>? configuracoes,
    @JsonKey(name: 'logo_url') final String? logoUrl,
    @JsonKey(name: 'website_url') final String? websiteUrl,
    @JsonKey(name: 'primary_color') final String? primaryColor,
    @JsonKey(name: 'secondary_color') final String? secondaryColor,
  }) = _$TenantModelImpl;

  factory _TenantModel.fromJson(Map<String, dynamic> json) =
      _$TenantModelImpl.fromJson;

  @override
  int get id;
  @override
  String get nome;
  @override
  String get subdomain;
  @override
  @JsonKey(name: 'razao_social')
  String get razaoSocial;
  @override
  String get cnpj;
  @override
  String? get email;
  @override
  String? get telefone;
  @override
  String? get endereco;
  @override
  String? get cidade;
  @override
  String? get estado;
  @override
  String? get cep;
  @override
  bool get ativo;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt; // Configurações específicas
  @override
  Map<String, dynamic>? get configuracoes; // URLs e endpoints
  @override
  @JsonKey(name: 'logo_url')
  String? get logoUrl;
  @override
  @JsonKey(name: 'website_url')
  String? get websiteUrl; // Cores do tema
  @override
  @JsonKey(name: 'primary_color')
  String? get primaryColor;
  @override
  @JsonKey(name: 'secondary_color')
  String? get secondaryColor;

  /// Create a copy of TenantModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TenantModelImplCopyWith<_$TenantModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
