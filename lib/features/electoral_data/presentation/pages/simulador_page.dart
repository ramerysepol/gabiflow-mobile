import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/municipio_voto_model.dart';
import '../../data/services/mesorregiao_colors.dart';
import '../providers/eleitoral_providers.dart';

final _numFmt = NumberFormat.decimalPattern('pt_BR');

/// Simulador "e se?" de projeção de votos por mesorregião.
/// Paridade com o simulador do desktop: um slider por mesorregião
/// (-50% a +100%), total projetado vs original — tudo client-side
/// a partir dos dados reais do mapa do candidato.
class SimuladorPage extends ConsumerStatefulWidget {
  const SimuladorPage({
    super.key,
    required this.sequencial,
    this.nomeCandidato,
  });

  final String sequencial;
  final String? nomeCandidato;

  @override
  ConsumerState<SimuladorPage> createState() => _SimuladorPageState();
}

class _SimuladorPageState extends ConsumerState<SimuladorPage> {
  /// Ajuste percentual por chave de mesorregião (ex.: '2905' → 0.25 = +25%)
  final Map<String, double> _ajustes = {};

  @override
  Widget build(BuildContext context) {
    final asyncMapa = ref.watch(candidatoMapaProvider(widget.sequencial));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Simulador'),
            if (widget.nomeCandidato != null)
              Text(
                widget.nomeCandidato!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Zerar ajustes',
            onPressed: () => setState(_ajustes.clear),
          ),
        ],
      ),
      body: asyncMapa.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(
            6,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerSkeleton.card(height: 84),
            ),
          ),
        ),
        error: (e, _) => AppEmptyState(
          title: 'Erro ao carregar dados',
          subtitle: e.toString(),
          actionLabel: 'Tentar novamente',
          onAction: () =>
              ref.invalidate(candidatoMapaProvider(widget.sequencial)),
        ),
        data: (mapa) => _buildSimulador(mapa),
      ),
    );
  }

  Widget _buildSimulador(MapaMunicipiosData mapa) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Agrupa votos originais por mesorregião (lookup hardcoded 417 municípios)
    final votosPorMeso = <String, int>{};
    for (final m in mapa.municipios) {
      final key = MesorregiaoColors.getMesorregiaoKey(m.idMunicipio);
      votosPorMeso[key] = (votosPorMeso[key] ?? 0) + m.votosMunicipio;
    }

    final mesoKeys = votosPorMeso.keys.toList()
      ..sort((a, b) => (votosPorMeso[b] ?? 0).compareTo(votosPorMeso[a] ?? 0));

    final totalOriginal = mapa.totalVotos;
    var totalProjetado = 0.0;
    String? maiorCrescimentoKey;
    var maiorCrescimento = 0.0;

    for (final key in mesoKeys) {
      final votos = votosPorMeso[key] ?? 0;
      final ajuste = _ajustes[key] ?? 0;
      totalProjetado += votos * (1 + ajuste);
      final ganho = votos * ajuste;
      if (ganho > maiorCrescimento) {
        maiorCrescimento = ganho;
        maiorCrescimentoKey = key;
      }
    }

    final diff = totalProjetado.round() - totalOriginal;
    final diffPct =
        totalOriginal > 0 ? (diff / totalOriginal) * 100 : 0.0;

    // Dica de meta: quanto falta para +10%
    final meta10 = (totalOriginal * 1.1).round();
    final faltaMeta = meta10 - totalProjetado.round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ── Card de resultado ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('ORIGINAL',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onPrimary.withValues(alpha: 0.8),
                            fontSize: 9,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                          )),
                      Text(
                        _numFmt.format(totalOriginal),
                        style: tt.titleMedium?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      color: cs.onPrimary.withValues(alpha: 0.7)),
                  Column(
                    children: [
                      Text('PROJETADO',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onPrimary.withValues(alpha: 0.8),
                            fontSize: 9,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                          )),
                      Text(
                        _numFmt.format(totalProjetado.round()),
                        style: tt.titleLarge?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.onPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  diff == 0
                      ? 'Ajuste os sliders para simular cenários'
                      : '${diff > 0 ? '+' : ''}${_numFmt.format(diff)} votos '
                          '(${diffPct >= 0 ? '+' : ''}${diffPct.toStringAsFixed(1)}%)',
                  style: tt.labelMedium?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (faltaMeta > 0 && diff != 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Para +10% faltam ${_numFmt.format(faltaMeta)} votos',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onPrimary.withValues(alpha: 0.85),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Destaque de maior crescimento ─────────────────────────────────
        if (maiorCrescimentoKey != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up_rounded,
                    size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Maior crescimento: '
                    '${MesorregiaoColors.nomes[maiorCrescimentoKey] ?? maiorCrescimentoKey} '
                    '(+${_numFmt.format(maiorCrescimento.round())} votos)',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        Text(
          'Ajuste por mesorregião',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Simule o impacto de crescer (ou perder) votos em cada região.',
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),

        // ── Sliders ───────────────────────────────────────────────────────
        for (final key in mesoKeys)
          _MesoSliderCard(
            nome: MesorregiaoColors.nomes[key] ?? key,
            cor: MesorregiaoColors.cores[key] ?? cs.primary,
            votosOriginais: votosPorMeso[key] ?? 0,
            ajuste: _ajustes[key] ?? 0,
            onChanged: (v) => setState(() => _ajustes[key] = v),
          ),
      ],
    );
  }
}

class _MesoSliderCard extends StatelessWidget {
  const _MesoSliderCard({
    required this.nome,
    required this.cor,
    required this.votosOriginais,
    required this.ajuste,
    required this.onChanged,
  });

  final String nome;
  final Color cor;
  final int votosOriginais;
  final double ajuste;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final projetado = (votosOriginais * (1 + ajuste)).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ajuste != 0
              ? cor.withValues(alpha: 0.5)
              : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nome,
                  style:
                      tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ajuste == 0
                      ? cs.surfaceContainerHighest
                      : ajuste > 0
                          ? Colors.green.withValues(alpha: 0.15)
                          : cs.errorContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${ajuste >= 0 ? '+' : ''}${(ajuste * 100).round()}%',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    color: ajuste == 0
                        ? cs.onSurfaceVariant
                        : ajuste > 0
                            ? Colors.green.shade800
                            : cs.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_numFmt.format(votosOriginais)} votos',
                style: tt.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
              ),
              if (ajuste != 0)
                Text(
                  '→ ${_numFmt.format(projetado)}',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: cor,
                  ),
                ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: cor,
              thumbColor: cor,
              overlayColor: cor.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: ajuste,
              min: -0.5,
              max: 1.0,
              divisions: 30,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
