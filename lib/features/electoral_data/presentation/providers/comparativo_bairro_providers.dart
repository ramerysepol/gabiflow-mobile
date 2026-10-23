import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/comparativo_bairro_model.dart';
import 'eleitoral_providers.dart';

/// Parâmetros do comparativo A×B. `bairro == null` => nível de bairros.
class ComparativoParams {
  final String municipio; // IBGE 7
  final String candA;
  final String candB;
  final String? bairro;

  const ComparativoParams({
    required this.municipio,
    required this.candA,
    required this.candB,
    this.bairro,
  });

  @override
  bool operator ==(Object other) =>
      other is ComparativoParams &&
      municipio == other.municipio &&
      candA == other.candA &&
      candB == other.candB &&
      bairro == other.bairro;

  @override
  int get hashCode => Object.hash(municipio, candA, candB, bairro);
}

final bairrosComparativoProvider = FutureProvider.autoDispose
    .family<BairrosComparativoModel, ComparativoParams>((ref, p) {
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(eleitoralDatasourceProvider).getBairrosComparativo(
        ano: filtros.ano,
        estado: filtros.estado,
        municipio: p.municipio,
        candA: p.candA,
        candB: p.candB,
      );
});

final secoesComparativoProvider = FutureProvider.autoDispose
    .family<SecoesComparativoModel, ComparativoParams>((ref, p) {
  final filtros = ref.watch(filtrosSelecionadosProvider);
  return ref.watch(eleitoralDatasourceProvider).getSecoesComparativo(
        ano: filtros.ano,
        estado: filtros.estado,
        municipio: p.municipio,
        candA: p.candA,
        candB: p.candB,
        bairro: p.bairro ?? '',
      );
});
