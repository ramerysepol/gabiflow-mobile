// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: _parseId(json['id']),
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String?,
      tenant: json['tenant'] as String?,
      telefone: json['telefone'] as String?,
      cpf: json['cpf'] as String?,
      tenantId: json['tenant_id'] as String?,
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      permissions: json['permissions'] == null
          ? const <String>[]
          : _parsePermissions(json['permissions']),
      preferences: json['preferences'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'avatar': instance.avatar,
      'tenant': instance.tenant,
      'telefone': instance.telefone,
      'cpf': instance.cpf,
      'tenant_id': instance.tenantId,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'permissions': instance.permissions,
      'preferences': instance.preferences,
    };
