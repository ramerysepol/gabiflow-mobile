class HierarquiaItemModel {
  final String id;
  final String nome;
  final int votosTotal;
  final double percentual;
  final bool temFilhos;
  // Extras opcionais (zona/secao trazem local de votação e metadados)
  final String? zona;
  final String? secao;
  final String? localVotacao;
  final String? endereco;
  final String? bairro;

  const HierarquiaItemModel({
    required this.id,
    required this.nome,
    required this.votosTotal,
    required this.percentual,
    required this.temFilhos,
    this.zona,
    this.secao,
    this.localVotacao,
    this.endereco,
    this.bairro,
  });

  factory HierarquiaItemModel.fromJson(Map<String, dynamic> json) {
    return HierarquiaItemModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      // Backend mobile devolve `votos`; fallback pra `votos_total` por compat.
      votosTotal: _parseInt(json['votos'] ?? json['votos_total']),
      percentual: _parseDouble(json['percentual']),
      temFilhos: json['tem_filhos'] as bool? ?? false,
      zona: json['zona']?.toString(),
      secao: json['secao']?.toString(),
      localVotacao: json['local_votacao'] as String?,
      endereco: json['endereco'] as String?,
      bairro: json['bairro'] as String?,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class HierarquiaNivelModel {
  final String nivel;
  final List<HierarquiaItemModel> items;

  const HierarquiaNivelModel({required this.nivel, required this.items});

  factory HierarquiaNivelModel.fromJson(Map<String, dynamic> json) {
    return HierarquiaNivelModel(
      nivel: json['nivel'] as String? ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => HierarquiaItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Hierarquias disponíveis
abstract final class HierarquiaNivel {
  static const mesorregiao = 'mesorregiao';
  static const microrregiao = 'microrregiao';
  static const municipio = 'municipio';
  static const bairro = 'bairro';
  static const zona = 'zona';
  static const secao = 'secao';

  static const ordered = [mesorregiao, microrregiao, municipio, bairro, zona, secao];

  static String label(String nivel) {
    switch (nivel) {
      case mesorregiao: return 'Mesorregião';
      case microrregiao: return 'Microrregião';
      case municipio: return 'Município';
      case bairro: return 'Bairro';
      case zona: return 'Zona';
      case secao: return 'Seção';
      default: return nivel;
    }
  }

  static String? proximo(String nivel) {
    final idx = ordered.indexOf(nivel);
    if (idx == -1 || idx >= ordered.length - 1) return null;
    return ordered[idx + 1];
  }
}
