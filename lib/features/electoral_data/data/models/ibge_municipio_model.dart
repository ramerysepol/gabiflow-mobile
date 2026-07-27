class ComposicaoEconomica {
  final double agropecuaria;
  final double industria;
  final double servicos;
  final double admPublica;

  const ComposicaoEconomica({
    required this.agropecuaria,
    required this.industria,
    required this.servicos,
    required this.admPublica,
  });

  factory ComposicaoEconomica.fromJson(Map<String, dynamic> json) {
    return ComposicaoEconomica(
      agropecuaria: _parseDouble(json['agropecuaria']),
      industria: _parseDouble(json['industria']),
      servicos: _parseDouble(json['servicos']),
      admPublica: _parseDouble(json['adm_publica']),
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  /// Retorna o setor dominante.
  String get setorDominante {
    final map = {
      'Agropecuária': agropecuaria,
      'Indústria': industria,
      'Serviços': servicos,
      'Adm. Pública': admPublica,
    };
    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Sugestão de projetos conforme setor dominante.
  String get sugestaoProjetos {
    switch (setorDominante) {
      case 'Agropecuária':
        return 'Projetos rurais, crédito agrícola, irrigação, assistência técnica';
      case 'Indústria':
        return 'Incentivos industriais, infraestrutura logística, qualificação profissional';
      case 'Serviços':
        return 'Fomento ao comércio, turismo, capacitação em TI e serviços';
      default:
        return 'Melhoria de serviços públicos, saúde, educação e infraestrutura';
    }
  }
}

class IbgeMunicipioModel {
  final String id;
  final String nome;
  final String uf;
  final String mesorregiao;
  final String microrregiao;
  final int populacao;
  final double pibPerCapita;
  final ComposicaoEconomica? composicao;

  const IbgeMunicipioModel({
    required this.id,
    required this.nome,
    required this.uf,
    required this.mesorregiao,
    required this.microrregiao,
    required this.populacao,
    required this.pibPerCapita,
    this.composicao,
  });

  factory IbgeMunicipioModel.fromJson(Map<String, dynamic> json) {
    return IbgeMunicipioModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      uf: json['uf'] as String? ?? '',
      mesorregiao: json['mesorregiao'] as String? ?? '',
      microrregiao: json['microrregiao'] as String? ?? '',
      populacao: _parseInt(json['populacao']),
      pibPerCapita: _parseDouble(json['pib_per_capita']),
      composicao: json['composicao'] != null
          ? ComposicaoEconomica.fromJson(json['composicao'] as Map<String, dynamic>)
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

class IbgeMunicipioRef {
  final String id;
  final String nome;

  const IbgeMunicipioRef({required this.id, required this.nome});

  factory IbgeMunicipioRef.fromJson(Map<String, dynamic> json) {
    return IbgeMunicipioRef(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
    );
  }
}

class IbgeMicrorregiao {
  final String id;
  final String nome;
  final String? mesorregiao;
  final List<IbgeMunicipioRef> municipios;

  const IbgeMicrorregiao({
    required this.id,
    required this.nome,
    this.mesorregiao,
    required this.municipios,
  });

  /// Apenas os IDs (shortcut pra filtrar/agregar votos por município).
  List<String> get municipioIds => municipios.map((m) => m.id).toList();

  factory IbgeMicrorregiao.fromJson(Map<String, dynamic> json) {
    final rawMunicipios = json['municipios'] as List? ?? [];
    // Aceita tanto o formato novo [{id,nome}] quanto o antigo [id, id, ...]
    // pra não quebrar caches em trânsito.
    final munis = rawMunicipios.map((e) {
      if (e is Map<String, dynamic>) {
        return IbgeMunicipioRef.fromJson(e);
      }
      final id = e.toString();
      return IbgeMunicipioRef(id: id, nome: id);
    }).toList();
    return IbgeMicrorregiao(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      mesorregiao: json['mesorregiao'] as String?,
      municipios: munis,
    );
  }
}
