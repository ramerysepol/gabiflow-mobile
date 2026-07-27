class MunicipioRef {
  final String id;
  final String nome;
  final int votos;

  const MunicipioRef({required this.id, required this.nome, required this.votos});

  factory MunicipioRef.fromJson(Map<String, dynamic> json) {
    return MunicipioRef(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      votos: _parseInt(json['votos']),
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

class CandidatoStatsModel {
  final int votosTotal;
  final int municipiosAtingidos;
  final double percentualEstado;
  final int rankingCargo;
  final int totalCandidatosCargo;
  final MunicipioRef? maiorVotacaoMunicipio;
  final MunicipioRef? menorVotacaoMunicipio;

  const CandidatoStatsModel({
    required this.votosTotal,
    required this.municipiosAtingidos,
    required this.percentualEstado,
    required this.rankingCargo,
    required this.totalCandidatosCargo,
    this.maiorVotacaoMunicipio,
    this.menorVotacaoMunicipio,
  });

  factory CandidatoStatsModel.fromJson(Map<String, dynamic> json) {
    return CandidatoStatsModel(
      votosTotal: _parseInt(json['votos_total']),
      municipiosAtingidos: _parseInt(json['municipios_atingidos']),
      percentualEstado: _parseDouble(json['percentual_estado']),
      rankingCargo: _parseInt(json['ranking_cargo']),
      totalCandidatosCargo: _parseInt(json['total_candidatos_cargo']),
      maiorVotacaoMunicipio: json['maior_votacao_municipio'] != null
          ? MunicipioRef.fromJson(json['maior_votacao_municipio'] as Map<String, dynamic>)
          : null,
      menorVotacaoMunicipio: json['menor_votacao_municipio'] != null
          ? MunicipioRef.fromJson(json['menor_votacao_municipio'] as Map<String, dynamic>)
          : null,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class CandidatoDetalheModel {
  final String sequencial;
  final String nome;
  final String nomeUrna;
  final String partido;
  final String siglaPartido;
  final String cargo;
  final String? fotoUrl;
  final String? bio;

  const CandidatoDetalheModel({
    required this.sequencial,
    required this.nome,
    required this.nomeUrna,
    required this.partido,
    required this.siglaPartido,
    required this.cargo,
    this.fotoUrl,
    this.bio,
  });

  factory CandidatoDetalheModel.fromJson(Map<String, dynamic> json) {
    return CandidatoDetalheModel(
      sequencial: json['sequencial']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      nomeUrna: json['nome_urna'] as String? ?? '',
      partido: json['partido'] as String? ?? '',
      siglaPartido: json['sigla_partido'] as String? ?? '',
      cargo: json['cargo'] as String? ?? '',
      fotoUrl: json['foto_url'] as String?,
      bio: json['bio'] as String?,
    );
  }
}

class CandidatoFullModel {
  final CandidatoDetalheModel candidato;
  final CandidatoStatsModel stats;
  final List<TopMunicipioModel> topMunicipios;

  const CandidatoFullModel({
    required this.candidato,
    required this.stats,
    required this.topMunicipios,
  });

  factory CandidatoFullModel.fromJson(Map<String, dynamic> json) {
    return CandidatoFullModel(
      candidato: CandidatoDetalheModel.fromJson(json['candidato'] as Map<String, dynamic>),
      stats: CandidatoStatsModel.fromJson(json['stats'] as Map<String, dynamic>),
      topMunicipios: (json['top_municipios'] as List? ?? [])
          .map((e) => TopMunicipioModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TopMunicipioModel {
  final String idMunicipio;
  final String nomeMunicipio;
  final int votosMunicipio;
  final double percentualMunicipio;

  const TopMunicipioModel({
    required this.idMunicipio,
    required this.nomeMunicipio,
    required this.votosMunicipio,
    required this.percentualMunicipio,
  });

  factory TopMunicipioModel.fromJson(Map<String, dynamic> json) {
    return TopMunicipioModel(
      idMunicipio: json['id_municipio']?.toString() ?? '',
      nomeMunicipio: json['nome_municipio'] as String? ?? '',
      votosMunicipio: CandidatoStatsModel._parseInt(json['votos_municipio']),
      percentualMunicipio: CandidatoStatsModel._parseDouble(json['percentual_municipio']),
    );
  }
}
