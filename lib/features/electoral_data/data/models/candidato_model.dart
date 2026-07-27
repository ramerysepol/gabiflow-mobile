class CandidatoModel {
  final String sequencial;
  final String nome;
  final String nomeUrna;
  final String partido;
  final String siglaPartido;
  final String cargo;
  final int votosTotal;
  final int municipiosAtingidos;
  final String? fotoUrl;

  const CandidatoModel({
    required this.sequencial,
    required this.nome,
    required this.nomeUrna,
    required this.partido,
    required this.siglaPartido,
    required this.cargo,
    required this.votosTotal,
    required this.municipiosAtingidos,
    this.fotoUrl,
  });

  factory CandidatoModel.fromJson(Map<String, dynamic> json) {
    return CandidatoModel(
      sequencial: json['sequencial']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      nomeUrna: json['nome_urna'] as String? ?? '',
      partido: json['partido'] as String? ?? '',
      siglaPartido: json['sigla_partido'] as String? ?? '',
      cargo: json['cargo'] as String? ?? '',
      votosTotal: _parseInt(json['votos_total']),
      municipiosAtingidos: _parseInt(json['municipios_atingidos']),
      fotoUrl: json['foto_url'] as String?,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

class CandidatosPage {
  final List<CandidatoModel> items;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  const CandidatosPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory CandidatosPage.fromJson(Map<String, dynamic> json) {
    return CandidatosPage(
      items: (json['items'] as List? ?? [])
          .map((e) => CandidatoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: CandidatoModel._parseInt(json['total']),
      page: CandidatoModel._parseInt(json['page']),
      limit: CandidatoModel._parseInt(json['limit']),
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
