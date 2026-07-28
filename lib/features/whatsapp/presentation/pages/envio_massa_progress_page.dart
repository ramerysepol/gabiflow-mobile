import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_tokens.dart';
import '../providers/whatsapp_providers.dart';

/// Progresso de um envio em massa — atualiza sozinho enquanto a campanha roda.
class EnvioMassaProgressPage extends ConsumerStatefulWidget {
  const EnvioMassaProgressPage({super.key, required this.campaignId});

  final int campaignId;

  @override
  ConsumerState<EnvioMassaProgressPage> createState() =>
      _EnvioMassaProgressPageState();
}

class _EnvioMassaProgressPageState
    extends ConsumerState<EnvioMassaProgressPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final status =
          ref.read(campanhaStatusProvider(widget.campaignId)).valueOrNull;
      if (status != null && status.concluida) {
        _timer?.cancel();
        return;
      }
      ref.invalidate(campanhaStatusProvider(widget.campaignId));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(campanhaStatusProvider(widget.campaignId));
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Envio em massa')),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48),
                const SizedBox(height: AppSpacing.md),
                const Text('Não foi possível carregar o progresso'),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref
                      .invalidate(campanhaStatusProvider(widget.campaignId)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (c) {
          final emAndamento = !c.concluida;
          final processados = c.totalEnviados + c.totalErros;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        emAndamento
                            ? Icons.forward_to_inbox_rounded
                            : c.totalErros == 0
                                ? Icons.check_circle_rounded
                                : Icons.info_rounded,
                        size: 48,
                        color: emAndamento
                            ? cs.primary
                            : c.totalErros == 0
                                ? (isDark
                                    ? AppColors.successDark
                                    : AppColors.successLight)
                                : (isDark
                                    ? AppColors.warningDark
                                    : AppColors.warningLight),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        emAndamento
                            ? 'Enviando mensagens…'
                            : 'Envio concluído',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.nome,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: c.progresso.clamp(0, 1),
                          minHeight: 10,
                          backgroundColor:
                              cs.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '$processados de ${c.totalDestinatarios}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      rotulo: 'ENVIADAS',
                      valor: c.totalEnviados,
                      cor: isDark
                          ? AppColors.successDark
                          : AppColors.successLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MiniStat(
                      rotulo: 'ERROS',
                      valor: c.totalErros,
                      cor: c.totalErros > 0
                          ? (isDark
                              ? AppColors.dangerDark
                              : AppColors.dangerLight)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (emAndamento)
                Text(
                  'Pode sair desta tela — o envio continua no servidor.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.rotulo, required this.valor, this.cor});

  final String rotulo;
  final int valor;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rotulo, style: AppTextStyles.eyebrow(context)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$valor',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: cor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
