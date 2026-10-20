import 'package:flutter/material.dart';

/// Barra única dividida nas cores dos dois candidatos (proporção de votos
/// entre os dois), com marcador dos 50%.
class BarraDuelo extends StatelessWidget {
  const BarraDuelo({
    super.key,
    required this.votosA,
    required this.votosB,
    required this.corA,
    required this.corB,
    this.altura = 14,
    this.corFundo,
  });

  final int votosA;
  final int votosB;
  final Color corA;
  final Color corB;
  final double altura;
  final Color? corFundo;

  @override
  Widget build(BuildContext context) {
    final soma = votosA + votosB;
    final temVotos = soma > 0;
    final fracA = temVotos ? votosA / soma : 0.5;
    final fundo = corFundo ?? Theme.of(context).colorScheme.surfaceContainerHighest;

    return ClipRRect(
      borderRadius: BorderRadius.circular(altura),
      child: SizedBox(
        height: altura,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: fundo),
            if (temVotos)
              Row(
                children: [
                  Expanded(
                    flex: (fracA * 10000).round().clamp(1, 9999),
                    child: ColoredBox(color: corA),
                  ),
                  Expanded(
                    flex: ((1 - fracA) * 10000).round().clamp(1, 9999),
                    child: ColoredBox(color: corB),
                  ),
                ],
              ),
            Align(
              child: Container(
                width: 2,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
