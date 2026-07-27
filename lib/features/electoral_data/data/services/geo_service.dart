import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Representa um município com seus polígonos para renderização no mapa.
class MunicipioFeature {
  final String id;
  final String nome;
  /// Lista de anéis (exterior + buracos). Cada anel é uma lista de LatLng.
  final List<List<LatLng>> rings;

  const MunicipioFeature({
    required this.id,
    required this.nome,
    required this.rings,
  });
}

/// Carrega e converte o arquivo TopoJSON de municípios da Bahia em [MunicipioFeature]s.
///
/// Implementa o algoritmo TopoJSON → GeoJSON:
/// 1. Lê o transform (scale + translate)
/// 2. Decodifica os arcos delta-encoded
/// 3. Resolve cada geometria (Polygon / MultiPolygon) costurando arcos
class GeoService {
  GeoService._();
  static final GeoService instance = GeoService._();

  List<MunicipioFeature>? _features;
  bool _loading = false;

  Future<List<MunicipioFeature>> getFeatures() async {
    if (_features != null) return _features!;
    if (_loading) {
      // Aguarda a primeira carga terminar
      while (_loading) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return _features ?? [];
    }
    _loading = true;
    try {
      _features = await _load();
      return _features!;
    } finally {
      _loading = false;
    }
  }

  Future<List<MunicipioFeature>> _load() async {
    final raw = await rootBundle.loadString('assets/geo/bahia-municipios.topo.json');
    final Map<String, dynamic> topo = jsonDecode(raw) as Map<String, dynamic>;

    // --- Transform ---
    double scaleX = 1, scaleY = 1, translateX = 0, translateY = 0;
    final transform = topo['transform'] as Map<String, dynamic>?;
    if (transform != null) {
      final scale = transform['scale'] as List?;
      final trans = transform['translate'] as List?;
      if (scale != null && scale.length >= 2) {
        scaleX = (scale[0] as num).toDouble();
        scaleY = (scale[1] as num).toDouble();
      }
      if (trans != null && trans.length >= 2) {
        translateX = (trans[0] as num).toDouble();
        translateY = (trans[1] as num).toDouble();
      }
    }

    // --- Arcos delta-encoded → coordenadas absolutas ---
    final rawArcs = topo['arcs'] as List;
    final arcs = <List<List<double>>>[]; // explicit arc type
    for (final rawArc in rawArcs) {
      final arc = <List<double>>[];
      double x = 0, y = 0;
      for (final pt in rawArc as List) {
        final point = pt as List;
        x += (point[0] as num).toDouble();
        y += (point[1] as num).toDouble();
        final lon = x * scaleX + translateX;
        final lat = y * scaleY + translateY;
        arc.add([lon, lat]);
      }
      arcs.add(arc);
    }

    // --- Identificar key do objeto ---
    final objects = topo['objects'] as Map<String, dynamic>;
    final objectKey = objects.keys.first;
    final topologyObject = objects[objectKey] as Map<String, dynamic>;
    final geometries = topologyObject['geometries'] as List;

    // --- Converter geometrias em features ---
    final features = <MunicipioFeature>[];
    for (final geom in geometries) {
      final g = geom as Map<String, dynamic>;
      final props = g['properties'] as Map<String, dynamic>? ?? {};

      // Tenta múltiplos campos de ID
      final id = (props['id'] ?? props['geocodigo'] ?? props['cd_mun'] ??
          props['CD_MUN'] ?? props['id_municipio'] ?? g['id'] ?? '').toString();
      final nome = (props['nome'] ?? props['NM_MUN'] ?? props['nm_mun'] ??
          props['name'] ?? '').toString();

      final type = g['type'] as String? ?? '';
      final rings = <List<LatLng>>[];

      if (type == 'Polygon') {
        // Polygon.arcs = [[idx, idx, ...]]  — array de rings; usa o exterior
        final polygonArcs = g['arcs'] as List;
        if (polygonArcs.isNotEmpty) {
          final arcIdxs = polygonArcs.first as List;
          final ring = _resolveRing(arcIdxs, arcs);
          if (ring.isNotEmpty) rings.add(ring);
        }
      } else if (type == 'MultiPolygon') {
        // MultiPolygon.arcs = [[[idx,...]], [[idx,...]], ...] — array de polígonos
        final polys = g['arcs'] as List;
        for (final poly in polys) {
          final polyList = poly as List;
          if (polyList.isEmpty) continue;
          final arcIdxs = polyList.first as List;
          final ring = _resolveRing(arcIdxs, arcs);
          if (ring.isNotEmpty) rings.add(ring);
        }
      }

      if (rings.isNotEmpty) {
        features.add(MunicipioFeature(id: id, nome: nome, rings: rings));
      }
    }

    return features;
  }

  /// Resolve uma lista de índices de arcos em uma lista de pontos LatLng.
  /// Índices negativos indicam arco invertido: ~idx (bitwise NOT).
  List<LatLng> _resolveRing(List<dynamic> arcIdxList, List<List<List<double>>> arcs) {
    final points = <LatLng>[];
    for (final idxRaw in arcIdxList) {
      final idx = idxRaw as int;
      final bool reversed = idx < 0;
      final arc = arcs[reversed ? ~idx : idx];
      final coords = reversed ? arc.reversed.toList() : arc;
      // Pula o primeiro ponto de arcos subsequentes para não duplicar
      final start = points.isEmpty ? 0 : 1;
      for (int i = start; i < coords.length; i++) {
        final pt = coords[i];
        // TopoJSON usa [longitude, latitude]
        points.add(LatLng(pt[1], pt[0]));
      }
    }
    return points;
  }

  /// Calcula centroide simples de um anel de pontos.
  static LatLng centroid(List<LatLng> ring) {
    if (ring.isEmpty) return const LatLng(0, 0);
    double lat = 0, lng = 0;
    for (final p in ring) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / ring.length, lng / ring.length);
  }

  /// Calcula opacidade baseada em votos usando escala logarítmica.
  /// Resultado entre 0.2 e 1.0.
  static double calcOpacity(int votos, int maxVotos) {
    if (maxVotos <= 0 || votos <= 0) return 0.15;
    final ratio = logRatio(votos, maxVotos);
    return 0.2 + ratio * 0.8;
  }

  /// Razão logarítmica log(votos+1)/log(max+1), entre 0 e 1.
  /// Base para as escalas de cor (regiões e heatmap).
  static double logRatio(int votos, int maxVotos) {
    if (maxVotos <= 0 || votos <= 0) return 0;
    return (math.log(votos + 1) / math.log(maxVotos + 1)).clamp(0.0, 1.0);
  }
}
