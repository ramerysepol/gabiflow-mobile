import 'apuracao_parse_utils.dart';
import 'apuracao_ranking_model.dart';

/// Dados cadastrais do candidato (ficha).
class ApuracaoCandidatoInfo {
  final String sqcand;
  final dynamic eleicao;
  final String? uf;
  final int? cargo;
  final String? cargoNome;
  final String? numero;
  final String nome;
  final String nomeUrna;
  final String? partido;
  final String? partidoNome;
  final String? federacao;
  final String? agremiacao;
  final String? agremiacaoTipo;
  final String? vices;
  final String? dataNasc;
  final bool seguido;
  final bool principal;

  const ApuracaoCandidatoInfo({
    required this.sqcand,
    this.eleicao,
    this.uf,
    this.cargo,
    this.cargoNome,
    this.numero,
    required this.nome,
    required this.nomeUrna,
    this.partido,
    this.partidoNome,
    this.federacao,
    this.agremiacao,
    this.agremiacaoTipo,
    this.vices,
    this.dataNasc,
    this.seguido = false,
    this.principal = false,
  });

  factory ApuracaoCandidatoInfo.fromJson(Map<String, dynamic> json) =>
      ApuracaoCandidatoInfo(
        sqcand: parseString(json['sqcand']),
        eleicao: json['eleicao'],
        uf: parseStringOrNull(json['uf']),
        cargo: parseIntOrNull(json['cargo']),
        cargoNome: parseStringOrNull(json['cargoNome']),
        numero: parseStringOrNull(json['numero']),
        nome: parseString(json['nome']),
        nomeUrna: parseString(json['nomeUrna'], json['nome']?.toString() ?? ''),
        partido: parseStringOrNull(json['partido']),
        partidoNome: parseStringOrNull(json['partidoNome']),
        federacao: parseStringOrNull(json['federacao']),
        agremiacao: parseStringOrNull(json['agremiacao']),
        agremiacaoTipo: parseStringOrNull(json['agremiacaoTipo']),
        vices: parseStringOrNull(json['vices']),
        dataNasc: parseStringOrNull(json['dataNasc']),
        seguido: parseBool(json['seguido']),
        principal: parseBool(json['principal']),
      );
}

/// Colega de partido/federação na mesma disputa.
class ApuracaoColega {
  final String sqcand;
  final String? numero;
  final String nomeUrna;
  final String? partido;
  final int votos;
  final num? pct;
  final int? posicao;
  final int? posicaoAgr;
  final String? projecao;

  const ApuracaoColega({
    required this.sqcand,
    this.numero,
    required this.nomeUrna,
    this.partido,
    this.votos = 0,
    this.pct,
    this.posicao,
    this.posicaoAgr,
    this.projecao,
  });

  factory ApuracaoColega.fromJson(Map<String, dynamic> json) => ApuracaoColega(
    sqcand: parseString(json['sqcand']),
    numero: parseStringOrNull(json['numero']),
    nomeUrna: parseString(json['nomeUrna']),
    partido: parseStringOrNull(json['partido']),
    votos: parseInt(json['votos']),
    pct: parseNum(json['pct']),
    posicao: parseIntOrNull(json['posicao']),
    posicaoAgr: parseIntOrNull(json['posicaoAgr']),
    projecao: parseStringOrNull(json['projecao']),
  );
}

/// Partido/federação do candidato, com colegas de chapa.
class ApuracaoAgremiacaoCandidato {
  final String? n;
  final String nome;
  final String sigla;
  final String? tipo;
  final int votosValidos;
  final int votosNominais;
  final int votosLegenda;
  final int? vagasTse;
  final int? vagasQp;
  final int? vagasSobras;
  final int? vagasProjetadas;
  final List<ApuracaoColega> colegas;

  const ApuracaoAgremiacaoCandidato({
    this.n,
    required this.nome,
    required this.sigla,
    this.tipo,
    this.votosValidos = 0,
    this.votosNominais = 0,
    this.votosLegenda = 0,
    this.vagasTse,
    this.vagasQp,
    this.vagasSobras,
    this.vagasProjetadas,
    this.colegas = const [],
  });

  int get vagas => vagasProjetadas ?? vagasTse ?? 0;

  factory ApuracaoAgremiacaoCandidato.fromJson(Map<String, dynamic> json) =>
      ApuracaoAgremiacaoCandidato(
        n: parseStringOrNull(json['n']),
        nome: parseString(json['nome']),
        sigla: parseString(json['sigla']),
        tipo: parseStringOrNull(json['tipo']),
        votosValidos: parseInt(json['votosValidos']),
        votosNominais: parseInt(json['votosNominais']),
        votosLegenda: parseInt(json['votosLegenda']),
        vagasTse: parseIntOrNull(json['vagasTse']),
        vagasQp: parseIntOrNull(json['vagasQp']),
        vagasSobras: parseIntOrNull(json['vagasSobras']),
        vagasProjetadas: parseIntOrNull(json['vagasProjetadas']),
        colegas: parseList(json['colegas'], ApuracaoColega.fromJson),
      );
}

/// Concorrente direto (vizinho na disputa) do candidato.
class ApuracaoVizinho {
  final String sqcand;
  final String? numero;
  final String nomeUrna;
  final String? partido;
  final String? agremiacao;
  final int votos;
  final num? pct;
  final int? posicao;
  final String? projecao;

  const ApuracaoVizinho({
    required this.sqcand,
    this.numero,
    required this.nomeUrna,
    this.partido,
    this.agremiacao,
    this.votos = 0,
    this.pct,
    this.posicao,
    this.projecao,
  });

  factory ApuracaoVizinho.fromJson(Map<String, dynamic> json) =>
      ApuracaoVizinho(
        sqcand: parseString(json['sqcand']),
        numero: parseStringOrNull(json['numero']),
        nomeUrna: parseString(json['nomeUrna']),
        partido: parseStringOrNull(json['partido']),
        agremiacao: parseStringOrNull(json['agremiacao']),
        votos: parseInt(json['votos']),
        pct: parseNum(json['pct']),
        posicao: parseIntOrNull(json['posicao']),
        projecao: parseStringOrNull(json['projecao']),
      );
}

/// Votação do candidato em um município.
class ApuracaoMunicipioVoto {
  final String cd;
  final String nome;
  final bool capital;
  final int votos;
  final num? pct;
  final int? posicao;
  final int? votosValidos;
  final num? pctSecoes;
  final bool finalizado;
  final int? eleitorado;

  /// Código IBGE do município (pode ser `null` quando o cruzamento com a
  /// base do TSE ainda não foi feito); usado para cruzar com o mapa de
  /// calor do GabiFlow (ver `MapaBaWidget`).
  final String? ibge;

  const ApuracaoMunicipioVoto({
    required this.cd,
    required this.nome,
    this.capital = false,
    this.votos = 0,
    this.pct,
    this.posicao,
    this.votosValidos,
    this.pctSecoes,
    this.finalizado = false,
    this.eleitorado,
    this.ibge,
  });

  factory ApuracaoMunicipioVoto.fromJson(Map<String, dynamic> json) =>
      ApuracaoMunicipioVoto(
        cd: parseString(json['cd']),
        nome: parseString(json['nome']),
        capital: parseBool(json['capital']),
        votos: parseInt(json['votos']),
        pct: parseNum(json['pct']),
        posicao: parseIntOrNull(json['posicao']),
        votosValidos: parseIntOrNull(json['votosValidos']),
        pctSecoes: parseNum(json['pctSecoes']),
        finalizado: parseBool(json['finalizado']),
        eleitorado: parseIntOrNull(json['eleitorado']),
        ibge: parseStringOrNull(json['ibge']),
      );
}

/// Candidato de referência da linha de corte: o 1º suplente do partido
/// (quando o candidato já está eleito) ou o último eleito pela mesma vaga
/// (quando ainda falta votos).
class ApuracaoCorteReferencia {
  final String sqcand;
  final String nomeUrna;
  final int votos;

  /// 'primeiro_suplente' | 'ultimo_eleito'.
  final String papel;

  const ApuracaoCorteReferencia({
    required this.sqcand,
    required this.nomeUrna,
    required this.votos,
    required this.papel,
  });

  factory ApuracaoCorteReferencia.fromJson(Map<String, dynamic> json) =>
      ApuracaoCorteReferencia(
        sqcand: parseString(json['sqcand']),
        nomeUrna: parseString(json['nomeUrna']),
        votos: parseInt(json['votos']),
        papel: parseString(json['papel']),
      );
}

/// Líder da disputa majoritária (prefeito/governador/senador/presidente).
class ApuracaoCorteLider {
  final String sqcand;
  final String nomeUrna;
  final int votos;

  const ApuracaoCorteLider({
    required this.sqcand,
    required this.nomeUrna,
    required this.votos,
  });

  factory ApuracaoCorteLider.fromJson(Map<String, dynamic> json) =>
      ApuracaoCorteLider(
        sqcand: parseString(json['sqcand']),
        nomeUrna: parseString(json['nomeUrna']),
        votos: parseInt(json['votos']),
      );
}

/// "Linha de corte" da disputa do candidato: o quão perto ele está de ser
/// eleito (proporcional: quociente partidário/sobras; majoritário: maioria
/// absoluta ou a dianteira sobre o 2º colocado).
class ApuracaoCorte {
  /// 'proporcional' | 'majoritario'.
  final String tipo;

  final bool eleito;

  // --- Proporcional ---
  final int? qe;
  final int? vagasAgr;
  final int? minimoIndividual;
  final bool? atingeMinimo;
  final int? margem;
  final int? faltam;
  final ApuracaoCorteReferencia? referencia;
  final bool semVagaNaAgr;
  final int? proximaVagaQp;

  // --- Majoritário ---
  final int? validos;
  final int? maioriaAbsoluta;
  final int? faltamMaioria;
  final int? diferencaLider;
  final ApuracaoCorteLider? lider;
  final bool segundoTurno;

  bool get isProporcional => tipo == 'proporcional';
  bool get isMajoritario => tipo == 'majoritario';

  const ApuracaoCorte({
    required this.tipo,
    this.eleito = false,
    this.qe,
    this.vagasAgr,
    this.minimoIndividual,
    this.atingeMinimo,
    this.margem,
    this.faltam,
    this.referencia,
    this.semVagaNaAgr = false,
    this.proximaVagaQp,
    this.validos,
    this.maioriaAbsoluta,
    this.faltamMaioria,
    this.diferencaLider,
    this.lider,
    this.segundoTurno = false,
  });

  factory ApuracaoCorte.fromJson(Map<String, dynamic> json) => ApuracaoCorte(
    tipo: parseString(json['tipo']),
    eleito: parseBool(json['eleito']),
    qe: parseIntOrNull(json['qe']),
    vagasAgr: parseIntOrNull(json['vagasAgr']),
    minimoIndividual: parseIntOrNull(json['minimoIndividual']),
    atingeMinimo: json['atingeMinimo'] == null
        ? null
        : parseBool(json['atingeMinimo']),
    margem: parseIntOrNull(json['margem']),
    faltam: parseIntOrNull(json['faltam']),
    referencia: json['referencia'] == null
        ? null
        : ApuracaoCorteReferencia.fromJson(
            Map<String, dynamic>.from(json['referencia'] as Map),
          ),
    semVagaNaAgr: parseBool(json['semVagaNaAgr']),
    proximaVagaQp: parseIntOrNull(json['proximaVagaQp']),
    validos: parseIntOrNull(json['validos']),
    maioriaAbsoluta: parseIntOrNull(json['maioriaAbsoluta']),
    faltamMaioria: parseIntOrNull(json['faltamMaioria']),
    diferencaLider: parseIntOrNull(json['diferencaLider']),
    lider: json['lider'] == null
        ? null
        : ApuracaoCorteLider.fromJson(
            Map<String, dynamic>.from(json['lider'] as Map),
          ),
    segundoTurno: parseBool(json['segundoTurno']),
  );
}

/// Resumo de quantos municípios já têm dado / foram totalizados.
class ApuracaoMunicipiosResumo {
  final int total;
  final int finalizados;
  final int comVotos;

  const ApuracaoMunicipiosResumo({
    this.total = 0,
    this.finalizados = 0,
    this.comVotos = 0,
  });

  factory ApuracaoMunicipiosResumo.fromJson(Map<String, dynamic> json) =>
      ApuracaoMunicipiosResumo(
        total: parseInt(json['total']),
        finalizados: parseInt(json['finalizados']),
        comVotos: parseInt(json['comVotos']),
      );
}

/// Ponto da série histórica do candidato (evolução da votação).
class ApuracaoHistoricoPonto {
  final int votos;
  final num? pct;
  final int? posicao;
  final String? projecao;
  final num? pctSecoes;
  final DateTime? em;

  const ApuracaoHistoricoPonto({
    this.votos = 0,
    this.pct,
    this.posicao,
    this.projecao,
    this.pctSecoes,
    this.em,
  });

  factory ApuracaoHistoricoPonto.fromJson(Map<String, dynamic> json) =>
      ApuracaoHistoricoPonto(
        votos: parseInt(json['votos']),
        pct: parseNum(json['pct']),
        posicao: parseIntOrNull(json['posicao']),
        projecao: parseStringOrNull(json['projecao']),
        pctSecoes: parseNum(json['pctSecoes']),
        em: parseDate(json['em']),
      );
}

/// Resposta de GET /api/mobile/apuracao/candidato/{sqcand}.
class ApuracaoCandidatoModel {
  final ApuracaoCandidatoInfo candidato;
  final ApuracaoCandVoto? geral;
  final ApuracaoResumo? resumo;
  final ApuracaoAgremiacaoCandidato? agremiacao;
  final List<ApuracaoVizinho> vizinhos;
  final List<ApuracaoMunicipioVoto> municipios;
  final ApuracaoMunicipiosResumo municipiosResumo;
  final List<ApuracaoHistoricoPonto> historico;

  /// Linha de corte: o quão perto o candidato está de ser eleito.
  final ApuracaoCorte? corte;

  const ApuracaoCandidatoModel({
    required this.candidato,
    this.geral,
    this.resumo,
    this.agremiacao,
    this.vizinhos = const [],
    this.municipios = const [],
    this.municipiosResumo = const ApuracaoMunicipiosResumo(),
    this.historico = const [],
    this.corte,
  });

  factory ApuracaoCandidatoModel.fromJson(
    Map<String, dynamic> json,
  ) => ApuracaoCandidatoModel(
    candidato: ApuracaoCandidatoInfo.fromJson(
      Map<String, dynamic>.from(json['candidato'] as Map? ?? const {}),
    ),
    geral: json['geral'] == null
        ? null
        : ApuracaoCandVoto.fromJson(
            Map<String, dynamic>.from(json['geral'] as Map),
          ),
    resumo: json['resumo'] == null
        ? null
        : ApuracaoResumo.fromJson(
            Map<String, dynamic>.from(json['resumo'] as Map),
          ),
    agremiacao: json['agremiacao'] == null
        ? null
        : ApuracaoAgremiacaoCandidato.fromJson(
            Map<String, dynamic>.from(json['agremiacao'] as Map),
          ),
    vizinhos: parseList(json['vizinhos'], ApuracaoVizinho.fromJson),
    municipios: parseList(json['municipios'], ApuracaoMunicipioVoto.fromJson),
    municipiosResumo: json['municipiosResumo'] == null
        ? const ApuracaoMunicipiosResumo()
        : ApuracaoMunicipiosResumo.fromJson(
            Map<String, dynamic>.from(json['municipiosResumo'] as Map),
          ),
    historico: parseList(json['historico'], ApuracaoHistoricoPonto.fromJson),
    corte: json['corte'] == null
        ? null
        : ApuracaoCorte.fromJson(
            Map<String, dynamic>.from(json['corte'] as Map),
          ),
  );
}
