/// Modelo do endpoint /api/mobile/eleitoral/partido/{sigla}.
library;

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class PartidoCandidatoItem {
  final String sequencial;
  final String nome;
  final String nomeUrna;
  final String cargo;
  final int votos;
  final String resultado;

  /// Presente quando o item vem de contexto multi-partido (coligação).
  final String siglaPartido;

  const PartidoCandidatoItem({
    required this.sequencial,
    required this.nome,
    required this.nomeUrna,
    required this.cargo,
    required this.votos,
    required this.resultado,
    this.siglaPartido = '',
  });

  factory PartidoCandidatoItem.fromJson(Map<String, dynamic> json) {
    return PartidoCandidatoItem(
      sequencial: json['sequencial']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      nomeUrna: json['nome_urna'] as String? ?? '',
      cargo: json['cargo'] as String? ?? '',
      votos: _toInt(json['votos']),
      resultado: json['resultado'] as String? ?? '',
      siglaPartido: json['sigla_partido'] as String? ?? '',
    );
  }

  bool get eleito {
    final r = resultado.toLowerCase();
    return r.contains('eleito') && !r.contains('não');
  }

  bool get suplente => resultado.toLowerCase() == 'suplente';
}

class PartidoMunicipioItem {
  final String id;
  final String nome;
  final int votos;

  const PartidoMunicipioItem({
    required this.id,
    required this.nome,
    required this.votos,
  });

  factory PartidoMunicipioItem.fromJson(Map<String, dynamic> json) {
    return PartidoMunicipioItem(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      votos: _toInt(json['votos']),
    );
  }
}

class PartidoDetalheModel {
  final String sigla;
  final String nome;
  final String? numeroPartido;
  final int candidatos;
  final int eleitos;
  final int suplentes;
  final int votos;
  final int generoMasculino;
  final int generoFeminino;
  final List<PartidoCandidatoItem> topCandidatos;
  final List<PartidoMunicipioItem> topMunicipios;

  const PartidoDetalheModel({
    required this.sigla,
    required this.nome,
    this.numeroPartido,
    required this.candidatos,
    required this.eleitos,
    required this.suplentes,
    required this.votos,
    required this.generoMasculino,
    required this.generoFeminino,
    required this.topCandidatos,
    required this.topMunicipios,
  });

  factory PartidoDetalheModel.fromJson(Map<String, dynamic> json) {
    final totais =
        (json['totais'] as Map?)?.cast<String, dynamic>() ?? const {};
    final genero =
        (json['genero'] as Map?)?.cast<String, dynamic>() ?? const {};
    return PartidoDetalheModel(
      sigla: json['sigla'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      numeroPartido: json['numero_partido']?.toString(),
      candidatos: _toInt(totais['candidatos']),
      eleitos: _toInt(totais['eleitos']),
      suplentes: _toInt(totais['suplentes']),
      votos: _toInt(totais['votos']),
      generoMasculino: _toInt(genero['masculino']),
      generoFeminino: _toInt(genero['feminino']),
      topCandidatos: (json['top_candidatos'] as List? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => PartidoCandidatoItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      topMunicipios: (json['top_municipios'] as List? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => PartidoMunicipioItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
