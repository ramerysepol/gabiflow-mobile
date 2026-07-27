/// Modelos auxiliares do módulo de munícipes: facetas de filtro e interações.
library;

class FacetaItem {
  final String valor;
  final int total;

  const FacetaItem({required this.valor, required this.total});

  factory FacetaItem.fromJson(Map<String, dynamic> json) => FacetaItem(
        valor: json['valor']?.toString() ?? '',
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

class ConstituentFacets {
  final List<FacetaItem> tags;
  final List<FacetaItem> cidades;
  final int aniversariantesHoje;

  const ConstituentFacets({
    required this.tags,
    required this.cidades,
    required this.aniversariantesHoje,
  });

  factory ConstituentFacets.fromJson(Map<String, dynamic> json) {
    List<FacetaItem> parse(dynamic list) => (list as List? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => FacetaItem.fromJson(e.cast<String, dynamic>()))
        .toList();
    return ConstituentFacets(
      tags: parse(json['tags']),
      cidades: parse(json['cidades']),
      aniversariantesHoje:
          (json['aniversariantes_hoje'] as num?)?.toInt() ?? 0,
    );
  }
}

class InteracaoModel {
  final String id;
  final String tipo;
  final String descricao;
  final String? canal;
  final String? resultado;
  final String? dataInteracao;
  final String? responsavelNome;

  const InteracaoModel({
    required this.id,
    required this.tipo,
    required this.descricao,
    this.canal,
    this.resultado,
    this.dataInteracao,
    this.responsavelNome,
  });

  factory InteracaoModel.fromJson(Map<String, dynamic> json) =>
      InteracaoModel(
        id: json['id']?.toString() ?? '',
        tipo: json['tipo']?.toString() ?? 'outro',
        descricao: json['descricao']?.toString() ?? '',
        canal: json['canal']?.toString(),
        resultado: json['resultado']?.toString(),
        dataInteracao: json['data_interacao']?.toString(),
        responsavelNome: json['responsavel_nome']?.toString(),
      );
}

/// Filtros ativos da lista de munícipes.
class ConstituentFilters {
  final String? cidade;
  final String? tag;
  final String? nivelApoio;
  final String? aniversariantes; // 'hoje' | 'mes'
  final String sort; // 'recentes' | 'nome'

  const ConstituentFilters({
    this.cidade,
    this.tag,
    this.nivelApoio,
    this.aniversariantes,
    this.sort = 'recentes',
  });

  bool get vazio =>
      cidade == null &&
      tag == null &&
      nivelApoio == null &&
      aniversariantes == null;

  int get quantidadeAtivos =>
      (cidade != null ? 1 : 0) +
      (tag != null ? 1 : 0) +
      (nivelApoio != null ? 1 : 0) +
      (aniversariantes != null ? 1 : 0);

  ConstituentFilters copyWith({
    String? cidade,
    String? tag,
    String? nivelApoio,
    String? aniversariantes,
    String? sort,
    bool limparCidade = false,
    bool limparTag = false,
    bool limparNivel = false,
    bool limparAniversariantes = false,
  }) =>
      ConstituentFilters(
        cidade: limparCidade ? null : (cidade ?? this.cidade),
        tag: limparTag ? null : (tag ?? this.tag),
        nivelApoio: limparNivel ? null : (nivelApoio ?? this.nivelApoio),
        aniversariantes: limparAniversariantes
            ? null
            : (aniversariantes ?? this.aniversariantes),
        sort: sort ?? this.sort,
      );

  static const vazios = ConstituentFilters();
}
