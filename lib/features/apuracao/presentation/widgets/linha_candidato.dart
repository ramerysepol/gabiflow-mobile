import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../apuracao_format.dart';
import 'projecao_badge.dart';

/// Linha de candidato reutilizada no ranking, na disputa direta (vizinhos)
/// e nos colegas de partido/federação.
class LinhaCandidato extends StatelessWidget {
  const LinhaCandidato({
    super.key,
    this.posicao,
    required this.nomeUrna,
    this.numero,
    this.partido,
    this.votos,
    this.pct,
    this.projecao,
    this.projecaoVia,
    this.pctSecoes,
    this.seguido = false,
    this.principal = false,
    this.destacado = false,
    this.onTap,
  });

  final int? posicao;
  final String nomeUrna;
  final String? numero;
  final String? partido;
  final int? votos;
  final num? pct;
  final String? projecao;
  final String? projecaoVia;
  final num? pctSecoes;

  /// Mostra a estrela de "acompanhado".
  final bool seguido;

  /// Mostra a estrela cheia de "meu candidato".
  final bool principal;

  /// Realça o fundo da linha (candidato principal / o próprio candidato
  /// na lista de concorrentes).
  final bool destacado;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final subtitulo = [
      if (numero != null && numero!.isNotEmpty) numero,
      if (partido != null && partido!.isNotEmpty) partido,
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: destacado
            ? cs.primaryContainer.withValues(alpha: 0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: destacado
            ? Border(left: BorderSide(color: cs.primary, width: 3))
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              destacado ? AppSpacing.md - 3 : AppSpacing.md,
              10,
              AppSpacing.md,
              10,
            ),
            child: Row(
              children: [
                if (posicao != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 24),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$posicao',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: tt.titleSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (posicao != null) const SizedBox(width: 4),
                if (principal)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Color(0xFFD97706),
                    ),
                  )
                else if (seguido)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.star_outline_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomeUrna,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: destacado
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      if (subtitulo.isNotEmpty)
                        Text(
                          subtitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatarVotosApuracao(votos),
                        maxLines: 1,
                        style: tt.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    if (pct != null)
                      Text(
                        formatarPctApuracao(pct),
                        maxLines: 1,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (projecao != null) ...[
                  const SizedBox(width: 8),
                  ProjecaoBadge(
                    projecao: projecao,
                    projecaoVia: projecaoVia,
                    pctSecoes: pctSecoes,
                    compacto: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
