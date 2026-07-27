import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/tenant.dart';

part 'tenant_model.freezed.dart';
part 'tenant_model.g.dart';

@freezed
class TenantModel with _$TenantModel {
  const factory TenantModel({
    required int id,
    required String nome,
    required String subdomain,
    @JsonKey(name: 'razao_social') required String razaoSocial,
    required String cnpj,
    String? email,
    String? telefone,
    String? endereco,
    String? cidade,
    String? estado,
    String? cep,
    required bool ativo,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    
    // Configurações específicas
    Map<String, dynamic>? configuracoes,
    
    // URLs e endpoints  
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'website_url') String? websiteUrl,
    
    // Cores do tema
    @JsonKey(name: 'primary_color') String? primaryColor,
    @JsonKey(name: 'secondary_color') String? secondaryColor,
  }) = _TenantModel;
  
  factory TenantModel.fromJson(Map<String, dynamic> json) =>
      _$TenantModelFromJson(json);
}

// Extension para converter para entidade
extension TenantModelX on TenantModel {
  Tenant toEntity() => Tenant(
    id: id,
    nome: nome,
    subdomain: subdomain,
    razaoSocial: razaoSocial,
    cnpj: cnpj,
    email: email,
    telefone: telefone,
    endereco: endereco,
    cidade: cidade,
    estado: estado,
    cep: cep,
    ativo: ativo,
    createdAt: createdAt,
    updatedAt: updatedAt,
    configuracoes: configuracoes,
    logoUrl: logoUrl,
    websiteUrl: websiteUrl,
    primaryColor: primaryColor,
    secondaryColor: secondaryColor,
  );
}