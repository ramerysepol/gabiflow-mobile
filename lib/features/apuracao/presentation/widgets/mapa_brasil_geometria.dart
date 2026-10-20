import 'dart:math' as math;
import 'dart:ui';

import '../../../electoral_data/data/services/geo_service.dart';

/// Um estado já projetado (Mercator) em coordenadas unitárias: altura do
/// Brasil = 1, largura = [GeometriaBrasil.aspecto].
class EstadoGeometria {
  const EstadoGeometria({
    required this.sigla,
    required this.nome,
    required this.caminho,
    required this.centro,
    required this.larguraRel,
  });

  final String sigla;
  final String nome;
  final Path caminho;

  /// Ponto de ancoragem do rótulo (centroide do maior polígono).
  final Offset centro;

  /// Largura do maior polígono (mesma unidade de [caminho]); decide se o
  /// percentual cabe dentro do estado.
  final double larguraRel;
}

/// Malha dos 27 estados projetada uma única vez e reaproveitada pelo painter.
class GeometriaBrasil {
  const GeometriaBrasil(this.aspecto, this.estados);

  final double aspecto;
  final List<EstadoGeometria> estados;

  static const assetEstados = 'assets/geo/brasil-estados.topo.json';
  static Future<GeometriaBrasil>? _cache;

  static Future<GeometriaBrasil> carregar() => _cache ??= _montar().onError((
    e,
    s,
  ) {
    _cache = null;
    throw e!;
  });

  static Future<GeometriaBrasil> _montar() async {
    final features = await GeoService.instance.getFeatures(
      assetPath: assetEstados,
    );

    // Projeção Mercator (mesma da web) de todos os anéis.
    final aneis = <(String, String, List<List<Offset>>)>[];
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final f in features) {
      final proj = <List<Offset>>[];
      for (final ring in f.rings) {
        final pts = <Offset>[];
        for (final p in ring) {
          final x = p.longitude * math.pi / 180;
          final y =
              -math.log(math.tan(math.pi / 4 + p.latitude * math.pi / 360));
          pts.add(Offset(x, y));
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
        }
        proj.add(pts);
      }
      aneis.add((f.id.toUpperCase(), f.nome, proj));
    }

    final h = maxY - minY;
    final estados = <EstadoGeometria>[];
    for (final (sigla, nome, rings) in aneis) {
      final caminho = Path();
      List<Offset>? maior;
      double maiorArea = -1;
      for (final ring in rings) {
        final un = [for (final o in ring) Offset((o.dx - minX) / h, (o.dy - minY) / h)];
        if (un.length < 3) continue;
        caminho.addPolygon(un, true);
        final area = _area(un).abs();
        if (area > maiorArea) {
          maiorArea = area;
          maior = un;
        }
      }
      if (maior == null) continue;
      var minRx = double.infinity, maxRx = -double.infinity;
      for (final o in maior) {
        minRx = math.min(minRx, o.dx);
        maxRx = math.max(maxRx, o.dx);
      }
      estados.add(
        EstadoGeometria(
          sigla: sigla,
          nome: nome,
          caminho: caminho,
          centro: _centroide(maior),
          larguraRel: maxRx - minRx,
        ),
      );
    }
    return GeometriaBrasil((maxX - minX) / h, estados);
  }

  static double _area(List<Offset> p) {
    double a = 0;
    for (var i = 0; i < p.length; i++) {
      final q = p[(i + 1) % p.length];
      a += p[i].dx * q.dy - q.dx * p[i].dy;
    }
    return a / 2;
  }

  static Offset _centroide(List<Offset> p) {
    final a = _area(p);
    if (a.abs() < 1e-12) {
      return Offset(
        p.map((e) => e.dx).reduce((x, y) => x + y) / p.length,
        p.map((e) => e.dy).reduce((x, y) => x + y) / p.length,
      );
    }
    double cx = 0, cy = 0;
    for (var i = 0; i < p.length; i++) {
      final q = p[(i + 1) % p.length];
      final f = p[i].dx * q.dy - q.dx * p[i].dy;
      cx += (p[i].dx + q.dx) * f;
      cy += (p[i].dy + q.dy) * f;
    }
    return Offset(cx / (6 * a), cy / (6 * a));
  }
}
