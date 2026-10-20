import 'package:flutter/material.dart';

/// Barra de progresso linear arredondada, com rótulo opcional acima.
class BarraProgresso extends StatelessWidget {
  const BarraProgresso({
    super.key,
    required this.pct,
    this.cor,
    this.corFundo,
    this.height = 6,
    this.rotulo,
  });

  /// Percentual de 0 a 100.
  final num pct;
  final Color? cor;
  final Color? corFundo;
  final double height;
  final String? rotulo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final valor = (pct.clamp(0, 100)) / 100.0;
    final corBarra = cor ?? cs.primary;

    final barra = ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: valor.toDouble(),
        minHeight: height,
        backgroundColor: corFundo ?? cs.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(corBarra),
      ),
    );

    if (rotulo == null) return barra;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo!,
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        barra,
      ],
    );
  }
}
