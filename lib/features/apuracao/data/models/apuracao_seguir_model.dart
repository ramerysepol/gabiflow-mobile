import 'apuracao_parse_utils.dart';

/// Candidato que o gabinete está acompanhando na apuração ao vivo.
class ApuracaoSeguido {
  final String sqcand;
  final bool principal;
  final String? numero;
  final String nome;
  final String nomeUrna;
  final int? cargo;
  final String? cargoNome;
  final String? uf;
  final String? partido;
  final String? agremiacao;
  final int votos;
  final num? pct;
  final int? posicao;
  final String? projecao;
  final String? projecaoVia;
  final bool eleitoTse;
  final String? situacaoTse;
  final num? pctSecoes;
  final int? vagas;
  final DateTime? atualizadoEm;

  const ApuracaoSeguido({
    required this.sqcand,
    this.principal = false,
    this.numero,
    required this.nome,
    required this.nomeUrna,
    this.cargo,
    this.cargoNome,
    this.uf,
    this.partido,
    this.agremiacao,
    this.votos = 0,
    this.pct,
    this.posicao,
    this.projecao,
    this.projecaoVia,
    this.eleitoTse = false,
    this.situacaoTse,
    this.pctSecoes,
    this.vagas,
    this.atualizadoEm,
  });

  factory ApuracaoSeguido.fromJson(Map<String, dynamic> json) =>
      ApuracaoSeguido(
        sqcand: parseString(json['sqcand']),
        principal: parseBool(json['principal']),
        numero: parseStringOrNull(json['numero']),
        nome: parseString(json['nome']),
        nomeUrna: parseString(json['nomeUrna'], json['nome']?.toString() ?? ''),
        cargo: parseIntOrNull(json['cargo']),
        cargoNome: parseStringOrNull(json['cargoNome']),
        uf: parseStringOrNull(json['uf']),
        partido: parseStringOrNull(json['partido']),
        agremiacao: parseStringOrNull(json['agremiacao']),
        votos: parseInt(json['votos']),
        pct: parseNum(json['pct']),
        posicao: parseIntOrNull(json['posicao']),
        projecao: parseStringOrNull(json['projecao']),
        projecaoVia: parseStringOrNull(json['projecaoVia']),
        eleitoTse: parseBool(json['eleitoTse']),
        situacaoTse: parseStringOrNull(json['situacaoTse']),
        pctSecoes: parseNum(json['pctSecoes']),
        vagas: parseIntOrNull(json['vagas']),
        atualizadoEm: parseDate(json['atualizadoEm']),
      );
}

/// Sugestão de candidato (pelo cadastro do gabinete) para acompanhar.
class ApuracaoSugestao {
  final String sqcand;
  final String? numero;
  final String nome;
  final String nomeUrna;
  final int? cargo;
  final String? cargoNome;
  final String? uf;
  final String? partido;
  final String? agremiacao;
  final int confianca;

  const ApuracaoSugestao({
    required this.sqcand,
    this.numero,
    required this.nome,
    required this.nomeUrna,
    this.cargo,
    this.cargoNome,
    this.uf,
    this.partido,
    this.agremiacao,
    this.confianca = 0,
  });

  factory ApuracaoSugestao.fromJson(Map<String, dynamic> json) =>
      ApuracaoSugestao(
        sqcand: parseString(json['sqcand']),
        numero: parseStringOrNull(json['numero']),
        nome: parseString(json['nome']),
        nomeUrna: parseString(json['nomeUrna'], json['nome']?.toString() ?? ''),
        cargo: parseIntOrNull(json['cargo']),
        cargoNome: parseStringOrNull(json['cargoNome']),
        uf: parseStringOrNull(json['uf']),
        partido: parseStringOrNull(json['partido']),
        agremiacao: parseStringOrNull(json['agremiacao']),
        confianca: parseInt(json['confianca']),
      );
}

/// Resposta de GET/POST/DELETE /api/mobile/apuracao/seguir.
class ApuracaoSeguirModel {
  final List<ApuracaoSeguido> seguidos;
  final List<ApuracaoSugestao> sugestoes;

  const ApuracaoSeguirModel({
    this.seguidos = const [],
    this.sugestoes = const [],
  });

  /// Candidato principal do gabinete ("meu candidato"), se já escolhido.
  ApuracaoSeguido? get principal {
    for (final s in seguidos) {
      if (s.principal) return s;
    }
    return null;
  }

  /// Demais candidatos acompanhados (não-principal).
  List<ApuracaoSeguido> get outrosSeguidos =>
      seguidos.where((s) => !s.principal).toList(growable: false);

  factory ApuracaoSeguirModel.fromJson(Map<String, dynamic> json) =>
      ApuracaoSeguirModel(
        seguidos: parseList(json['seguidos'], ApuracaoSeguido.fromJson),
        sugestoes: parseList(json['sugestoes'], ApuracaoSugestao.fromJson),
      );
}
