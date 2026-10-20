import 'apuracao_parse_utils.dart';

/// Abrangência de uma consulta de apuração (eleição/UF/cargo).
class ApuracaoAbrangencia {
  final dynamic eleicao;
  final String? uf;
  final int? cargo;
  final String? abr;
  final dynamic cd;

  const ApuracaoAbrangencia({
    this.eleicao,
    this.uf,
    this.cargo,
    this.abr,
    this.cd,
  });

  factory ApuracaoAbrangencia.fromJson(Map<String, dynamic> json) =>
      ApuracaoAbrangencia(
        eleicao: json['eleicao'],
        uf: parseStringOrNull(json['uf']),
        cargo: parseIntOrNull(json['cargo']),
        abr: parseStringOrNull(json['abr']),
        cd: json['cd'],
      );
}

/// Resumo consolidado da apuração para uma abrangência (totais, quociente,
/// seções apuradas etc.).
class ApuracaoResumo {
  final dynamic arquivoId;
  final dynamic eleicao;
  final String? uf;
  final String? abr;
  final dynamic cd;
  final int? cargo;
  final String? cargoNome;
  final int? vagas;
  final int? qe;
  final String? qeOrigem;
  final int? secoesTotal;
  final int? secoesTotalizadas;
  final num? pctSecoes;
  final int? eleitorado;
  final int? comparecimento;
  final int? abstencao;
  final num? pctComparecimento;
  final int? votosTotal;
  final int? votosValidos;
  final int? votosNominais;
  final int? votosLegenda;
  final int? brancos;
  final int? nulos;
  final int? anulados;
  final bool finalizado;
  final DateTime? atualizadoEm;
  final DateTime? geradoEm;
  final String? nomeAbr;

  const ApuracaoResumo({
    this.arquivoId,
    this.eleicao,
    this.uf,
    this.abr,
    this.cd,
    this.cargo,
    this.cargoNome,
    this.vagas,
    this.qe,
    this.qeOrigem,
    this.secoesTotal,
    this.secoesTotalizadas,
    this.pctSecoes,
    this.eleitorado,
    this.comparecimento,
    this.abstencao,
    this.pctComparecimento,
    this.votosTotal,
    this.votosValidos,
    this.votosNominais,
    this.votosLegenda,
    this.brancos,
    this.nulos,
    this.anulados,
    this.finalizado = false,
    this.atualizadoEm,
    this.geradoEm,
    this.nomeAbr,
  });

  factory ApuracaoResumo.fromJson(Map<String, dynamic> json) => ApuracaoResumo(
    arquivoId: json['arquivoId'],
    eleicao: json['eleicao'],
    uf: parseStringOrNull(json['uf']),
    abr: parseStringOrNull(json['abr']),
    cd: json['cd'],
    cargo: parseIntOrNull(json['cargo']),
    cargoNome: parseStringOrNull(json['cargoNome']),
    vagas: parseIntOrNull(json['vagas']),
    qe: parseIntOrNull(json['qe']),
    qeOrigem: parseStringOrNull(json['qeOrigem']),
    secoesTotal: parseIntOrNull(json['secoesTotal']),
    secoesTotalizadas: parseIntOrNull(json['secoesTotalizadas']),
    pctSecoes: parseNum(json['pctSecoes']),
    eleitorado: parseIntOrNull(json['eleitorado']),
    comparecimento: parseIntOrNull(json['comparecimento']),
    abstencao: parseIntOrNull(json['abstencao']),
    pctComparecimento: parseNum(json['pctComparecimento']),
    votosTotal: parseIntOrNull(json['votosTotal']),
    votosValidos: parseIntOrNull(json['votosValidos']),
    votosNominais: parseIntOrNull(json['votosNominais']),
    votosLegenda: parseIntOrNull(json['votosLegenda']),
    brancos: parseIntOrNull(json['brancos']),
    nulos: parseIntOrNull(json['nulos']),
    anulados: parseIntOrNull(json['anulados']),
    finalizado: parseBool(json['finalizado']),
    atualizadoEm: parseDate(json['atualizadoEm']),
    geradoEm: parseDate(json['geradoEm']),
    nomeAbr: parseStringOrNull(json['nomeAbr']),
  );
}

/// Um candidato com sua votação apurada (usado no ranking, na ficha do
/// candidato e nos vizinhos/colegas de disputa).
class ApuracaoCandVoto {
  final String sqcand;
  final String? numero;
  final String nome;
  final String nomeUrna;
  final int? cargo;
  final String? cargoNome;
  final String? partido;
  final String? partidoNum;
  final String? federacao;
  final String? agremiacao;
  final String? agremiacaoN;
  final String? agremiacaoTipo;
  final String? vices;
  final String? uf;
  final int votos;
  final num? pct;
  final int? posicao;
  final int? posicaoAgr;
  final bool eleitoTse;
  final String? situacaoTse;
  final String? projecao; // eleito | suplente | segundo_turno | nao_eleito
  final String? projecaoVia; // qp | media | tse | maioria
  final bool seguido;
  final bool principal;

  /// Presentes apenas quando vindos de `geral` (ficha do candidato).
  final int? vagas;
  final bool? proporcional;

  const ApuracaoCandVoto({
    required this.sqcand,
    this.numero,
    required this.nome,
    required this.nomeUrna,
    this.cargo,
    this.cargoNome,
    this.partido,
    this.partidoNum,
    this.federacao,
    this.agremiacao,
    this.agremiacaoN,
    this.agremiacaoTipo,
    this.vices,
    this.uf,
    this.votos = 0,
    this.pct,
    this.posicao,
    this.posicaoAgr,
    this.eleitoTse = false,
    this.situacaoTse,
    this.projecao,
    this.projecaoVia,
    this.seguido = false,
    this.principal = false,
    this.vagas,
    this.proporcional,
  });

  factory ApuracaoCandVoto.fromJson(Map<String, dynamic> json) =>
      ApuracaoCandVoto(
        sqcand: parseString(json['sqcand']),
        numero: parseStringOrNull(json['numero']),
        nome: parseString(json['nome']),
        nomeUrna: parseString(json['nomeUrna'], json['nome']?.toString() ?? ''),
        cargo: parseIntOrNull(json['cargo']),
        cargoNome: parseStringOrNull(json['cargoNome']),
        partido: parseStringOrNull(json['partido']),
        partidoNum: parseStringOrNull(json['partidoNum']),
        federacao: parseStringOrNull(json['federacao']),
        agremiacao: parseStringOrNull(json['agremiacao']),
        agremiacaoN: parseStringOrNull(json['agremiacaoN']),
        agremiacaoTipo: parseStringOrNull(json['agremiacaoTipo']),
        vices: parseStringOrNull(json['vices']),
        uf: parseStringOrNull(json['uf']),
        votos: parseInt(json['votos']),
        pct: parseNum(json['pct']),
        posicao: parseIntOrNull(json['posicao']),
        posicaoAgr: parseIntOrNull(json['posicaoAgr']),
        eleitoTse: parseBool(json['eleitoTse']),
        situacaoTse: parseStringOrNull(json['situacaoTse']),
        projecao: parseStringOrNull(json['projecao']),
        projecaoVia: parseStringOrNull(json['projecaoVia']),
        seguido: parseBool(json['seguido']),
        principal: parseBool(json['principal']),
        vagas: parseIntOrNull(json['vagas']),
        proporcional: json['proporcional'] == null
            ? null
            : parseBool(json['proporcional']),
      );
}

/// Resposta de GET /api/mobile/apuracao/ranking.
class ApuracaoRankingModel {
  final ApuracaoAbrangencia abrangencia;
  final ApuracaoResumo? resumo;
  final int total;
  final List<ApuracaoCandVoto> itens;

  const ApuracaoRankingModel({
    required this.abrangencia,
    this.resumo,
    this.total = 0,
    this.itens = const [],
  });

  factory ApuracaoRankingModel.fromJson(Map<String, dynamic> json) =>
      ApuracaoRankingModel(
        abrangencia: ApuracaoAbrangencia.fromJson(
          Map<String, dynamic>.from(json['abrangencia'] as Map? ?? const {}),
        ),
        resumo: json['resumo'] == null
            ? null
            : ApuracaoResumo.fromJson(
                Map<String, dynamic>.from(json['resumo'] as Map),
              ),
        total: parseInt(json['total']),
        itens: parseList(json['itens'], ApuracaoCandVoto.fromJson),
      );
}
