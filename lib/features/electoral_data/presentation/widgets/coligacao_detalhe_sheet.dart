import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/eleitoral_providers.dart';

final _numFmt = NumberFormat.decimalPattern('pt_BR');

/// Abre o detalhe de uma coligação (drilldown do ranking de coligações).
void showColigacaoDetalheSheet(BuildContext context, String nome) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ColigacaoDetalheSheet(nome: nome),
  );
}

class ColigacaoDetalheSheet extends ConsumerWidget {
  const ColigacaoDetalheSheet({super.key, required this.nome});

  final String nome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coligacaoDetalheProvider(nome));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 36, color: cs.error),
                        const SizedBox(height: 12),
                        Text(
                          'Não foi possível carregar a coligação',
                          style: tt.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () =>
                              ref.invalidate(coligacaoDetalheProvider(nome)),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (colig) => ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cs.tertiaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.handshake_outlined,
                              color: cs.onTertiaryContainer),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                colig.nome,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: tt.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '${colig.partidos.length} partido${colig.partidos.length > 1 ? 's' : ''}',
                                style: tt.labelSmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Partidos que compõem ──────────────────────────────
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final sigla in colig.partidos)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              sigla,
                              style: tt.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── KPIs ──────────────────────────────────────────────
                    Row(
                      children: [
                        _Kpi(label: 'Votos', value: _numFmt.format(colig.votos)),
                        _Kpi(
                            label: 'Candidatos',
                            value: _numFmt.format(colig.candidatos)),
                        _Kpi(
                            label: 'Eleitos',
                            value: _numFmt.format(colig.eleitos),
                            color: Colors.green.shade700),
                        _Kpi(
                            label: 'Suplentes',
                            value: _numFmt.format(colig.suplentes)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Top candidatos ────────────────────────────────────
                    if (colig.topCandidatos.isNotEmpty) ...[
                      Text(
                        'Principais candidatos',
                        style: tt.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      for (final c in colig.topCandidatos)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            c.nomeUrna.isNotEmpty ? c.nomeUrna : c.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            c.siglaPartido.isNotEmpty
                                ? '${c.siglaPartido} · ${c.cargo.replaceAll('_', ' ')}'
                                : c.cargo.replaceAll('_', ' '),
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 9.5,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (c.eleito)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ELEITO',
                                    style: tt.labelSmall?.copyWith(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              Text(
                                _numFmt.format(c.votos),
                                style: tt.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(
                                '/home/eleitoral/candidato/${c.sequencial}');
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color ?? cs.onSurface,
            ),
          ),
          Text(
            label,
            style: tt.labelSmall
                ?.copyWith(color: cs.onSurfaceVariant, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}
