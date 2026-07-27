import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ibge_municipio_model.dart';
import '../../data/models/municipio_voto_model.dart';
import '../providers/eleitoral_providers.dart';
import 'numero_formatado.dart';
import 'zonas_drilldown_sheet.dart';

class MunicipioBottomSheet extends ConsumerWidget {
  const MunicipioBottomSheet({
    super.key,
    required this.municipio,
    required this.mesorregiao,
    this.sequencial,
  });

  final MunicipioVotoModel municipio;
  final String mesorregiao;
  final String? sequencial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ibgeAsync = ref.watch(ibgeMunicipioProvider(municipio.idMunicipio));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.of(ctx).padding.bottom + 16,
            ),
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Text(
                municipio.nomeMunicipio,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(mesorregiao,
                  style:
                      tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
              // KPIs votos
              Row(
                children: [
                  Expanded(
                    child: _MiniKpi(
                      label: 'Votos',
                      value: formatarNumero(municipio.votosMunicipio),
                      icon: Icons.how_to_vote_outlined,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniKpi(
                      label: '% do candidato',
                      value:
                          '${formatarDecimal(municipio.percentualMunicipio)}%',
                      icon: Icons.pie_chart_outline,
                      color: cs.tertiary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Dados IBGE
              ibgeAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Dados IBGE indisponíveis',
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                data: (ibge) => _IbgeSection(
                    ibge: ibge, votosTotal: municipio.votosMunicipio),
              ),
              const Divider(height: 24),
              // Ações
              _AcoesRodape(
                municipio: municipio,
                sequencial: sequencial,
                mesorregiao: mesorregiao,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Rodapé de ações ─────────────────────────────────────────────────────────

class _AcoesRodape extends StatelessWidget {
  const _AcoesRodape({
    required this.municipio,
    required this.sequencial,
    required this.mesorregiao,
  });

  final MunicipioVotoModel municipio;
  final String? sequencial;
  final String mesorregiao;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AÇÕES',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.8,
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Ver zonas (só se tiver sequencial)
            if (sequencial != null)
              Expanded(
                child: _ActionButton(
                  icon: Icons.layers_outlined,
                  label: 'Ver zonas',
                  color: cs.primary,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop();
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ZonasDrilldownSheet(
                        sequencial: sequencial!,
                        municipio: municipio,
                      ),
                    );
                  },
                ),
              ),
            if (sequencial != null) const SizedBox(width: 8),
            // Compartilhar
            Expanded(
              child: _ActionButton(
                icon: Icons.share_outlined,
                label: 'Compartilhar',
                color: cs.tertiary,
                onTap: () => _compartilhar(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _compartilhar(BuildContext context) {
    HapticFeedback.lightImpact();
    final texto = [
      '🗳️ ${municipio.nomeMunicipio} — $mesorregiao',
      'Votos: ${formatarNumero(municipio.votosMunicipio)}',
      'Participação: ${formatarDecimal(municipio.percentualMunicipio)}%',
      '',
      'GabiFlow — Análise Eleitoral',
    ].join('\n');

    // Usando Clipboard como fallback (share_plus não listado no pubspec atual)
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado para área de transferência'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── KPI mini card ────────────────────────────────────────────────────────────

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // Sem Expanded aqui: este widget também é usado solto em Column
    // (Expanded em coluna com altura ilimitada quebra o layout do sheet).
    // Nos Rows, os call sites embrulham em Expanded.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant, fontSize: 10),
                ),
                Text(
                  value,
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Seção IBGE ──────────────────────────────────────────────────────────────

class _IbgeSection extends StatelessWidget {
  const _IbgeSection({required this.ibge, required this.votosTotal});

  final IbgeMunicipioModel ibge;
  final int votosTotal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final votosPorMil =
        ibge.populacao > 0 ? (votosTotal / ibge.populacao * 1000) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DADOS IBGE',
          style:
              tt.labelSmall?.copyWith(letterSpacing: 0.8, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniKpi(
                label: 'População',
                value: formatarNumero(ibge.populacao),
                icon: Icons.people_outline,
                color: cs.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniKpi(
                label: 'PIB per capita',
                value: formatarMoeda(ibge.pibPerCapita),
                icon: Icons.attach_money,
                color: cs.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MiniKpi(
          label: 'Votos / mil hab.',
          value: formatarDecimal(votosPorMil.toDouble(), casas: 1),
          icon: Icons.analytics_outlined,
          color: cs.primary,
        ),
        if (ibge.composicao != null) ...[
          const SizedBox(height: 16),
          _ComposicaoEconomicaWidget(composicao: ibge.composicao!),
        ],
      ],
    );
  }
}

class _ComposicaoEconomicaWidget extends StatelessWidget {
  const _ComposicaoEconomicaWidget({required this.composicao});

  final ComposicaoEconomica composicao;

  static const _cores = [
    Color(0xFF388E3C), // Agropecuária
    Color(0xFF1976D2), // Indústria
    Color(0xFF7B1FA2), // Serviços
    Color(0xFFD84315), // Adm. Pública
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final valores = [
      composicao.agropecuaria,
      composicao.industria,
      composicao.servicos,
      composicao.admPublica,
    ];
    final labels = ['Agropecuária', 'Indústria', 'Serviços', 'Adm. Pública'];
    final total = valores.fold(0.0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMPOSIÇÃO ECONÔMICA',
          style: tt.labelSmall
              ?.copyWith(letterSpacing: 0.8, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        // Barra empilhada
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 16,
            child: Row(
              children: List.generate(valores.length, (i) {
                final frac = total > 0 ? valores[i] / total : 0.0;
                return Flexible(
                  flex: (frac * 100).round(),
                  child: Container(color: _cores[i]),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Grid 2×2
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.5,
          children: List.generate(labels.length, (i) {
            return Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _cores[i],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    labels[i],
                    style: tt.labelSmall?.copyWith(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${formatarDecimal(valores[i])}%',
                  style: tt.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 12),
        // Card vocação
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vocação: ${composicao.setorDominante}',
                style: tt.labelMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                composicao.sugestaoProjetos,
                style: tt.bodySmall
                    ?.copyWith(color: cs.onPrimaryContainer),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
