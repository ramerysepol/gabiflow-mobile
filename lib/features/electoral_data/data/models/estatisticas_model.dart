/// Modelos do endpoint /api/mobile/eleitoral/estatisticas
/// (dashboard de análise da eleição).
library;

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class EstatisticasGenero {
  final int masculino;
  final int feminino;
  final int naoInformado;

  const EstatisticasGenero({
    required this.masculino,
    required this.feminino,
    required this.naoInformado,
  });

  factory EstatisticasGenero.fromJson(Map<String, dynamic> json) {
    return EstatisticasGenero(
      masculino: _toInt(json['masculino']),
      feminino: _toInt(json['feminino']),
      naoInformado: _toInt(json['nao_informado']),
    );
  }
}

class EstatisticasSituacao {
  final String status;
  final int total;

  const EstatisticasSituacao({required this.status, required this.total});

  factory EstatisticasSituacao.fromJson(Map<String, dynamic> json) {
    return EstatisticasSituacao(
      status: json['status'] as String? ?? '',
      total: _toInt(json['total']),
    );
  }
}

class PartidoRankingItem {
  final String sigla;
  final int candidatos;
  final int eleitos;
  final int suplentes;
  final int votos;

  const PartidoRankingItem({
    required this.sigla,
    required this.candidatos,
    required this.eleitos,
    required this.suplentes,
    required this.votos,
  });

  factory PartidoRankingItem.fromJson(Map<String, dynamic> json) {
    return PartidoRankingItem(
      sigla: json['sigla'] as String? ?? '',
      candidatos: _toInt(json['candidatos']),
      eleitos: _toInt(json['eleitos']),
      suplentes: _toInt(json['suplentes']),
      votos: _toInt(json['votos']),
    );
  }
}

class TopCandidatoItem {
  final String sequencial;
  final String nome;
  final String nomeUrna;
  final String siglaPartido;
  final String cargo;
  final int votos;
  final String resultado;

  const TopCandidatoItem({
    required this.sequencial,
    required this.nome,
    required this.nomeUrna,
    required this.siglaPartido,
    required this.cargo,
    required this.votos,
    required this.resultado,
  });

  factory TopCandidatoItem.fromJson(Map<String, dynamic> json) {
    return TopCandidatoItem(
      sequencial: json['sequencial']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      nomeUrna: json['nome_urna'] as String? ?? '',
      siglaPartido: json['sigla_partido'] as String? ?? '',
      cargo: json['cargo'] as String? ?? '',
      votos: _toInt(json['votos']),
      resultado: json['resultado'] as String? ?? '',
    );
  }

  bool get eleito => resultado.toLowerCase().contains('eleito') &&
      !resultado.toLowerCase().contains('não');
}

class EstatisticasModel {
  final int totalCandidatos;
  final int candidatosEleitos;
  final double percentualEleitos;
  final double candidatasMulheresPct;
  final EstatisticasGenero genero;
  final List<EstatisticasSituacao> situacao;
  final int totalPartidos;
  final List<PartidoRankingItem> partidosRanking;
  final List<TopCandidatoItem> candidatosMaisVotados;

  const EstatisticasModel({
    required this.totalCandidatos,
    required this.candidatosEleitos,
    required this.percentualEleitos,
    required this.candidatasMulheresPct,
    required this.genero,
    required this.situacao,
    required this.totalPartidos,
    required this.partidosRanking,
    required this.candidatosMaisVotados,
  });

  factory EstatisticasModel.fromJson(Map<String, dynamic> json) {
    final partidos =
        (json['partidos'] as Map?)?.cast<String, dynamic>() ?? const {};
    return EstatisticasModel(
      totalCandidatos: _toInt(json['total_candidatos']),
      candidatosEleitos: _toInt(json['candidatos_eleitos']),
      percentualEleitos: _toDouble(json['percentual_eleitos']),
      candidatasMulheresPct: _toDouble(json['candidatas_mulheres_pct']),
      genero: EstatisticasGenero.fromJson(
          (json['genero'] as Map?)?.cast<String, dynamic>() ?? const {}),
      situacao: (json['situacao'] as List? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => EstatisticasSituacao.fromJson(e.cast<String, dynamic>()))
          .toList(),
      totalPartidos: _toInt(partidos['total']),
      partidosRanking: (partidos['ranking'] as List? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => PartidoRankingItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      candidatosMaisVotados: (json['candidatos_mais_votados'] as List? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => TopCandidatoItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
