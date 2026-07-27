/// Entidade Tenant
class Tenant {
  final int id;
  final String nome;
  final String subdomain;
  final String razaoSocial;
  final String cnpj;
  final String? email;
  final String? telefone;
  final String? endereco;
  final String? cidade;
  final String? estado;
  final String? cep;
  final bool ativo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Configurações específicas
  final Map<String, dynamic>? configuracoes;
  
  // URLs e endpoints
  final String? logoUrl;
  final String? websiteUrl;
  
  // Cores do tema
  final String? primaryColor;
  final String? secondaryColor;
  
  const Tenant({
    required this.id,
    required this.nome,
    required this.subdomain,
    required this.razaoSocial,
    required this.cnpj,
    this.email,
    this.telefone,
    this.endereco,
    this.cidade,
    this.estado,
    this.cep,
    required this.ativo,
    required this.createdAt,
    this.updatedAt,
    this.configuracoes,
    this.logoUrl,
    this.websiteUrl,
    this.primaryColor,
    this.secondaryColor,
  });
}