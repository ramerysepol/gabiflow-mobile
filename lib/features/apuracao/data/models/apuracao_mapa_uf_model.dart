import 'apuracao_parse_utils.dart';
import 'apuracao_ranking_model.dart';

/// Candidato dentro de um estado (top-N da UF), já ordenado por posição
/// (índice 0 = líder no estado).
class ApuracaoEstadoCandidato {
  final String sqcand;
  final String? numero;
  final String nomeUrna;
  final String? partido;
  final int votos;
  final num? pct;
  final int? posicao;

  const ApuracaoEstadoCandidato({
    required this.sqcand,
    this.numero,
    required this.nomeUrna,
    this.partido,
    this.votos = 0,
    this.pct,
    this.posicao,
  });

  factory ApuracaoEstadoCandidato.fromJson(Map<String, dynamic> json) =>
      ApuracaoEstadoCandidato(
        sqcand: parseString(json['sqcand']),
        numero: parseStringOrNull(json['numero']),
        nomeUrna: parseString(json['nomeUrna']),
        partido: parseStringOrNull(json['partido']),
        votos: parseInt(json['votos']),
        pct: parseNum(json['pct']),
        posicao: parseIntOrNull(json['posicao']),
      );
}

/// Apuração de um estado (item de `estados` em GET /apuracao/mapa-uf).
class ApuracaoEstadoUf {
  /// Sigla em MAIÚSCULAS (a API devolve minúscula; normalizado aqui).
  final String uf;
  final num? pctSecoes;
  final int? secoesTotal;
  final int? secoesTotalizadas;
  final int? votosValidos;
  final int? votosTotal;
  final int? comparecimento;
  final num? pctComparecimento;
  final int? brancos;
  final int? nulos;
  final bool finalizado;
  final DateTime? atualizadoEm;
  final List<ApuracaoEstadoCandidato> candidatos;

  const ApuracaoEstadoUf({
    required this.uf,
    this.pctSecoes,
    this.secoesTotal,
    this.secoesTotalizadas,
    this.votosValidos,
    this.votosTotal,
    this.comparecimento,
    this.pctComparecimento,
    this.brancos,
    this.nulos,
    this.finalizado = false,
    this.atualizadoEm,
    this.candidatos = const [],
  });

  /// Líder do estado, ou `null` enquanto não há votos computados.
  ApuracaoEstadoCandidato? get lider {
    if (candidatos.isEmpty || candidatos.first.votos <= 0) return null;
    return candidatos.first;
  }

  ApuracaoEstadoCandidato? get segundo {
    if (candidatos.length < 2 || candidatos[1].votos <= 0) return null;
    return candidatos[1];
  }

  factory ApuracaoEstadoUf.fromJson(Map<String, dynamic> json) =>
      ApuracaoEstadoUf(
        uf: parseString(json['uf']).toUpperCase(),
        pctSecoes: parseNum(json['pctSecoes']),
        secoesTotal: parseIntOrNull(json['secoesTotal']),
        secoesTotalizadas: parseIntOrNull(json['secoesTotalizadas']),
        votosValidos: parseIntOrNull(json['votosValidos']),
        votosTotal: parseIntOrNull(json['votosTotal']),
        comparecimento: parseIntOrNull(json['comparecimento']),
        pctComparecimento: parseNum(json['pctComparecimento']),
        brancos: parseIntOrNull(json['brancos']),
        nulos: parseIntOrNull(json['nulos']),
        finalizado: parseBool(json['finalizado']),
        atualizadoEm: parseDate(json['atualizadoEm']),
        candidatos: parseList(
          json['candidatos'],
          ApuracaoEstadoCandidato.fromJson,
        ),
      );
}

/// Resposta de GET /api/mobile/apuracao/mapa-uf.
///
/// `abrangencia`, `resumo` e `itens` têm o mesmo shape do `/ranking`
/// (reaproveita [ApuracaoResumo] e [ApuracaoCandVoto]); `estados` é novo.
class ApuracaoMapaUfModel {
  final ApuracaoAbrangencia abrangencia;
  final ApuracaoResumo? resumo;
  final int total;
  final List<ApuracaoCandVoto> itens;
  final List<ApuracaoEstadoUf> estados;

  const ApuracaoMapaUfModel({
    required this.abrangencia,
    this.resumo,
    this.total = 0,
    this.itens = const [],
    this.estados = const [],
  });

  /// Ainda sem nenhum dado do TSE (antes do primeiro boletim).
  bool get aguardando => resumo == null && itens.isEmpty && estados.isEmpty;

  factory ApuracaoMapaUfModel.fromJson(Map<String, dynamic> json) =>
      ApuracaoMapaUfModel(
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
        estados: parseList(json['estados'], ApuracaoEstadoUf.fromJson),
      );
}
