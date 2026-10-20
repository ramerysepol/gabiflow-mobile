import 'apuracao_parse_utils.dart';

/// Cargo disputado numa eleição (ex.: Deputado Estadual, Governador).
class ApuracaoCargo {
  final int cd;
  final String nome;
  final String abr;

  const ApuracaoCargo({
    required this.cd,
    required this.nome,
    required this.abr,
  });

  factory ApuracaoCargo.fromJson(Map<String, dynamic> json) => ApuracaoCargo(
    cd: parseInt(json['cd']),
    nome: parseString(json['nome']),
    abr: parseString(json['abr']),
  );
}

/// Eleição disponível para apuração (ex.: Eleições 2026, 1º turno).
class ApuracaoEleicao {
  final dynamic cd;
  final String nome;
  final String? data;
  final int? turno;
  final String? tipo;
  final bool segundoTurno;
  final List<ApuracaoCargo> cargos;

  const ApuracaoEleicao({
    required this.cd,
    required this.nome,
    this.data,
    this.turno,
    this.tipo,
    this.segundoTurno = false,
    this.cargos = const [],
  });

  factory ApuracaoEleicao.fromJson(Map<String, dynamic> json) =>
      ApuracaoEleicao(
        cd: json['cd'],
        nome: parseString(json['nome']),
        data: parseStringOrNull(json['data']),
        turno: parseIntOrNull(json['turno']),
        tipo: parseStringOrNull(json['tipo']),
        segundoTurno: parseBool(json['segundoTurno']),
        cargos: parseList(json['cargos'], ApuracaoCargo.fromJson),
      );
}

/// Progresso de apuração de uma UF/cargo (usado para o indicador geral).
class ApuracaoProgressoUf {
  final String uf;
  final int cargo;
  final num? pctSecoes;
  final bool finalizado;
  final DateTime? atualizadoEm;

  const ApuracaoProgressoUf({
    required this.uf,
    required this.cargo,
    this.pctSecoes,
    this.finalizado = false,
    this.atualizadoEm,
  });

  factory ApuracaoProgressoUf.fromJson(Map<String, dynamic> json) =>
      ApuracaoProgressoUf(
        uf: parseString(json['uf']),
        cargo: parseInt(json['cargo']),
        pctSecoes: parseNum(json['pctSecoes']),
        finalizado: parseBool(json['finalizado']),
        atualizadoEm: parseDate(json['atualizadoEm']),
      );
}

/// Status geral da apuração ao vivo do TSE (GET /api/mobile/apuracao/status).
class ApuracaoStatusModel {
  final bool ativo;
  final dynamic ciclo;
  final DateTime? ultimaColeta;
  final DateTime? ultimaAlteracao;
  final int arquivos;
  final int arquivosComErro;
  final List<String> ufsDisponiveis;
  final List<ApuracaoEleicao> eleicoes;
  final List<ApuracaoProgressoUf> progresso;

  const ApuracaoStatusModel({
    required this.ativo,
    this.ciclo,
    this.ultimaColeta,
    this.ultimaAlteracao,
    this.arquivos = 0,
    this.arquivosComErro = 0,
    this.ufsDisponiveis = const [],
    this.eleicoes = const [],
    this.progresso = const [],
  });

  /// UFs disponíveis sem o agregado nacional ("br"), para seletores de UF.
  List<String> get ufsSelecionaveis =>
      ufsDisponiveis.where((uf) => uf.toLowerCase() != 'br').toList();

  factory ApuracaoStatusModel.fromJson(Map<String, dynamic> json) =>
      ApuracaoStatusModel(
        ativo: parseBool(json['ativo']),
        ciclo: json['ciclo'],
        ultimaColeta: parseDate(json['ultimaColeta']),
        ultimaAlteracao: parseDate(json['ultimaAlteracao']),
        arquivos: parseInt(json['arquivos']),
        arquivosComErro: parseInt(json['arquivosComErro']),
        ufsDisponiveis: (json['ufsDisponiveis'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        eleicoes: parseList(json['eleicoes'], ApuracaoEleicao.fromJson),
        progresso: parseList(json['progresso'], ApuracaoProgressoUf.fromJson),
      );
}
