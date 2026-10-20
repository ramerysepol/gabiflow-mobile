import 'apuracao_parse_utils.dart';

/// Município simples (GET /api/mobile/apuracao/municipios), usado no
/// seletor de município dos filtros.
class ApuracaoMunicipioSimples {
  final String cd;
  final String? ibge;
  final String nome;
  final bool capital;

  const ApuracaoMunicipioSimples({
    required this.cd,
    this.ibge,
    required this.nome,
    this.capital = false,
  });

  factory ApuracaoMunicipioSimples.fromJson(Map<String, dynamic> json) =>
      ApuracaoMunicipioSimples(
        cd: parseString(json['cd']),
        ibge: parseStringOrNull(json['ibge']),
        nome: parseString(json['nome']),
        capital: parseBool(json['capital']),
      );
}

/// Resposta de GET /api/mobile/apuracao/municipios.
class ApuracaoMunicipiosModel {
  final List<ApuracaoMunicipioSimples> itens;

  const ApuracaoMunicipiosModel({this.itens = const []});

  factory ApuracaoMunicipiosModel.fromJson(Map<String, dynamic> json) =>
      ApuracaoMunicipiosModel(
        itens: parseList(json['itens'], ApuracaoMunicipioSimples.fromJson),
      );
}
