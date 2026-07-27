/// Modelo do endpoint /api/mobile/eleitoral/coligacao (?nome=...).
library;

import 'partido_detalhe_model.dart' show PartidoCandidatoItem;

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class ColigacaoDetalheModel {
  final String nome;
  final List<String> partidos;
  final int candidatos;
  final int eleitos;
  final int suplentes;
  final int votos;
  final List<PartidoCandidatoItem> topCandidatos;

  const ColigacaoDetalheModel({
    required this.nome,
    required this.partidos,
    required this.candidatos,
    required this.eleitos,
    required this.suplentes,
    required this.votos,
    required this.topCandidatos,
  });

  factory ColigacaoDetalheModel.fromJson(Map<String, dynamic> json) {
    final totais =
        (json['totais'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ColigacaoDetalheModel(
      nome: json['nome'] as String? ?? '',
      partidos: (json['partidos'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      candidatos: _toInt(totais['candidatos']),
      eleitos: _toInt(totais['eleitos']),
      suplentes: _toInt(totais['suplentes']),
      votos: _toInt(totais['votos']),
      topCandidatos: (json['top_candidatos'] as List? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => PartidoCandidatoItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
