import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'services/mesorregiao_colors.dart';
import 'mesorregioes_sp.dart';

/// Configuração de uma UF habilitada nos Dados Eleitorais.
/// Espelha lib/eleitoral/ufs.ts do projeto web.
class UFConfig {
  const UFConfig({
    required this.sigla,
    required this.nome,
    required this.assetPath,
    required this.center,
    required this.zoom,
    required this.nomes,
    required this.cores,
    required this.keyOf,
    required this.fallbackKey,
  });

  final String sigla;
  final String nome;

  /// Malha municipal TopoJSON (assets/geo).
  final String assetPath;

  /// Centro inicial do mapa e zoom (equivalente a mapCenter/mapScale da web).
  final LatLng center;
  final double zoom;

  /// chave da mesorregião -> nome / cor
  final Map<String, String> nomes;
  final Map<String, Color> cores;

  /// código IBGE (7 dígitos) -> chave da mesorregião
  final String Function(String codigoIbge) keyOf;
  final String fallbackKey;

  String getMesorregiaoKey(String codigoIbge) => keyOf(codigoIbge);

  Color getCor(String codigoIbge) =>
      cores[keyOf(codigoIbge)] ?? cores[fallbackKey] ?? const Color(0xFF388E3C);

  String getNome(String codigoIbge) =>
      nomes[keyOf(codigoIbge)] ?? nomes[fallbackKey] ?? '';
}

const String ufPadrao = 'BA';

final Map<String, UFConfig> ufsConfig = {
  'BA': const UFConfig(
    sigla: 'BA',
    nome: 'Bahia',
    assetPath: 'assets/geo/bahia-municipios.topo.json',
    center: LatLng(-13.0, -41.5),
    zoom: 5.5,
    nomes: MesorregiaoColors.nomes,
    cores: MesorregiaoColors.cores,
    keyOf: MesorregiaoColors.getMesorregiaoKey,
    fallbackKey: '2906',
  ),
  'SP': const UFConfig(
    sigla: 'SP',
    nome: 'São Paulo',
    assetPath: 'assets/geo/sp-municipios.topo.json',
    center: LatLng(-22.3, -48.7),
    zoom: 5.9,
    nomes: MesorregioesSP.nomes,
    cores: MesorregioesSP.cores,
    keyOf: MesorregioesSP.getKey,
    fallbackKey: '3515',
  ),
};

/// Config da UF, com fallback para a UF padrão (BA), igual à web.
UFConfig getUFConfig(String? uf) =>
    ufsConfig[(uf ?? '').toUpperCase()] ?? ufsConfig[ufPadrao]!;

/// True se a UF está habilitada.
bool ufDisponivel(String? uf) =>
    uf != null && ufsConfig.containsKey(uf.toUpperCase());
