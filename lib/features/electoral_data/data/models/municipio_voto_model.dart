class MunicipioVotoModel {
  final String idMunicipio;
  final String nomeMunicipio;
  final int votosMunicipio;
  final double percentualMunicipio;
  final String? mesorregiao;

  const MunicipioVotoModel({
    required this.idMunicipio,
    required this.nomeMunicipio,
    required this.votosMunicipio,
    required this.percentualMunicipio,
    this.mesorregiao,
  });

  factory MunicipioVotoModel.fromJson(Map<String, dynamic> json) {
    return MunicipioVotoModel(
      idMunicipio: json['id_municipio']?.toString() ?? '',
      nomeMunicipio: json['nome_municipio'] as String? ?? '',
      votosMunicipio: _parseInt(json['votos_municipio']),
      percentualMunicipio: _parseDouble(json['percentual_municipio']),
      mesorregiao: json['mesorregiao'] as String?,
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

class MapaMunicipiosData {
  final List<MunicipioVotoModel> municipios;
  final int totalVotos;
  final int maxVotosMunicipio;

  const MapaMunicipiosData({
    required this.municipios,
    required this.totalVotos,
    required this.maxVotosMunicipio,
  });

  factory MapaMunicipiosData.fromJson(Map<String, dynamic> json) {
    return MapaMunicipiosData(
      municipios: (json['municipios'] as List? ?? [])
          .map((e) => MunicipioVotoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalVotos: MunicipioVotoModel._parseInt(json['total_votos']),
      maxVotosMunicipio: MunicipioVotoModel._parseInt(json['max_votos_municipio']),
    );
  }
}
