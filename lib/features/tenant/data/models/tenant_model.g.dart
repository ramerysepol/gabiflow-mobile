// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TenantModelImpl _$$TenantModelImplFromJson(Map<String, dynamic> json) =>
    _$TenantModelImpl(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      subdomain: json['subdomain'] as String,
      razaoSocial: json['razao_social'] as String,
      cnpj: json['cnpj'] as String,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
      endereco: json['endereco'] as String?,
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
      cep: json['cep'] as String?,
      ativo: json['ativo'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      configuracoes: json['configuracoes'] as Map<String, dynamic>?,
      logoUrl: json['logo_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      primaryColor: json['primary_color'] as String?,
      secondaryColor: json['secondary_color'] as String?,
    );

Map<String, dynamic> _$$TenantModelImplToJson(_$TenantModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'subdomain': instance.subdomain,
      'razao_social': instance.razaoSocial,
      'cnpj': instance.cnpj,
      'email': instance.email,
      'telefone': instance.telefone,
      'endereco': instance.endereco,
      'cidade': instance.cidade,
      'estado': instance.estado,
      'cep': instance.cep,
      'ativo': instance.ativo,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'configuracoes': instance.configuracoes,
      'logo_url': instance.logoUrl,
      'website_url': instance.websiteUrl,
      'primary_color': instance.primaryColor,
      'secondary_color': instance.secondaryColor,
    };
