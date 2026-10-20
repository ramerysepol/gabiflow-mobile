import 'apuracao_parse_utils.dart';
import 'apuracao_ranking_model.dart';

/// Votação/vagas de um partido ou federação numa abrangência.
class ApuracaoAgremiacao {
  final String? n;
  final String nome;
  final String sigla;
  final String? tipo;
  final List<String> partidos;
  final int votosNominais;
  final int votosLegenda;
  final int votosValidos;
  final int? vagasTse;
  final int? vagasQp;
  final int? vagasSobras;
  final int? vagasProjetadas;

  const ApuracaoAgremiacao({
    this.n,
    required this.nome,
    required this.sigla,
    this.tipo,
    this.partidos = const [],
    this.votosNominais = 0,
    this.votosLegenda = 0,
    this.votosValidos = 0,
    this.vagasTse,
    this.vagasQp,
    this.vagasSobras,
    this.vagasProjetadas,
  });

  /// Vagas a exibir: prioriza a projeção (quociente+sobras), cai para a
  /// confirmada pelo TSE quando ainda não há projeção.
  int get vagas => vagasProjetadas ?? vagasTse ?? 0;

  factory ApuracaoAgremiacao.fromJson(Map<String, dynamic> json) =>
      ApuracaoAgremiacao(
        n: parseStringOrNull(json['n']),
        nome: parseString(json['nome']),
        sigla: parseString(json['sigla']),
        tipo: parseStringOrNull(json['tipo']),
        partidos: (json['partidos'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        votosNominais: parseInt(json['votosNominais']),
        votosLegenda: parseInt(json['votosLegenda']),
        votosValidos: parseInt(json['votosValidos']),
        vagasTse: parseIntOrNull(json['vagasTse']),
        vagasQp: parseIntOrNull(json['vagasQp']),
        vagasSobras: parseIntOrNull(json['vagasSobras']),
        vagasProjetadas: parseIntOrNull(json['vagasProjetadas']),
      );
}

/// Ponto da série de progresso da apuração (seções x votos ao longo do tempo).
class ApuracaoProgressoPonto {
  final num? pctSecoes;
  final int? votosValidos;
  final DateTime? em;

  const ApuracaoProgressoPonto({this.pctSecoes, this.votosValidos, this.em});

  factory ApuracaoProgressoPonto.fromJson(Map<String, dynamic> json) =>
      ApuracaoProgressoPonto(
        pctSecoes: parseNum(json['pctSecoes']),
        votosValidos: parseIntOrNull(json['votosValidos']),
        em: parseDate(json['em']),
      );
}

/// Resposta de GET /api/mobile/apuracao/resumo.
class ApuracaoResumoDetalheModel {
  final ApuracaoAbrangencia abrangencia;
  final ApuracaoResumo? resumo;
  final List<ApuracaoAgremiacao> agremiacoes;
  final List<ApuracaoProgressoPonto> progresso;

  const ApuracaoResumoDetalheModel({
    required this.abrangencia,
    this.resumo,
    this.agremiacoes = const [],
    this.progresso = const [],
  });

  /// Só vale mostrar a seção de vagas por partido quando já existe alguma
  /// vaga confirmada ou projetada.
  bool get temVagas => agremiacoes.any(
    (a) => (a.vagasProjetadas ?? 0) > 0 || (a.vagasTse ?? 0) > 0,
  );

  factory ApuracaoResumoDetalheModel.fromJson(
    Map<String, dynamic> json,
  ) => ApuracaoResumoDetalheModel(
    abrangencia: ApuracaoAbrangencia.fromJson(
      Map<String, dynamic>.from(json['abrangencia'] as Map? ?? const {}),
    ),
    resumo: json['resumo'] == null
        ? null
        : ApuracaoResumo.fromJson(
            Map<String, dynamic>.from(json['resumo'] as Map),
          ),
    agremiacoes: parseList(json['agremiacoes'], ApuracaoAgremiacao.fromJson),
    progresso: parseList(json['progresso'], ApuracaoProgressoPonto.fromJson),
  );
}
