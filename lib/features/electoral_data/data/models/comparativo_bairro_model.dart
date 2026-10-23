int _int(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

/// Identificação resumida de um candidato no comparativo.
class CandidatoResumoModel {
  final String sequencial;
  final String nomeUrna;
  final String partido;
  final String numero;
  final String cargo;

  const CandidatoResumoModel({
    required this.sequencial,
    required this.nomeUrna,
    required this.partido,
    required this.numero,
    required this.cargo,
  });

  factory CandidatoResumoModel.fromJson(Map<String, dynamic> j) =>
      CandidatoResumoModel(
        sequencial: j['sequencial']?.toString() ?? '',
        nomeUrna: j['nomeUrna']?.toString() ?? j['nome_urna']?.toString() ?? '',
        partido: j['partido']?.toString() ?? '',
        numero: j['numero']?.toString() ?? '',
        cargo: j['cargo']?.toString() ?? '',
      );
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

class BairroComparativoItem {
  final String bairro;
  final int votosA;
  final int votosB;
  final int secoes;

  const BairroComparativoItem({
    required this.bairro,
    required this.votosA,
    required this.votosB,
    required this.secoes,
  });

  int get diferenca => votosA - votosB;

  factory BairroComparativoItem.fromJson(Map<String, dynamic> j) =>
      BairroComparativoItem(
        bairro: j['bairro']?.toString() ?? '',
        votosA: _int(j['votosA']),
        votosB: _int(j['votosB']),
        secoes: _int(j['secoes']),
      );
}

class BairrosComparativoModel {
  final CandidatoResumoModel a;
  final CandidatoResumoModel b;
  final List<BairroComparativoItem> bairros;
  final int totalVotosA;
  final int totalVotosB;
  final int totalBairros;
  final int totalSecoes;

  const BairrosComparativoModel({
    required this.a,
    required this.b,
    required this.bairros,
    required this.totalVotosA,
    required this.totalVotosB,
    required this.totalBairros,
    required this.totalSecoes,
  });

  factory BairrosComparativoModel.fromJson(Map<String, dynamic> j) {
    final c = _map(j['candidatos']);
    final t = _map(j['totais']);
    return BairrosComparativoModel(
      a: CandidatoResumoModel.fromJson(_map(c['a'])),
      b: CandidatoResumoModel.fromJson(_map(c['b'])),
      bairros: (j['bairros'] as List? ?? [])
          .map((e) => BairroComparativoItem.fromJson(_map(e)))
          .toList(),
      totalVotosA: _int(t['votosA']),
      totalVotosB: _int(t['votosB']),
      totalBairros: _int(t['bairros']),
      totalSecoes: _int(t['secoes']),
    );
  }
}

class SecaoComparativoItem {
  final String zona;
  final String secao;
  final String local;
  final String endereco;
  final int votosA;
  final int votosB;

  const SecaoComparativoItem({
    required this.zona,
    required this.secao,
    required this.local,
    required this.endereco,
    required this.votosA,
    required this.votosB,
  });

  int get diferenca => votosA - votosB;

  factory SecaoComparativoItem.fromJson(Map<String, dynamic> j) =>
      SecaoComparativoItem(
        zona: j['zona']?.toString() ?? '',
        secao: j['secao']?.toString() ?? '',
        local: j['local']?.toString() ?? '',
        endereco: j['endereco']?.toString() ?? '',
        votosA: _int(j['votosA']),
        votosB: _int(j['votosB']),
      );
}

class SecoesComparativoModel {
  final CandidatoResumoModel a;
  final CandidatoResumoModel b;
  final List<SecaoComparativoItem> secoes;
  final int totalVotosA;
  final int totalVotosB;
  final int totalSecoes;
  final int secoesComAmbos;
  final int secoesSoA;
  final int secoesSoB;
  final int secoesSemNenhum;

  const SecoesComparativoModel({
    required this.a,
    required this.b,
    required this.secoes,
    required this.totalVotosA,
    required this.totalVotosB,
    required this.totalSecoes,
    required this.secoesComAmbos,
    required this.secoesSoA,
    required this.secoesSoB,
    required this.secoesSemNenhum,
  });

  factory SecoesComparativoModel.fromJson(Map<String, dynamic> j) {
    final c = _map(j['candidatos']);
    final t = _map(j['totais']);
    return SecoesComparativoModel(
      a: CandidatoResumoModel.fromJson(_map(c['a'])),
      b: CandidatoResumoModel.fromJson(_map(c['b'])),
      secoes: (j['secoes'] as List? ?? [])
          .map((e) => SecaoComparativoItem.fromJson(_map(e)))
          .toList(),
      totalVotosA: _int(t['votosA']),
      totalVotosB: _int(t['votosB']),
      totalSecoes: _int(t['secoes']),
      secoesComAmbos: _int(t['secoesComAmbos']),
      secoesSoA: _int(t['secoesSoA']),
      secoesSoB: _int(t['secoesSoB']),
      secoesSemNenhum: _int(t['secoesSemNenhum']),
    );
  }
}
