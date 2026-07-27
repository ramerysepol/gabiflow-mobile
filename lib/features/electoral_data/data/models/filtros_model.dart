class FiltrosModel {
  final List<int> anos;
  final List<String> ufs;
  final List<String> cargos;

  const FiltrosModel({
    required this.anos,
    required this.ufs,
    required this.cargos,
  });

  factory FiltrosModel.fromJson(Map<String, dynamic> json) {
    return FiltrosModel(
      anos: List<int>.from((json['anos'] as List? ?? []).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)),
      ufs: List<String>.from(json['ufs'] as List? ?? []),
      cargos: List<String>.from(json['cargos'] as List? ?? []),
    );
  }

  factory FiltrosModel.empty() => const FiltrosModel(anos: [], ufs: [], cargos: []);
}
