class EleitoMunicipioModel {
  final String sequencial;
  final String nome;
  final String nomeUrna;
  final String siglaPartido;
  final String cargo;
  final String? numero;
  final String? fotoUrl;
  final String resultado;
  final int votosMunicipio;
  final double percentualMunicipio;

  const EleitoMunicipioModel({
    required this.sequencial,
    required this.nome,
    required this.nomeUrna,
    required this.siglaPartido,
    required this.cargo,
    required this.numero,
    required this.fotoUrl,
    required this.resultado,
    required this.votosMunicipio,
    required this.percentualMunicipio,
  });

  bool get isEleito => resultado.contains('eleito') && !resultado.contains('suplente');
  bool get isSuplente => resultado.contains('suplente');

  factory EleitoMunicipioModel.fromJson(Map<String, dynamic> json) {
    return EleitoMunicipioModel(
      sequencial: json['sequencial']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      nomeUrna: json['nome_urna'] as String? ?? '',
      siglaPartido: json['sigla_partido'] as String? ?? '',
      cargo: json['cargo'] as String? ?? '',
      numero: json['numero']?.toString(),
      fotoUrl: json['foto_url'] as String?,
      resultado: (json['resultado'] as String? ?? '').toLowerCase(),
      votosMunicipio: _parseInt(json['votos_municipio']),
      percentualMunicipio: _parseDouble(json['percentual_municipio']),
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

class MunicipioEleitosModel {
  final String idMunicipio;
  final String nomeMunicipio;
  final int totalVotos;
  final int totalEleitos;
  final List<EleitoMunicipioModel> items;

  const MunicipioEleitosModel({
    required this.idMunicipio,
    required this.nomeMunicipio,
    required this.totalVotos,
    required this.totalEleitos,
    required this.items,
  });

  factory MunicipioEleitosModel.fromJson(Map<String, dynamic> json) {
    return MunicipioEleitosModel(
      idMunicipio: json['id_municipio']?.toString() ?? '',
      nomeMunicipio: json['nome_municipio'] as String? ?? '',
      totalVotos: EleitoMunicipioModel._parseInt(json['total_votos']),
      totalEleitos: EleitoMunicipioModel._parseInt(json['total_eleitos']),
      items: (json['items'] as List? ?? [])
          .map((e) => EleitoMunicipioModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
