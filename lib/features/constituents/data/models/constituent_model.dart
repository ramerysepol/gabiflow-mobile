/// Model de munícipe (constituent) — sem geração de código.
/// Campos alinhados ao endpoint mobile (/api/mobile/constituents):
/// a lista devolve o shape enxuto; o detalhe devolve todos os campos.
class ConstituentModel {
  final String id;
  final String nome;
  final String? cpf;
  final String? email;
  final String? telefone;
  final String? whatsapp;
  final String? endereco;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? cep;
  final String? dataNascimento; // YYYY-MM-DD
  final String? genero;
  final String? profissao;
  final String? nivelApoio;
  final bool voluntario;
  final List<String> tags;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  const ConstituentModel({
    required this.id,
    required this.nome,
    this.cpf,
    this.email,
    this.telefone,
    this.whatsapp,
    this.endereco,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
    this.dataNascimento,
    this.genero,
    this.profissao,
    this.nivelApoio,
    this.voluntario = false,
    this.tags = const [],
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory ConstituentModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    List<String> parsedTags = [];
    if (rawTags is List) {
      parsedTags = rawTags.map((e) => e.toString()).toList();
    }
    return ConstituentModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? json['name']?.toString() ?? '',
      cpf: json['cpf']?.toString(),
      email: json['email']?.toString(),
      telefone: json['telefone']?.toString() ?? json['phone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      endereco: json['endereco']?.toString(),
      numero: json['numero']?.toString(),
      complemento: json['complemento']?.toString(),
      bairro: json['bairro']?.toString(),
      cidade: json['cidade']?.toString(),
      estado: json['estado']?.toString(),
      cep: json['cep']?.toString(),
      dataNascimento: json['data_nascimento']?.toString(),
      genero: json['genero']?.toString(),
      profissao: json['profissao']?.toString(),
      nivelApoio: json['nivel_apoio']?.toString(),
      voluntario: json['voluntario'] == true,
      tags: parsedTags,
      notes: json['observacoes']?.toString() ?? json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        if (cpf != null) 'cpf': cpf,
        if (email != null) 'email': email,
        if (telefone != null) 'telefone': telefone,
        if (whatsapp != null) 'whatsapp': whatsapp,
        if (endereco != null) 'endereco': endereco,
        if (numero != null) 'numero': numero,
        if (complemento != null) 'complemento': complemento,
        if (bairro != null) 'bairro': bairro,
        if (cidade != null) 'cidade': cidade,
        if (estado != null) 'estado': estado,
        if (cep != null) 'cep': cep,
        if (dataNascimento != null) 'data_nascimento': dataNascimento,
        if (genero != null) 'genero': genero,
        if (profissao != null) 'profissao': profissao,
        if (nivelApoio != null) 'nivel_apoio': nivelApoio,
        'voluntario': voluntario,
        'tags': tags,
        if (notes != null) 'observacoes': notes,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}

class ConstituentListResponse {
  final List<ConstituentModel> items;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  const ConstituentListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory ConstituentListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .map((e) => ConstituentModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <ConstituentModel>[];
    return ConstituentListResponse(
      items: items,
      total: _parseInt(json['total']),
      page: _parseInt(json['page']),
      limit: _parseInt(json['limit']),
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
