import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/apuracao_candidato_model.dart';
import '../apuracao_format.dart';

const _corVerde = Color(0xFF16A34A);
const _corVermelho = Color(0xFFDC2626);
const _corAmbar = Color(0xFFD97706);

String _rotuloPapel(String papel) => switch (papel) {
  'primeiro_suplente' => '1º suplente',
  'ultimo_eleito' => 'último eleito',
  _ => papel,
};

/// Resume a "linha de corte" (quociente/sobras ou maioria absoluta) numa
/// única frase + cor, usada tanto no card completo quanto na versão
/// compacta. [sqcandAtual] identifica o candidato da tela para decidir se
/// ele é o líder ou não (disputa majoritária).
(String texto, Color cor) resumoLinhaDeCorte(
  ApuracaoCorte corte,
  String sqcandAtual,
) {
  if (corte.isProporcional) {
    if (corte.semVagaNaAgr) {
      final faltamTxt = corte.proximaVagaQp != null
          ? ' · faltam ${formatarVotosApuracao(corte.proximaVagaQp)} votos '
                'para a 1ª vaga por quociente'
          : '';
      return ('Partido sem vaga projetada ainda$faltamTxt', _corAmbar);
    }
    if (corte.atingeMinimo == false) {
      final minimoTxt = corte.minimoIndividual != null
          ? ' (10% do QE = ${formatarVotosApuracao(corte.minimoIndividual)} '
                'votos)'
          : '';
      return ('Abaixo do mínimo individual$minimoTxt', _corVermelho);
    }
    if (corte.eleito) {
      final ref = corte.referencia;
      final sobre = ref != null
          ? ' sobre ${ref.nomeUrna} (${_rotuloPapel(ref.papel)})'
          : '';
      return (
        'Margem de ${formatarVotosApuracao(corte.margem)} votos$sobre',
        _corVerde,
      );
    }
    final ref = corte.referencia;
    final doQue = ref != null
        ? ' para a última vaga do partido (${ref.nomeUrna})'
        : ' para a última vaga do partido';
    return (
      'Faltam ${formatarVotosApuracao(corte.faltam)} votos$doQue',
      _corVermelho,
    );
  }

  // Majoritário.
  final lider = corte.lider;
  if (lider != null && lider.sqcand == sqcandAtual) {
    return (
      'Lidera por ${formatarVotosApuracao(corte.diferencaLider)} votos',
      _corVerde,
    );
  }
  if (lider != null) {
    return (
      '${formatarVotosApuracao(corte.diferencaLider)} votos atrás de '
          '${lider.nomeUrna}',
      _corVermelho,
    );
  }
  return (
    'Faltam ${formatarVotosApuracao(corte.faltamMaioria)} votos para a '
        'maioria absoluta',
    _corAmbar,
  );
}

/// Card completo de "linha de corte" — ficha do candidato, abaixo dos KPIs.
class LinhaDeCorteCard extends StatelessWidget {
  const LinhaDeCorteCard({
    super.key,
    required this.corte,
    required this.sqcandAtual,
  });

  final ApuracaoCorte corte;
  final String sqcandAtual;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final (texto, cor) = resumoLinhaDeCorte(corte, sqcandAtual);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_circle_rounded, color: cor, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LINHA DE CORTE', style: AppTextStyles.eyebrow(context)),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cor,
                  ),
                ),
                if (corte.segundoTurno) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Pode haver 2º turno.',
                    style: tt.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Versão compacta de uma linha, usada dentro do card "Meu candidato" da
/// tela principal.
class LinhaDeCorteCompacta extends StatelessWidget {
  const LinhaDeCorteCompacta({
    super.key,
    required this.corte,
    required this.sqcandAtual,
  });

  final ApuracaoCorte corte;
  final String sqcandAtual;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final (texto, cor) = resumoLinhaDeCorte(corte, sqcandAtual);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.flag_circle_rounded, size: 14, color: cor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(
              color: cor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
