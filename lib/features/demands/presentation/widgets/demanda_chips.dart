import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/demanda_model.dart';
import '../../data/models/demanda_vocab.dart';

/// Chip arredondado com tom suave (fundo translúcido + texto na cor).
class DemandaChip extends StatelessWidget {
  const DemandaChip({
    super.key,
    required this.rotulo,
    required this.cor,
    this.icone,
  });

  final String rotulo;
  final Color cor;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 12, color: cor),
            const SizedBox(width: 3),
          ],
          Text(
            rotulo,
            style: TextStyle(
              color: cor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class DemandaStatusChip extends StatelessWidget {
  const DemandaStatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) => DemandaChip(
    rotulo: DemandaVocab.status(status),
    cor: DemandaVocab.corStatus(context, status),
  );
}

class DemandaPrioridadeChip extends StatelessWidget {
  const DemandaPrioridadeChip(this.prioridade, {super.key});
  final String prioridade;

  @override
  Widget build(BuildContext context) => DemandaChip(
    rotulo: DemandaVocab.prioridade(prioridade),
    cor: DemandaVocab.corPrioridade(context, prioridade),
  );
}

class DemandaSaudeChip extends StatelessWidget {
  const DemandaSaudeChip({super.key});

  @override
  Widget build(BuildContext context) => DemandaChip(
    rotulo: 'Saúde',
    cor: DemandaVocab.corSaude(context),
    icone: Icons.monitor_heart_rounded,
  );
}

/// Texto + cor do semáforo de prazo (SLA). Null quando não há prazo.
({String texto, Color cor, IconData icone})? semaforoPrazo(
  BuildContext context,
  DemandaResumo d,
) {
  final data = parseData(d.prazo);
  if (data == null) return null;
  final dark = Theme.of(context).brightness == Brightness.dark;
  final neutro = Theme.of(context).colorScheme.onSurfaceVariant;
  final fmt = DateFormat('dd/MM').format(data);
  if (d.encerrada) {
    return (
      texto: 'Prazo $fmt',
      cor: neutro,
      icone: Icons.event_available_outlined,
    );
  }
  final hoje = DateTime.now();
  final dias =
      d.diasRestantes ??
      data.difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;
  final vermelho = dark ? AppColors.dangerDark : AppColors.dangerLight;
  final ambar = dark ? AppColors.warningDark : AppColors.warningLight;
  final verde = dark ? AppColors.successDark : AppColors.successLight;
  if (d.atrasada || dias < 0) {
    final n = dias.abs();
    return (
      texto: 'Atrasada ${n == 0 ? '' : 'há $n d · '}$fmt',
      cor: vermelho,
      icone: Icons.error_outline_rounded,
    );
  }
  if (dias == 0) {
    return (texto: 'Vence hoje', cor: ambar, icone: Icons.schedule_rounded);
  }
  if (dias <= 2) {
    return (
      texto: dias == 1 ? 'Vence amanhã' : 'Vence em $dias d · $fmt',
      cor: ambar,
      icone: Icons.schedule_rounded,
    );
  }
  return (
    texto: 'Em $dias d · $fmt',
    cor: verde,
    icone: Icons.schedule_rounded,
  );
}

class DemandaPrazoLabel extends StatelessWidget {
  const DemandaPrazoLabel(this.demanda, {super.key, this.grande = false});
  final DemandaResumo demanda;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final s = semaforoPrazo(context, demanda);
    if (s == null) return const SizedBox.shrink();
    return Semantics(
      label: 'Prazo: ${s.texto}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icone, size: grande ? 18 : 14, color: s.cor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              s.texto,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: s.cor,
                fontSize: grande ? 14 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Há 3 h", "ontem", "12/10" — tempo relativo curto para a timeline.
String tempoRelativo(String? iso) {
  final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  if (diff.inDays == 1) return 'ontem';
  if (diff.inDays < 7) return 'há ${diff.inDays} dias';
  return DateFormat('dd/MM/yy').format(d);
}
