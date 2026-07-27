class RankingItemModel {
  final String id;
  final String nome;
  final int totalVotos;
  final int eleitos;

  const RankingItemModel({
    required this.id,
    required this.nome,
    required this.totalVotos,
    required this.eleitos,
  });

  factory RankingItemModel.fromJson(Map<String, dynamic> json) {
    return RankingItemModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      totalVotos: _parseInt(json['total_votos']),
      eleitos: _parseInt(json['eleitos']),
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

class RankingModel {
  final String tipo;
  final List<RankingItemModel> items;

  const RankingModel({required this.tipo, required this.items});

  factory RankingModel.fromJson(Map<String, dynamic> json) {
    return RankingModel(
      tipo: json['tipo'] as String? ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => RankingItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
