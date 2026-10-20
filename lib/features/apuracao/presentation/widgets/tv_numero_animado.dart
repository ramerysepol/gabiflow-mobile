import 'package:flutter/widgets.dart';

/// Número que anima suavemente do valor anterior até o novo (a cada poll).
class TvNumeroAnimado extends StatelessWidget {
  const TvNumeroAnimado({
    super.key,
    required this.valor,
    required this.formatar,
    required this.estilo,
    this.duracao = const Duration(milliseconds: 900),
  });

  final double valor;
  final String Function(double) formatar;
  final TextStyle estilo;
  final Duration duracao;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: valor),
      duration: duracao,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(
        formatar(v),
        maxLines: 1,
        softWrap: false,
        style: estilo.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
