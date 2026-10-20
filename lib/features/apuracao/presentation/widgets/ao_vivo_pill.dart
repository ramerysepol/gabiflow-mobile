import 'package:flutter/material.dart';

/// Pílula de status da apuração: vermelha pulsante "AO VIVO" enquanto a
/// contagem está em andamento, verde "Totalizada" quando já encerrou.
class AoVivoPill extends StatefulWidget {
  const AoVivoPill({super.key, required this.aoVivo});

  /// `true` = ainda apurando (pulsa em vermelho); `false` = totalizada.
  final bool aoVivo;

  @override
  State<AoVivoPill> createState() => _AoVivoPillState();
}

class _AoVivoPillState extends State<AoVivoPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.aoVivo
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);
    final texto = widget.aoVivo ? 'AO VIVO' : 'TOTALIZADA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.aoVivo)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cor.withValues(alpha: 0.4 + _ctrl.value * 0.6),
                ),
              ),
            )
          else
            Icon(Icons.check_circle_rounded, size: 12, color: cor),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: cor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
