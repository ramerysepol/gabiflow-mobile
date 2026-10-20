import 'apuracao_parse_utils.dart';

/// Item de resultado de busca de candidato (GET /api/mobile/apuracao/busca).
class ApuracaoBuscaItem {
  final String sqcand;
  final String? numero;
  final String nome;
  final String nomeUrna;
  final int? cargo;
  final String? cargoNome;
  final String? uf;
  final String? partido;
  final String? agremiacao;
  final int? votos;
  final num? pct;
  final int? posicao;
  final String? projecao;
  final bool seguido;
  final bool principal;

  const ApuracaoBuscaItem({
    required this.sqcand,
    this.numero,
    required this.nome,
    required this.nomeUrna,
    this.cargo,
    this.cargoNome,
    this.uf,
    this.partido,
    this.agremiacao,
    this.votos,
    this.pct,
    this.posicao,
    this.projecao,
    this.seguido = false,
    this.principal = false,
  });

  factory ApuracaoBuscaItem.fromJson(Map<String, dynamic> json) =>
      ApuracaoBuscaItem(
        sqcand: parseString(json['sqcand']),
        numero: parseStringOrNull(json['numero']),
        nome: parseString(json['nome']),
        nomeUrna: parseString(json['nomeUrna'], json['nome']?.toString() ?? ''),
        cargo: parseIntOrNull(json['cargo']),
        cargoNome: parseStringOrNull(json['cargoNome']),
        uf: parseStringOrNull(json['uf']),
        partido: parseStringOrNull(json['partido']),
        agremiacao: parseStringOrNull(json['agremiacao']),
        votos: parseIntOrNull(json['votos']),
        pct: parseNum(json['pct']),
        posicao: parseIntOrNull(json['posicao']),
        projecao: parseStringOrNull(json['projecao']),
        seguido: parseBool(json['seguido']),
        principal: parseBool(json['principal']),
      );
}

/// Resposta de GET /api/mobile/apuracao/busca.
class ApuracaoBuscaModel {
  final List<ApuracaoBuscaItem> itens;

  const ApuracaoBuscaModel({this.itens = const []});

  factory ApuracaoBuscaModel.fromJson(Map<String, dynamic> json) =>
      ApuracaoBuscaModel(
        itens: parseList(json['itens'], ApuracaoBuscaItem.fromJson),
      );
}
