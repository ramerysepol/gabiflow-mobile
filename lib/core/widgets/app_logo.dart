import 'package:flutter/material.dart';

/// Widget reutilizável para o logo do app
class AppLogo extends StatelessWidget {
  final double? height;
  final double? width;
  
  const AppLogo({
    super.key,
    this.height = 100,
    this.width,
  });
  
  @override
  Widget build(BuildContext context) {
    // Decodifica ja no tamanho exibido (evita bitmap em resolucao total na memoria).
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.asset(
      'assets/images/gabiflow-hd.png',
      height: height,
      width: width,
      fit: BoxFit.contain,
      cacheWidth: width != null ? (width! * dpr).round() : null,
      cacheHeight: width == null ? ((height ?? 100) * dpr).round() : null,
      errorBuilder: (context, error, stackTrace) {
        // Fallback caso a imagem não carregue
        return Container(
          height: height,
          width: width ?? height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.account_balance,
            size: (height ?? 100) * 0.6,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}