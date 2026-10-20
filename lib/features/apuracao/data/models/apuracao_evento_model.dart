import 'apuracao_parse_utils.dart';

/// Dados extras de um evento do feed "Acontecendo agora", variam por [tipo].
class ApuracaoEventoDados {
  final bool? bom;
  final bool? ruim;
  final String? de;
  final String? para;
  final int? votos;
  final int? posicao;
  final String? marco;
  final String? abr;
  final String? cargo;
  final num? pctSecoes;

  const ApuracaoEventoDados({
    this.bom,
    this.ruim,
    this.de,
    this.para,
    this.votos,
    this.posicao,
    this.marco,
    this.abr,
    this.cargo,
    this.pctSecoes,
  });

  factory ApuracaoEventoDados.fromJson(Map<String, dynamic> json) =>
      ApuracaoEventoDados(
        bom: json['bom'] == null ? null : parseBool(json['bom']),
        ruim: json['ruim'] == null ? null : parseBool(json['ruim']),
        de: parseStringOrNull(json['de']),
        para: parseStringOrNull(json['para']),
        votos: parseIntOrNull(json['votos']),
        posicao: parseIntOrNull(json['posicao']),
        marco: parseStringOrNull(json['marco']),
        abr: parseStringOrNull(json['abr']),
        cargo: parseStringOrNull(json['cargo']),
        pctSecoes: parseNum(json['pctSecoes']),
      );
}

/// Item do feed "Acontecendo agora" (GET /api/mobile/apuracao/eventos):
/// um marco relevante da apuração (projeção mudou, subiu/caiu de posição,
/// virada de votos, novo lote apurado...).
class ApuracaoEvento {
  final int id;
  final String sqcand;

  /// 'projecao' | 'posicao' | 'votos' | 'apuracao'.
  final String tipo;

  /// 1 (baixa) a 3 (alta) — usada para decidir alerta local/banner.
  final int importancia;
  final String titulo;
  final String mensagem;
  final ApuracaoEventoDados dados;
  final DateTime em;
  final bool principal;
  final String nomeUrna;
  final String? numero;
  final String? partido;
  final String? cargoNome;
  final String? uf;

  const ApuracaoEvento({
    required this.id,
    required this.sqcand,
    required this.tipo,
    this.importancia = 1,
    required this.titulo,
    required this.mensagem,
    this.dados = const ApuracaoEventoDados(),
    required this.em,
    this.principal = false,
    required this.nomeUrna,
    this.numero,
    this.partido,
    this.cargoNome,
    this.uf,
  });

  factory ApuracaoEvento.fromJson(Map<String, dynamic> json) => ApuracaoEvento(
    id: parseInt(json['id']),
    sqcand: parseString(json['sqcand']),
    tipo: parseString(json['tipo']),
    importancia: parseInt(json['importancia'], 1),
    titulo: parseString(json['titulo']),
    mensagem: parseString(json['mensagem']),
    dados: json['dados'] == null
        ? const ApuracaoEventoDados()
        : ApuracaoEventoDados.fromJson(
            Map<String, dynamic>.from(json['dados'] as Map),
          ),
    em: parseDate(json['em']) ?? DateTime.now(),
    principal: parseBool(json['principal']),
    nomeUrna: parseString(json['nomeUrna']),
    numero: parseStringOrNull(json['numero']),
    partido: parseStringOrNull(json['partido']),
    cargoNome: parseStringOrNull(json['cargoNome']),
    uf: parseStringOrNull(json['uf']),
  );
}

/// Resposta de GET /api/mobile/apuracao/eventos.
class ApuracaoEventosModel {
  final List<ApuracaoEvento> itens;
  final DateTime? agora;

  const ApuracaoEventosModel({this.itens = const [], this.agora});

  factory ApuracaoEventosModel.fromJson(Map<String, dynamic> json) =>
      ApuracaoEventosModel(
        itens: parseList(json['itens'], ApuracaoEvento.fromJson),
        agora: parseDate(json['agora']),
      );
}
