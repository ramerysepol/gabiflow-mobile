import 'package:flutter/material.dart';

import '../../data/models/apuracao_mapa_uf_model.dart';
import '../cores_duelo.dart';
import 'mapa_brasil_geometria.dart';

/// Mapa do Brasil por estados: cada UF pintada com a cor do candidato líder
/// (intensidade = tamanho da vantagem), com sigla + % do líder escritos DENTRO
/// do estado. Sem interação — tudo visível o tempo todo.
class MapaBrasilWidget extends StatefulWidget {
  const MapaBrasilWidget({
    super.key,
    required this.estados,
    required this.corDe,
    this.escuro = false,
    this.escalaTexto = 1.0,
  });

  final List<ApuracaoEstadoUf> estados;

  /// Cor fixa do candidato (ver [CoresDuelo.doCandidato]).
  final Color Function(String sqcand) corDe;
  final bool escuro;
  final double escalaTexto;

  @override
  State<MapaBrasilWidget> createState() => _MapaBrasilWidgetState();
}

class _MapaBrasilWidgetState extends State<MapaBrasilWidget> {
  late Future<GeometriaBrasil> _geo = GeometriaBrasil.carregar();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GeometriaBrasil>(
      future: _geo,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _geo = GeometriaBrasil.carregar()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Mapa indisponível — tentar de novo'),
            ),
          );
        }
        final geo = snap.data;
        if (geo == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return LayoutBuilder(
          builder: (context, c) {
            var w = c.maxWidth;
            var h = w / geo.aspecto;
            if (c.hasBoundedHeight && h > c.maxHeight) {
              h = c.maxHeight;
              w = h * geo.aspecto;
            }
            return Center(
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(w, h),
                  painter: _MapaPainter(
                    geo: geo,
                    estados: widget.estados,
                    corDe: widget.corDe,
                    escuro: widget.escuro,
                    escalaTexto: widget.escalaTexto,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MapaPainter extends CustomPainter {
  _MapaPainter({
    required this.geo,
    required this.estados,
    required this.corDe,
    required this.escuro,
    required this.escalaTexto,
  });

  final GeometriaBrasil geo;
  final List<ApuracaoEstadoUf> estados;
  final Color Function(String sqcand) corDe;
  final bool escuro;
  final double escalaTexto;

  @override
  void paint(Canvas canvas, Size size) {
    final porSigla = {for (final e in estados) e.uf.toUpperCase(): e};
    final s = size.height;
    final matriz = (Matrix4.identity()..scaleByDouble(s, s, 1, 1)).storage;
    final borda = escuro ? const Color(0xFF0B1020) : Colors.white;

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = borda
      ..strokeJoin = StrokeJoin.round;

    for (final g in geo.estados) {
      final lider = porSigla[g.sigla]?.lider;
      fill.color = lider == null
          ? CoresDuelo.semDados(escuro: escuro)
          : corDe(lider.sqcand).withValues(
              alpha: CoresDuelo.opacidadeVantagem(lider.pct ?? 50),
            );
      final path = g.caminho.transform(matriz);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }

    final fonteBase = (s * 0.026 * escalaTexto).clamp(7.0, 40.0);
    final fontePct = fonteBase * 0.88;
    for (final g in geo.estados) {
      final lider = porSigla[g.sigla]?.lider;
      final cx = g.centro.dx * s;
      final cy = g.centro.dy * s;
      final larguraPx = g.larguraRel * s;

      // Percentual só se couber dentro do estado (DF, SE etc. ficam só com a
      // sigla): tenta "52,3%", depois "52%".
      String? textoPct;
      final pct = lider?.pct;
      if (pct != null) {
        final candidatos = [
          '${pct.toStringAsFixed(1).replaceAll('.', ',')}%',
          '${pct.round()}%',
        ];
        for (final c in candidatos) {
          final tp = _texto(c, fontePct, FontWeight.w600);
          final cabe = tp.width <= larguraPx * 0.92;
          tp.dispose();
          if (cabe) {
            textoPct = c;
            break;
          }
        }
      }

      final alturaLinha = fonteBase * 1.05;
      final total = textoPct == null ? alturaLinha : alturaLinha + fontePct * 1.05;
      var y = cy - total / 2;
      _rotulo(canvas, g.sigla, fonteBase, FontWeight.w800, cx, y);
      if (textoPct != null) {
        y += alturaLinha;
        _rotulo(canvas, textoPct, fontePct, FontWeight.w600, cx, y);
      }
    }
  }

  TextPainter _texto(
    String t,
    double fonte,
    FontWeight peso, {
    bool contorno = false,
  }) {
    return TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          fontSize: fonte,
          fontWeight: peso,
          height: 1.0,
          color: contorno ? null : Colors.white,
          foreground: contorno
              ? (Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = fonte * 0.28
                  ..strokeJoin = StrokeJoin.round
                  ..color = const Color(0xCC000000))
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// Desenha [t] centralizado em [cx], com contorno escuro para legibilidade
  /// sobre qualquer cor de fundo.
  void _rotulo(
    Canvas canvas,
    String t,
    double fonte,
    FontWeight peso,
    double cx,
    double y,
  ) {
    final contorno = _texto(t, fonte, peso, contorno: true);
    final cheio = _texto(t, fonte, peso);
    contorno.paint(canvas, Offset(cx - contorno.width / 2, y));
    cheio.paint(canvas, Offset(cx - cheio.width / 2, y));
    contorno.dispose();
    cheio.dispose();
  }

  @override
  bool shouldRepaint(_MapaPainter old) =>
      old.estados != estados ||
      old.escuro != escuro ||
      old.escalaTexto != escalaTexto ||
      old.geo != geo;
}
