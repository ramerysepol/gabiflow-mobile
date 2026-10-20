import 'apuracao_parse_utils.dart';

/// Ficha resumida do candidato no contexto de "onde está o voto que falta"
/// (duplica alguns campos de [ApuracaoCandidatoInfo] propositalmente — é a
/// resposta de um endpoint separado, mais leve).
class ApuracaoTerritorioCandidato {
  final String sqcand;
  final String nomeUrna;
  final String? numero;
  final int? cargo;
  final String? uf;

  const ApuracaoTerritorioCandidato({
    required this.sqcand,
    required this.nomeUrna,
    this.numero,
    this.cargo,
    this.uf,
  });

  factory ApuracaoTerritorioCandidato.fromJson(Map<String, dynamic> json) =>
      ApuracaoTerritorioCandidato(
        sqcand: parseString(json['sqcand']),
        nomeUrna: parseString(json['nomeUrna']),
        numero: parseStringOrNull(json['numero']),
        cargo: parseIntOrNull(json['cargo']),
        uf: parseStringOrNull(json['uf']),
      );
}

/// Votação atual do candidato (igual à ficha completa, só o essencial).
class ApuracaoTerritorioAtual {
  final int votos;
  final num? pct;
  final int? posicao;
  final bool projecaoEleito;
  final num? pctSecoes;
  final int? vagas;
  final bool finalizado;
  final DateTime? atualizadoEm;

  const ApuracaoTerritorioAtual({
    this.votos = 0,
    this.pct,
    this.posicao,
    this.projecaoEleito = false,
    this.pctSecoes,
    this.vagas,
    this.finalizado = false,
    this.atualizadoEm,
  });

  factory ApuracaoTerritorioAtual.fromJson(Map<String, dynamic> json) =>
      ApuracaoTerritorioAtual(
        votos: parseInt(json['votos']),
        pct: parseNum(json['pct']),
        posicao: parseIntOrNull(json['posicao']),
        projecaoEleito: parseBool(json['projecaoEleito']),
        pctSecoes: parseNum(json['pctSecoes']),
        vagas: parseIntOrNull(json['vagas']),
        finalizado: parseBool(json['finalizado']),
        atualizadoEm: parseDate(json['atualizadoEm']),
      );
}

/// Correspondência do candidato na eleição de 2022 (base da projeção).
class ApuracaoTerritorioBase2022 {
  final bool encontrado;
  final String? sequencial;
  final String? nome;
  final String? nomeUrna;
  final String? numero;
  final String? cargo;
  final String? partido;
  final String? situacao;
  final int? totalVotos;
  final int? municipiosComVoto;

  const ApuracaoTerritorioBase2022({
    this.encontrado = false,
    this.sequencial,
    this.nome,
    this.nomeUrna,
    this.numero,
    this.cargo,
    this.partido,
    this.situacao,
    this.totalVotos,
    this.municipiosComVoto,
  });

  factory ApuracaoTerritorioBase2022.fromJson(Map<String, dynamic> json) =>
      ApuracaoTerritorioBase2022(
        encontrado: parseBool(json['encontrado']),
        sequencial: parseStringOrNull(json['sequencial']),
        nome: parseStringOrNull(json['nome']),
        nomeUrna: parseStringOrNull(json['nomeUrna']),
        numero: parseStringOrNull(json['numero']),
        cargo: parseStringOrNull(json['cargo']),
        partido: parseStringOrNull(json['partido']),
        situacao: parseStringOrNull(json['situacao']),
        totalVotos: parseIntOrNull(json['totalVotos']),
        municipiosComVoto: parseIntOrNull(json['municipiosComVoto']),
      );
}

/// Projeção final de votos (central + faixa min/max), com a base usada
/// para calculá-la: o resultado de 2022 ajustado pela razão já observada
/// nos municípios apurados, ou — sem correspondência em 2022 — o ritmo
/// atual da apuração.
class ApuracaoTerritorioProjecao {
  final int central;
  final int min;
  final int max;

  /// '2022' | 'ritmo'.
  final String base;

  /// % de seções apuradas na UF — usado como indicador de confiança.
  final num? confianca;

  const ApuracaoTerritorioProjecao({
    required this.central,
    required this.min,
    required this.max,
    required this.base,
    this.confianca,
  });

  bool get baseEm2022 => base == '2022';

  factory ApuracaoTerritorioProjecao.fromJson(Map<String, dynamic> json) =>
      ApuracaoTerritorioProjecao(
        central: parseInt(json['central']),
        min: parseInt(json['min']),
        max: parseInt(json['max']),
        base: parseString(json['base'], 'ritmo'),
        confianca: parseNum(json['confianca']),
      );
}

/// Contadores de apoio da seção "onde está o voto que falta".
class ApuracaoTerritorioResumo {
  final int votosAtuais;
  final int potencialRestante;
  final int municipios;
  final int semApurar;
  final int parciais;
  final int totalizados;
  final int municipesTotal;
  final int municipesCasados;

  const ApuracaoTerritorioResumo({
    this.votosAtuais = 0,
    this.potencialRestante = 0,
    this.municipios = 0,
    this.semApurar = 0,
    this.parciais = 0,
    this.totalizados = 0,
    this.municipesTotal = 0,
    this.municipesCasados = 0,
  });

  /// Municípios ainda não totalizados (sem apurar + parciais) — usado como
  /// "quantos municípios ainda faltam" nos textos de projeção.
  int get aindaNaoTotalizados => semApurar + parciais;

  factory ApuracaoTerritorioResumo.fromJson(Map<String, dynamic> json) =>
      ApuracaoTerritorioResumo(
        votosAtuais: parseInt(json['votosAtuais']),
        potencialRestante: parseInt(json['potencialRestante']),
        municipios: parseInt(json['municipios']),
        semApurar: parseInt(json['semApurar']),
        parciais: parseInt(json['parciais']),
        totalizados: parseInt(json['totalizados']),
        municipesTotal: parseInt(json['municipesTotal']),
        municipesCasados: parseInt(json['municipesCasados']),
      );
}

/// Linha de município usada nas listas "onde falta apurar", "maiores
/// altas/quedas vs 2022" e nos votos por município (quando casado com 2022).
class ApuracaoTerritorioLinha {
  final String cd;
  final String? ibge;
  final String nome;
  final bool capital;
  final num? pctSecoes;
  final bool apurado;
  final bool finalizado;
  final int votos;
  final num? pct;
  final int? posicao;
  final int? votosValidos;
  final int? eleitorado;
  final int? votos2022;
  final int? variacaoVotos;
  final num? variacaoPct;
  final int municipes;
  final int? esperadoFinal;
  final int? potencialRestante;

  const ApuracaoTerritorioLinha({
    required this.cd,
    this.ibge,
    required this.nome,
    this.capital = false,
    this.pctSecoes,
    this.apurado = false,
    this.finalizado = false,
    this.votos = 0,
    this.pct,
    this.posicao,
    this.votosValidos,
    this.eleitorado,
    this.votos2022,
    this.variacaoVotos,
    this.variacaoPct,
    this.municipes = 0,
    this.esperadoFinal,
    this.potencialRestante,
  });

  factory ApuracaoTerritorioLinha.fromJson(Map<String, dynamic> json) =>
      ApuracaoTerritorioLinha(
        cd: parseString(json['cd']),
        ibge: parseStringOrNull(json['ibge']),
        nome: parseString(json['nome']),
        capital: parseBool(json['capital']),
        pctSecoes: parseNum(json['pctSecoes']),
        apurado: parseBool(json['apurado']),
        finalizado: parseBool(json['finalizado']),
        votos: parseInt(json['votos']),
        pct: parseNum(json['pct']),
        posicao: parseIntOrNull(json['posicao']),
        votosValidos: parseIntOrNull(json['votosValidos']),
        eleitorado: parseIntOrNull(json['eleitorado']),
        votos2022: parseIntOrNull(json['votos2022']),
        variacaoVotos: parseIntOrNull(json['variacaoVotos']),
        variacaoPct: parseNum(json['variacaoPct']),
        municipes: parseInt(json['municipes']),
        esperadoFinal: parseIntOrNull(json['esperadoFinal']),
        potencialRestante: parseIntOrNull(json['potencialRestante']),
      );
}

/// Resposta de GET /api/mobile/apuracao/candidato/{sqcand}/territorio:
/// projeção final do candidato e "onde está o voto que falta" — os
/// municípios que ainda vão decidir o resultado, com base no comparativo
/// com a eleição de 2022.
class ApuracaoTerritorioModel {
  final ApuracaoTerritorioCandidato candidato;
  final ApuracaoTerritorioAtual? atual;
  final ApuracaoTerritorioBase2022 base2022;
  final num? razaoVs2022;
  final ApuracaoTerritorioProjecao? projecao;
  final ApuracaoTerritorioResumo resumo;
  final List<ApuracaoTerritorioLinha> ondeFalta;
  final List<ApuracaoTerritorioLinha> maioresAltas;
  final List<ApuracaoTerritorioLinha> maioresQuedas;
  final List<ApuracaoTerritorioLinha> municipios;

  const ApuracaoTerritorioModel({
    required this.candidato,
    this.atual,
    this.base2022 = const ApuracaoTerritorioBase2022(),
    this.razaoVs2022,
    this.projecao,
    this.resumo = const ApuracaoTerritorioResumo(),
    this.ondeFalta = const [],
    this.maioresAltas = const [],
    this.maioresQuedas = const [],
    this.municipios = const [],
  });

  factory ApuracaoTerritorioModel.fromJson(
    Map<String, dynamic> json,
  ) => ApuracaoTerritorioModel(
    candidato: ApuracaoTerritorioCandidato.fromJson(
      Map<String, dynamic>.from(json['candidato'] as Map? ?? const {}),
    ),
    atual: json['atual'] == null
        ? null
        : ApuracaoTerritorioAtual.fromJson(
            Map<String, dynamic>.from(json['atual'] as Map),
          ),
    base2022: json['base2022'] == null
        ? const ApuracaoTerritorioBase2022()
        : ApuracaoTerritorioBase2022.fromJson(
            Map<String, dynamic>.from(json['base2022'] as Map),
          ),
    razaoVs2022: parseNum(json['razaoVs2022']),
    projecao: json['projecao'] == null
        ? null
        : ApuracaoTerritorioProjecao.fromJson(
            Map<String, dynamic>.from(json['projecao'] as Map),
          ),
    resumo: json['resumo'] == null
        ? const ApuracaoTerritorioResumo()
        : ApuracaoTerritorioResumo.fromJson(
            Map<String, dynamic>.from(json['resumo'] as Map),
          ),
    ondeFalta: parseList(json['ondeFalta'], ApuracaoTerritorioLinha.fromJson),
    maioresAltas: parseList(
      json['maioresAltas'],
      ApuracaoTerritorioLinha.fromJson,
    ),
    maioresQuedas: parseList(
      json['maioresQuedas'],
      ApuracaoTerritorioLinha.fromJson,
    ),
    municipios: parseList(json['municipios'], ApuracaoTerritorioLinha.fromJson),
  );
}
