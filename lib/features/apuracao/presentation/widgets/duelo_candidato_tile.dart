import 'package:flutter/material.dart';

import '../../data/models/apuracao_ranking_model.dart';
import '../apuracao_format.dart';
import 'avatar_candidato.dart';

/// Bloco de um candidato do duelo (dashboard): avatar, nome, partido/número,
/// votos, % grande e barra na cor dele.
class DueloCandidatoTile extends StatelessWidget {
  const DueloCandidatoTile({
    super.key,
    required this.candidato,
    required this.cor,
    required this.eleito,
    this.vantagem,
  });

  final ApuracaoCandVoto candidato;
  final Color cor;
  final bool eleito;

  /// Vantagem em votos sobre o 2º (só para o líder).
  final int? vantagem;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final pct = (candidato.pct ?? 0).toDouble().clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarCandidato(nome: candidato.nomeUrna, cor: cor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            candidato.nomeUrna,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (eleito) ...[
                          const SizedBox(width: 6),
                          const _SeloEleito(),
                        ],
                      ],
                    ),
                    Text(
                      '${candidato.partido ?? '—'} · nº ${candidato.numero ?? '—'}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    Text(
                      '${formatarVotosApuracao(candidato.votos)} votos',
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatarPctApuracao(candidato.pct),
                style: TextStyle(
                  color: cor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cor),
            ),
          ),
          if (vantagem != null && vantagem! > 0) ...[
            const SizedBox(height: 6),
            Text(
              'vantagem de ${formatarVotosApuracao(vantagem)} votos',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeloEleito extends StatelessWidget {
  const _SeloEleito();

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: verde.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: verde.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, size: 11, color: verde),
          SizedBox(width: 3),
          Text(
            'ELEITO',
            style: TextStyle(
              color: verde,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
