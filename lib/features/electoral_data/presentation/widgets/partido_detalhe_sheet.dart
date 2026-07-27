import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/partido_detalhe_model.dart';
import '../providers/eleitoral_providers.dart';
import 'erro_inline.dart';

final _numFmt = NumberFormat.decimalPattern('pt_BR');

/// Abre o detalhe de um partido (drilldown dos rankings e da análise).
void showPartidoDetalheSheet(BuildContext context, String sigla) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PartidoDetalheSheet(sigla: sigla),
  );
}

class PartidoDetalheSheet extends ConsumerWidget {
  const PartidoDetalheSheet({super.key, required this.sigla});

  final String sigla;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(partidoDetalheProvider(sigla));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
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
                error: (e, _) => ErroInline(
                  mensagem: 'Não foi possível carregar o partido',
                  onRetry: () =>
                      ref.invalidate(partidoDetalheProvider(sigla)),
                ),
                data: (p) => ListView(
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
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p.numeroPartido ?? p.sigla.substring(
                                0, p.sigla.length.clamp(0, 2)),
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.sigla,
                                style: tt.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                p.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.labelSmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── KPIs ──────────────────────────────────────────────
                    Row(
                      children: [
                        _Kpi(label: 'Votos', value: _numFmt.format(p.votos)),
                        _Kpi(
                            label: 'Candidatos',
                            value: _numFmt.format(p.candidatos)),
                        _Kpi(
                            label: 'Eleitos',
                            value: _numFmt.format(p.eleitos),
                            color: Colors.green.shade700),
                        _Kpi(
                            label: 'Suplentes',
                            value: _numFmt.format(p.suplentes)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Gênero ────────────────────────────────────────────
                    if (p.generoMasculino + p.generoFeminino > 0) ...[
                      const _SectionLabel('Gênero'),
                      const SizedBox(height: 6),
                      _GeneroBar(
                        masculino: p.generoMasculino,
                        feminino: p.generoFeminino,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Top candidatos ────────────────────────────────────
                    if (p.topCandidatos.isNotEmpty) ...[
                      const _SectionLabel('Principais candidatos'),
                      const SizedBox(height: 6),
                      for (final c in p.topCandidatos)
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
                            c.cargo.replaceAll('_', ' '),
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
                                    color: Colors.green
                                        .withValues(alpha: 0.15),
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
                                )
                              else if (c.suplente)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'SUPL.',
                                    style: tt.labelSmall?.copyWith(
                                      color: Colors.orange.shade800,
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
                      const SizedBox(height: 10),
                    ],

                    // ── Top municípios ────────────────────────────────────
                    if (p.topMunicipios.isNotEmpty) ...[
                      const _SectionLabel('Municípios com mais votos'),
                      const SizedBox(height: 8),
                      _TopMunicipiosBars(municipios: p.topMunicipios),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _GeneroBar extends StatelessWidget {
  const _GeneroBar({required this.masculino, required this.feminino});

  final int masculino;
  final int feminino;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final total = masculino + feminino;
    final pctM = total > 0 ? masculino / total : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: (pctM * 1000).round().clamp(1, 999),
                  child: ColoredBox(color: Colors.blue.shade600),
                ),
                Expanded(
                  flex: ((1 - pctM) * 1000).round().clamp(1, 999),
                  child: ColoredBox(color: Colors.purple.shade400),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '♂ ${(pctM * 100).toStringAsFixed(0)}% homens',
              style: tt.labelSmall?.copyWith(fontSize: 10),
            ),
            Text(
              '♀ ${((1 - pctM) * 100).toStringAsFixed(0)}% mulheres',
              style: tt.labelSmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopMunicipiosBars extends StatelessWidget {
  const _TopMunicipiosBars({required this.municipios});

  final List<PartidoMunicipioItem> municipios;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxVotos =
        municipios.map((m) => m.votos).fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        for (final m in municipios)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    m.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(fontSize: 10.5),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: maxVotos > 0 ? m.votos / maxVotos : 0,
                      minHeight: 10,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _numFmt.format(m.votos),
                  style: tt.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 10.5),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
