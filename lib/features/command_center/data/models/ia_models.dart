/// Modelos das respostas JSON do Command Center IA
/// (briefing, insight do dia, alertas e radar territorial).
library;

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

// ─── Insight do Dia ──────────────────────────────────────────────────────────

class IaInsightModel {
  final String insight;
  final String tipo; // territorial | adversario | oportunidade | whatsapp | estrategia | info

  const IaInsightModel({required this.insight, required this.tipo});

  factory IaInsightModel.fromJson(Map<String, dynamic> json) {
    return IaInsightModel(
      insight: json['insight'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'info',
    );
  }
}

// ─── Alertas ─────────────────────────────────────────────────────────────────

class IaAlertaModel {
  final String tipo; // risco | oportunidade | urgente | info
  final String titulo;
  final String descricao;
  final String? municipio;
  final String? acaoSugerida;
  final String icone;

  const IaAlertaModel({
    required this.tipo,
    required this.titulo,
    required this.descricao,
    this.municipio,
    this.acaoSugerida,
    required this.icone,
  });

  factory IaAlertaModel.fromJson(Map<String, dynamic> json) {
    return IaAlertaModel(
      tipo: json['tipo'] as String? ?? 'info',
      titulo: json['titulo'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      municipio: json['municipio'] as String?,
      acaoSugerida: json['acao_sugerida'] as String?,
      icone: json['icone'] as String? ?? 'ℹ️',
    );
  }
}

// ─── Briefing ────────────────────────────────────────────────────────────────

class IaBriefingStats {
  final int totalMunicipiosUf;
  final int municipiosComVoto;
  final int municipiosSemVoto;
  final double coberturaTerritorialPct;

  const IaBriefingStats({
    required this.totalMunicipiosUf,
    required this.municipiosComVoto,
    required this.municipiosSemVoto,
    required this.coberturaTerritorialPct,
  });

  factory IaBriefingStats.fromJson(Map<String, dynamic> json) {
    return IaBriefingStats(
      totalMunicipiosUf: _toInt(json['total_municipios_uf']),
      municipiosComVoto: _toInt(json['municipios_com_voto']),
      municipiosSemVoto: _toInt(json['municipios_sem_voto']),
      coberturaTerritorialPct: _toDouble(json['cobertura_territorial_pct']),
    );
  }
}

class IaBriefingMunicipio {
  final String nome;
  final int votos;

  const IaBriefingMunicipio({required this.nome, required this.votos});

  factory IaBriefingMunicipio.fromJson(Map<String, dynamic> json) {
    return IaBriefingMunicipio(
      nome: (json['nome_municipio'] ?? json['nome'] ?? json['municipio'] ?? '')
          .toString(),
      votos: _toInt(json['votos'] ?? json['total_votos'] ?? json['votos_municipio']),
    );
  }
}

class IaBriefingMesorregiao {
  final String mesorregiao;
  final int totalVotos;
  final double coberturaPercentual;

  const IaBriefingMesorregiao({
    required this.mesorregiao,
    required this.totalVotos,
    required this.coberturaPercentual,
  });

  factory IaBriefingMesorregiao.fromJson(Map<String, dynamic> json) {
    return IaBriefingMesorregiao(
      mesorregiao: json['mesorregiao'] as String? ?? '',
      totalVotos: _toInt(json['total_votos']),
      coberturaPercentual: _toDouble(json['cobertura_percentual']),
    );
  }
}

class IaBriefingModel {
  final IaBriefingStats stats;
  final List<IaBriefingMunicipio> topMunicipios;
  final IaBriefingMesorregiao? melhorMesorregiao;
  final IaBriefingMesorregiao? piorMesorregiao;
  final Map<String, dynamic>? gabinete;
  final List<Map<String, dynamic>> topOportunidades;

  const IaBriefingModel({
    required this.stats,
    required this.topMunicipios,
    this.melhorMesorregiao,
    this.piorMesorregiao,
    this.gabinete,
    required this.topOportunidades,
  });

  factory IaBriefingModel.fromJson(Map<String, dynamic> json) {
    return IaBriefingModel(
      stats: IaBriefingStats.fromJson(
          (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {}),
      topMunicipios: (json['top_municipios'] as List? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => IaBriefingMunicipio.fromJson(e.cast<String, dynamic>()))
          .toList(),
      melhorMesorregiao: json['melhor_mesorregiao'] is Map
          ? IaBriefingMesorregiao.fromJson(
              (json['melhor_mesorregiao'] as Map).cast<String, dynamic>())
          : null,
      piorMesorregiao: json['pior_mesorregiao'] is Map
          ? IaBriefingMesorregiao.fromJson(
              (json['pior_mesorregiao'] as Map).cast<String, dynamic>())
          : null,
      gabinete: (json['gabinete'] as Map?)?.cast<String, dynamic>(),
      topOportunidades: (json['top_oportunidades'] as List? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => e.cast<String, dynamic>())
          .toList(),
    );
  }
}

// ─── Radar Territorial ───────────────────────────────────────────────────────

class IaRadarMunicipio {
  final String nomeMunicipio;
  final int votos;
  final int constituintes;
  final int demandas;
  final double score;
  final String classificacao; // forte | moderada | apenas_votos | sem_presenca

  const IaRadarMunicipio({
    required this.nomeMunicipio,
    required this.votos,
    required this.constituintes,
    required this.demandas,
    required this.score,
    required this.classificacao,
  });

  factory IaRadarMunicipio.fromJson(Map<String, dynamic> json) {
    return IaRadarMunicipio(
      nomeMunicipio: json['nome_municipio'] as String? ?? '',
      votos: _toInt(json['votos']),
      constituintes: _toInt(json['constituintes']),
      demandas: _toInt(json['demandas']),
      score: _toDouble(json['score']),
      classificacao: json['classificacao'] as String? ?? 'sem_presenca',
    );
  }
}

class IaRadarResumo {
  final int totalMunicipiosComVotos;
  final int totalVotos;
  final int comPresencaForte;
  final int apenasVotos;
  final int semPresenca;
  final int totalConstituintes;
  final int totalDemandas;

  const IaRadarResumo({
    required this.totalMunicipiosComVotos,
    required this.totalVotos,
    required this.comPresencaForte,
    required this.apenasVotos,
    required this.semPresenca,
    required this.totalConstituintes,
    required this.totalDemandas,
  });

  factory IaRadarResumo.fromJson(Map<String, dynamic> json) {
    return IaRadarResumo(
      totalMunicipiosComVotos: _toInt(json['total_municipios_com_votos']),
      totalVotos: _toInt(json['total_votos']),
      comPresencaForte: _toInt(json['com_presenca_forte']),
      apenasVotos: _toInt(json['apenas_votos']),
      semPresenca: _toInt(json['sem_presenca']),
      totalConstituintes: _toInt(json['total_constituintes']),
      totalDemandas: _toInt(json['total_demandas']),
    );
  }
}

class IaRadarModel {
  final List<IaRadarMunicipio> municipios;
  final IaRadarResumo resumo;
  final List<IaRadarMunicipio> oportunidades;

  const IaRadarModel({
    required this.municipios,
    required this.resumo,
    required this.oportunidades,
  });

  factory IaRadarModel.fromJson(Map<String, dynamic> json) {
    return IaRadarModel(
      municipios: (json['municipios'] as List? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => IaRadarMunicipio.fromJson(e.cast<String, dynamic>()))
          .toList(),
      resumo: IaRadarResumo.fromJson(
          (json['resumo'] as Map?)?.cast<String, dynamic>() ?? const {}),
      oportunidades: (json['oportunidades'] as List? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => IaRadarMunicipio.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
