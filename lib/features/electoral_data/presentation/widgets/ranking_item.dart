import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/ranking_model.dart';
import 'coligacao_detalhe_sheet.dart';
import 'eleitos_municipio_sheet.dart';
import 'numero_formatado.dart';
import 'partido_detalhe_sheet.dart';

class RankingItemWidget extends StatelessWidget {
  const RankingItemWidget({
    super.key,
    required this.posicao,
    required this.item,
    this.tipo = 'municipios',
  });

  final int posicao;
  final RankingItemModel item;
  final String tipo; // municipios | partidos | coligacoes

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Color posColor = cs.onSurfaceVariant;
    if (posicao == 1) posColor = const Color(0xFFD4AF37); // ouro
    if (posicao == 2) posColor = const Color(0xFF9E9E9E); // prata
    if (posicao == 3) posColor = const Color(0xFFCD7F32); // bronze

    final isMunicipio = tipo == 'municipios';
    final isPartido = tipo == 'partidos';
    // Só faz sentido mostrar "eleitos" em ranking de partido/coligação
    // (eleitos totais). Em município estadual/federal todos teriam o mesmo
    // valor (total de eleitos na UF), o que é enganoso.
    final mostrarEleitos = !isMunicipio && item.eleitos > 0;

    return InkWell(
      onTap: isMunicipio
          ? () {
              HapticFeedback.selectionClick();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => EleitosMunicipioSheet(
                  idMunicipio: item.id,
                  nomeMunicipio: item.nome,
                ),
              );
            }
          : isPartido
              ? () {
                  HapticFeedback.selectionClick();
                  showPartidoDetalheSheet(context, item.id);
                }
              : () {
                  // coligações
                  HapticFeedback.selectionClick();
                  showColigacaoDetalheSheet(context, item.id);
                },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '$posicao',
                style: tt.titleMedium?.copyWith(
                  color: posColor,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nome,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (mostrarEleitos)
                    Text(
                      '${item.eleitos} eleito${item.eleitos > 1 ? 's' : ''}',
                      style:
                          tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatarNumero(item.totalVotos),
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                Text(
                  'votos',
                  style:
                      tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
