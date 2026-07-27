import 'candidato_stats_model.dart';

class ComparacaoCandidatoModel {
  final String sequencial;
  final String nome;
  final String nomeUrna;
  final String partido;
  final String siglaPartido;
  final String cargo;
  final String? fotoUrl;
  final CandidatoStatsModel stats;

  const ComparacaoCandidatoModel({
    required this.sequencial,
    required this.nome,
    required this.nomeUrna,
    required this.partido,
    required this.siglaPartido,
    required this.cargo,
    this.fotoUrl,
    required this.stats,
  });

  factory ComparacaoCandidatoModel.fromJson(Map<String, dynamic> json) {
    // Backend devolve `votos_total`/`municipios_atingidos` direto no root
    // do candidato (sem chave `stats` aninhada). Se não houver `stats`, usa
    // o próprio JSON como origem dos stats.
    final statsSrc = json['stats'] is Map<String, dynamic>
        ? json['stats'] as Map<String, dynamic>
        : json;
    final partido = (json['partido'] as String?) ?? '';
    return ComparacaoCandidatoModel(
      sequencial: json['sequencial']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      nomeUrna: (json['nome_urna'] as String?) ?? (json['nome'] as String? ?? ''),
      partido: partido,
      siglaPartido: (json['sigla_partido'] as String?) ?? partido,
      cargo: json['cargo'] as String? ?? '',
      fotoUrl: json['foto_url'] as String?,
      stats: CandidatoStatsModel.fromJson(statsSrc),
    );
  }
}

class DiffMunicipioModel {
  final String idMunicipio;
  final String nomeMunicipio;
  final int votosA;
  final int votosB;
  final int diferenca;
  final String vencedor; // 'a' | 'b' | 'empate'

  const DiffMunicipioModel({
    required this.idMunicipio,
    required this.nomeMunicipio,
    required this.votosA,
    required this.votosB,
    required this.diferenca,
    required this.vencedor,
  });

  factory DiffMunicipioModel.fromJson(Map<String, dynamic> json) {
    return DiffMunicipioModel(
      idMunicipio: json['id_municipio']?.toString() ?? '',
      nomeMunicipio: json['nome_municipio'] as String? ?? '',
      votosA: _parseInt(json['votos_a']),
      votosB: _parseInt(json['votos_b']),
      diferenca: _parseInt(json['diferenca']),
      vencedor: json['vencedor'] as String? ?? 'empate',
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

class ComparacaoModel {
  final List<ComparacaoCandidatoModel> candidatos;
  final List<DiffMunicipioModel> diffMunicipios;

  const ComparacaoModel({required this.candidatos, required this.diffMunicipios});

  factory ComparacaoModel.fromJson(Map<String, dynamic> json) {
    return ComparacaoModel(
      candidatos: (json['candidatos'] as List? ?? [])
          .map((e) => ComparacaoCandidatoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      diffMunicipios: (json['diff_municipios'] as List? ?? [])
          .map((e) => DiffMunicipioModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
