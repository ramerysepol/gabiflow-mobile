import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/demanda_extras.dart';
import '../../data/models/demanda_model.dart';
import '../../data/models/demanda_vocab.dart';

/// Faixa "Hoje": atalhos de filtro com os números que pedem ação agora.
class DemandaFaixaHoje extends StatelessWidget {
  const DemandaFaixaHoje({
    super.key,
    required this.contadores,
    required this.filtros,
    required this.onAplicar,
  });

  final DemandaContadores contadores;
  final DemandaFiltros filtros;
  final ValueChanged<DemandaFiltros> onAplicar;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final vermelho = dark ? AppColors.dangerDark : AppColors.dangerLight;
    final ambar = dark ? AppColors.warningDark : AppColors.warningLight;
    final base = filtros.semRapidos();
    final saudeN = contadores.saudeUrgentes ?? contadores.saude;

    final chips = <_Atalho>[
      _Atalho(
        'Atrasadas',
        contadores.atrasadas,
        vermelho,
        Icons.error_outline_rounded,
        filtros.atrasadas,
        base.copyWith(atrasadas: true),
      ),
      _Atalho(
        'Vencem hoje',
        contadores.venceHoje,
        ambar,
        Icons.schedule_rounded,
        filtros.venceHoje,
        base.copyWith(venceHoje: true),
      ),
      _Atalho(
        'Aguardando retorno',
        contadores.status('aguardando_retorno'),
        DemandaVocab.corStatus(context, 'aguardando_retorno'),
        Icons.hourglass_bottom_rounded,
        filtros.aguardandoHa != null,
        base.copyWith(
          status: () => 'aguardando_retorno',
          aguardandoHa: () => 5,
        ),
      ),
      _Atalho(
        contadores.saudeUrgentes != null ? 'Saúde urgentes' : 'Saúde',
        saudeN,
        DemandaVocab.corSaude(context),
        Icons.monitor_heart_rounded,
        filtros.area == 'saude' &&
            (contadores.saudeUrgentes == null ||
                filtros.prioridade == 'urgente'),
        base.copyWith(
          area: () => 'saude',
          prioridade: contadores.saudeUrgentes != null
              ? () => 'urgente'
              : () => null,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Text('HOJE', style: AppTextStyles.eyebrow(context)),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final a = chips[i];
              return Semantics(
                button: true,
                selected: a.ativo,
                label: '${a.rotulo}: ${a.n}',
                child: FilterChip(
                  selected: a.ativo,
                  showCheckmark: false,
                  avatar: Icon(a.icone, size: 16, color: a.cor),
                  label: Text('${a.rotulo} ${a.n}'),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: a.n > 0 ? a.cor : null,
                  ),
                  selectedColor: a.cor.withValues(alpha: 0.18),
                  side: BorderSide(color: a.cor.withValues(alpha: 0.4)),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => onAplicar(a.ativo ? base : a.filtro),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Atalho {
  const _Atalho(
    this.rotulo,
    this.n,
    this.cor,
    this.icone,
    this.ativo,
    this.filtro,
  );
  final String rotulo;
  final int n;
  final Color cor;
  final IconData icone;
  final bool ativo;
  final DemandaFiltros filtro;
}
