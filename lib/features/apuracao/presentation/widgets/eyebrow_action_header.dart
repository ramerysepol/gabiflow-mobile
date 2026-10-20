import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Header padrão "rótulo eyebrow + ação", reusado nas seções da apuração
/// (ex.: "MEU CANDIDATO" + "trocar", "RANKING" + cargo, "ACOMPANHANDO VOTO A
/// VOTO" + "Acompanhar outro"). Em telas estreitas (ex.: capa do Galaxy
/// Fold, ~360dp) ou com a fonte do sistema ampliada, o rótulo e a ação não
/// cabem numa linha só — nesse caso empilha o rótulo acima e a ação
/// alinhada à direita, em vez de truncar qualquer um dos dois.
class EyebrowActionHeader extends StatelessWidget {
  const EyebrowActionHeader({
    super.key,
    required this.label,
    required this.action,
  });

  /// Texto do rótulo eyebrow (já em uppercase pela convenção do app).
  final String label;

  /// Widget de ação à direita (botão, texto secundário, etc.).
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final escalaFonte = MediaQuery.textScalerOf(context).scale(100) / 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final estreita = constraints.maxWidth < 380 || escalaFonte > 1.15;

        final eyebrow = Text(
          label,
          style: AppTextStyles.eyebrow(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

        if (estreita) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              eyebrow,
              const SizedBox(height: AppSpacing.xs),
              Align(alignment: Alignment.centerRight, child: action),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: eyebrow),
            action,
          ],
        );
      },
    );
  }
}
