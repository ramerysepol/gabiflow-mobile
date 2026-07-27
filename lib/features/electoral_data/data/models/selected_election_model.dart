/// Representa a eleição selecionada pelo usuário (persistida em Hive).
class SelectedElection {
  final int ano;
  final String cargo;
  final String uf;

  const SelectedElection({
    required this.ano,
    required this.cargo,
    required this.uf,
  });

  /// Rótulo curto para exibição em chips e subtítulos.
  /// Ex.: "2022 · Dep. Federal · BA"
  String get label => '$ano · ${_cargoAbrev(cargo)} · $uf';

  /// Rótulo completo para o header.
  /// Ex.: "Eleições 2022 · Deputado Federal · BA"
  String get labelCompleto => 'Eleições $ano · ${_cargoCompleto(cargo)} · $uf';

  /// Normaliza: underscore → espaço + lowercase
  String _cargoNorm(String c) => c.toLowerCase().replaceAll('_', ' ').trim();

  String _cargoAbrev(String c) {
    final n = _cargoNorm(c);
    if (n.contains('deputado federal')) return 'Dep. Federal';
    if (n.contains('deputado estadual')) return 'Dep. Estadual';
    if (n.contains('senador')) return 'Senador';
    if (n.contains('governador')) return 'Governador';
    if (n.contains('presidente')) return 'Presidente';
    if (n.contains('prefeito')) return 'Prefeito';
    if (n.contains('vereador')) return 'Vereador';
    return c;
  }

  /// Capitaliza cada palavra: "deputado_federal" → "Deputado Federal"
  String _cargoCompleto(String c) {
    final n = _cargoNorm(c);
    return n
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  SelectedElection copyWith({int? ano, String? cargo, String? uf}) {
    return SelectedElection(
      ano: ano ?? this.ano,
      cargo: cargo ?? this.cargo,
      uf: uf ?? this.uf,
    );
  }

  Map<String, dynamic> toJson() => {'ano': ano, 'cargo': cargo, 'uf': uf};

  factory SelectedElection.fromJson(Map<String, dynamic> json) {
    return SelectedElection(
      ano: (json['ano'] as num).toInt(),
      cargo: json['cargo'] as String,
      uf: json['uf'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SelectedElection &&
      ano == other.ano &&
      cargo == other.cargo &&
      uf == other.uf;

  @override
  int get hashCode => Object.hash(ano, cargo, uf);
}
