/// Apoiador de 2024 (candidato municipal) — espelha ApoiadorResumo da web.
class ApoiadorModel {
  const ApoiadorModel({
    required this.sequencial,
    required this.ano,
    required this.nomeUrna,
    required this.cargo,
    required this.numero,
    required this.partido,
    required this.votosTotal,
    required this.resultado,
    this.observacao,
  });

  final String sequencial;
  final int ano;
  final String nomeUrna;
  final String cargo;
  final String numero;
  final String partido;
  final int votosTotal;
  final String resultado;
  final String? observacao;

  factory ApoiadorModel.fromJson(Map<String, dynamic> j) => ApoiadorModel(
        sequencial: j['sequencial']?.toString() ?? '',
        ano: (j['ano'] as num?)?.toInt() ?? 0,
        nomeUrna: j['nome_urna']?.toString() ?? '',
        cargo: j['cargo']?.toString() ?? '',
        numero: j['numero']?.toString() ?? '',
        partido: j['partido']?.toString() ?? '',
        votosTotal: (j['votos_total'] as num?)?.toInt() ?? 0,
        resultado: j['resultado']?.toString() ?? '',
        observacao: j['observacao']?.toString(),
      );
}

/// Sugestão da IA: apoiador + afinidade (alta | media | baixa).
class SugestaoApoiadorModel {
  const SugestaoApoiadorModel({
    required this.apoiador,
    required this.score,
    required this.afinidade,
  });

  final ApoiadorModel apoiador;
  final double score;
  final String afinidade;

  String get afinidadeRotulo => switch (afinidade) {
        'alta' => 'Alta',
        'media' => 'Média',
        _ => 'Baixa',
      };

  factory SugestaoApoiadorModel.fromJson(Map<String, dynamic> j) =>
      SugestaoApoiadorModel(
        apoiador: ApoiadorModel.fromJson(j),
        score: (j['score'] as num?)?.toDouble() ?? 0,
        afinidade: j['afinidade']?.toString() ?? 'baixa',
      );
}
