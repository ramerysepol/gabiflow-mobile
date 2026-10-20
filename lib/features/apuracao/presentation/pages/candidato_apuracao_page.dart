import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/friendly_error.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../electoral_data/data/models/municipio_voto_model.dart';
import '../../../electoral_data/presentation/widgets/erro_inline.dart';
import '../../../electoral_data/presentation/widgets/mapa_ba_widget.dart';
import '../../data/models/apuracao_candidato_model.dart';
import '../../data/models/apuracao_ranking_model.dart';
import '../apuracao_format.dart';
import '../providers/apuracao_providers.dart';
import '../widgets/barra_progresso.dart';
import '../widgets/linha_candidato.dart';
import '../widgets/linha_de_corte.dart';
import '../widgets/projecao_badge.dart';
import '../widgets/onde_falta_section.dart';
import '../../data/models/apuracao_territorio_model.dart';
import '../../../../core/utils/texto.dart';

enum _OrdemMunicipio { votos, nome, posicao }

/// Ficha de um candidato na apuração ao vivo: votação, disputa direta,
/// partido/federação e votos por município. Atualiza sozinha a cada 30s.
class CandidatoApuracaoPage extends ConsumerStatefulWidget {
  const CandidatoApuracaoPage({super.key, required this.sqcand});

  final String sqcand;

  @override
  ConsumerState<CandidatoApuracaoPage> createState() =>
      _CandidatoApuracaoPageState();
}

class _CandidatoApuracaoPageState extends ConsumerState<CandidatoApuracaoPage> {
  Timer? _pollTimer;
  bool _acaoEmAndamento = false;

  final _municipioSearchCtrl = TextEditingController();
  String _municipioQuery = '';
  _OrdemMunicipio _ordemMunicipio = _OrdemMunicipio.votos;
  bool _mapaExpandido = false;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.invalidate(apuracaoCandidatoProvider(widget.sqcand));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _municipioSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _tornarPrincipal() async {
    setState(() => _acaoEmAndamento = true);
    try {
      await ref
          .read(apuracaoSeguidosProvider.notifier)
          .tornarPrincipal(widget.sqcand);
      ref.invalidate(apuracaoCandidatoProvider(widget.sqcand));
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _acaoEmAndamento = false);
    }
  }

  Future<void> _alternarAcompanhar(bool seguindo) async {
    setState(() => _acaoEmAndamento = true);
    try {
      if (seguindo) {
        await ref
            .read(apuracaoSeguidosProvider.notifier)
            .deixarDeSeguir(widget.sqcand);
      } else {
        await ref.read(apuracaoSeguidosProvider.notifier).seguir(widget.sqcand);
      }
      ref.invalidate(apuracaoCandidatoProvider(widget.sqcand));
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _acaoEmAndamento = false);
    }
  }

  void _mostrarErro(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagemAmigavel(e))));
  }

  void _compartilhar(ApuracaoCandidatoModel dados) {
    unawaited(Share.share(textoCompartilharApuracao(dados)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(appRetomadoProvider, (prev, next) {
      if (prev != next && mounted) {
        ref.invalidate(apuracaoCandidatoProvider(widget.sqcand));
      }
    });

    final async = ref.watch(apuracaoCandidatoProvider(widget.sqcand));
    final dadosAtuais = async.valueOrNull;
    final territorio = ref
        .watch(apuracaoTerritorioProvider(widget.sqcand))
        .valueOrNull;
    final linhas2022 = <String, ApuracaoTerritorioLinha>{
      if (territorio?.base2022.encontrado ?? false)
        for (final l in territorio!.municipios) l.cd: l,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(dadosAtuais?.candidato.nomeUrna ?? 'Apuração ao vivo'),
        actions: [
          if (dadosAtuais != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Compartilhar',
              onPressed: () => _compartilhar(dadosAtuais),
            ),
        ],
      ),
      body: async.when(
        skipLoadingOnRefresh: true,
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ShimmerSkeleton.card(height: 100),
            ),
          ),
        ),
        error: (e, _) => ErroInline(
          mensagem: mensagemAmigavel(e),
          onRetry: () =>
              ref.invalidate(apuracaoCandidatoProvider(widget.sqcand)),
        ),
        data: (dados) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(apuracaoCandidatoProvider(widget.sqcand).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.md,
              AppSpacing.screenH,
              AppSpacing.xxl,
            ),
            children: [
              _HeaderCandidato(
                dados: dados,
                acaoEmAndamento: _acaoEmAndamento,
                onDefinirPrincipal: _tornarPrincipal,
                onAlternarAcompanhar: () =>
                    _alternarAcompanhar(dados.candidato.seguido),
              ),
              const SizedBox(height: AppSpacing.lg),
              _KpisCandidato(geral: dados.geral, resumo: dados.resumo),
              if (dados.corte != null) ...[
                const SizedBox(height: AppSpacing.sm),
                LinhaDeCorteCard(
                  corte: dados.corte!,
                  sqcandAtual: widget.sqcand,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              OndeFaltaOVotoSection(sqcand: widget.sqcand),
              if (dados.historico.length >= 2) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'EVOLUÇÃO DA VOTAÇÃO',
                  style: AppTextStyles.eyebrow(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 160,
                  child: _GraficoHistorico(historico: dados.historico),
                ),
              ],
              if (dados.vizinhos.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('DISPUTA DIRETA', style: AppTextStyles.eyebrow(context)),
                const SizedBox(height: AppSpacing.sm),
                _DisputaDiretaList(
                  sqcandAtual: widget.sqcand,
                  vizinhos: dados.vizinhos,
                ),
              ],
              if (dados.agremiacao != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'PARTIDO/FEDERAÇÃO',
                  style: AppTextStyles.eyebrow(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                _AgremiacaoSection(
                  sqcandAtual: widget.sqcand,
                  agremiacao: dados.agremiacao!,
                ),
              ],
              if ((dados.candidato.uf?.toLowerCase() ?? '') == 'ba' &&
                  dados.municipios.any((m) => m.votos > 0)) ...[
                const SizedBox(height: AppSpacing.lg),
                _MapaCalorSection(
                  municipios: dados.municipios,
                  expandido: _mapaExpandido,
                  onToggle: () =>
                      setState(() => _mapaExpandido = !_mapaExpandido),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                'VOTOS POR MUNICÍPIO',
                style: AppTextStyles.eyebrow(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MunicipiosSection(
                municipios: dados.municipios,
                linhas2022: linhas2022,
                query: _municipioQuery,
                ordem: _ordemMunicipio,
                searchCtrl: _municipioSearchCtrl,
                onQueryChanged: (v) => setState(() => _municipioQuery = v),
                onOrdemChanged: (o) => setState(() => _ordemMunicipio = o),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cabeçalho ────────────────────────────────────────────────────────────────

class _HeaderCandidato extends StatelessWidget {
  const _HeaderCandidato({
    required this.dados,
    required this.acaoEmAndamento,
    required this.onDefinirPrincipal,
    required this.onAlternarAcompanhar,
  });

  final ApuracaoCandidatoModel dados;
  final bool acaoEmAndamento;
  final VoidCallback onDefinirPrincipal;
  final VoidCallback onAlternarAcompanhar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final c = dados.candidato;
    final geral = dados.geral;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    c.numero ?? '?',
                    maxLines: 1,
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.nomeUrna,
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      c.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (c.cargoNome != null) c.cargoNome,
                        if (c.partido != null) c.partido,
                        if (c.uf != null) c.uf!.toUpperCase(),
                      ].join(' · '),
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (c.vices != null && c.vices!.isNotEmpty)
                      Text(
                        'Vice: ${c.vices}',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (geral != null)
                ProjecaoBadge(
                  projecao: geral.projecao,
                  projecaoVia: geral.projecaoVia,
                  pctSecoes: dados.resumo?.pctSecoes,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (!c.principal) ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: acaoEmAndamento ? null : onDefinirPrincipal,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline_rounded, size: 18),
                        SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Definir como meu candidato'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: acaoEmAndamento ? null : onAlternarAcompanhar,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        c.seguido
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            c.seguido ? 'Parar de acompanhar' : 'Acompanhar',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── KPIs ─────────────────────────────────────────────────────────────────────

class _KpisCandidato extends StatelessWidget {
  const _KpisCandidato({required this.geral, required this.resumo});

  final ApuracaoCandVoto? geral;
  final ApuracaoResumo? resumo;

  @override
  Widget build(BuildContext context) {
    final votos = geral?.votos;
    final pct = geral?.pct;
    final posicao = geral?.posicao;
    final vagas = geral?.vagas;
    final pctSecoes = resumo?.pctSecoes;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.9,
      children: [
        _KpiCard(
          label: 'Votos',
          value: formatarVotosApuracao(votos),
          icon: Icons.how_to_vote_outlined,
        ),
        _KpiCard(
          label: '% dos válidos',
          value: formatarPctApuracao(pct),
          icon: Icons.pie_chart_outline_rounded,
        ),
        _KpiCard(
          label: 'Posição',
          value: posicao != null
              ? '$posicao${vagas != null ? "/$vagas" : ""}'
              : '—',
          icon: Icons.leaderboard_outlined,
        ),
        _KpiCard(
          label: 'Seções apuradas',
          value: formatarPctApuracao(pctSecoes),
          icon: Icons.fact_check_outlined,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gráfico histórico ────────────────────────────────────────────────────────

class _GraficoHistorico extends StatelessWidget {
  const _GraficoHistorico({required this.historico});

  final List<ApuracaoHistoricoPonto> historico;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final pontos = <FlSpot>[
      for (var i = 0; i < historico.length; i++)
        FlSpot(i.toDouble(), historico[i].votos.toDouble()),
    ];
    final minY = pontos.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final step = historico.length > 4 ? (historico.length / 4).ceil() : 1;

    return LineChart(
      LineChartData(
        minY: minY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: null,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: step.toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= historico.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    formatarHoraCurtaApuracao(historico[i].em),
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: pontos,
            isCurved: true,
            color: cs.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Disputa direta ───────────────────────────────────────────────────────────

class _DisputaDiretaList extends StatelessWidget {
  const _DisputaDiretaList({required this.sqcandAtual, required this.vizinhos});

  final String sqcandAtual;
  final List<ApuracaoVizinho> vizinhos;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: vizinhos
          .map(
            (v) => LinhaCandidato(
              posicao: v.posicao,
              nomeUrna: v.nomeUrna,
              numero: v.numero,
              partido: v.partido,
              votos: v.votos,
              pct: v.pct,
              projecao: v.projecao,
              destacado: v.sqcand == sqcandAtual,
            ),
          )
          .toList(),
    );
  }
}

// ─── Partido/federação ────────────────────────────────────────────────────────

class _AgremiacaoSection extends StatelessWidget {
  const _AgremiacaoSection({
    required this.sqcandAtual,
    required this.agremiacao,
  });

  final String sqcandAtual;
  final ApuracaoAgremiacaoCandidato agremiacao;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    agremiacao.nome,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${agremiacao.vagas} vaga${agremiacao.vagas == 1 ? '' : 's'}',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...agremiacao.colegas.map(
            (col) => LinhaCandidato(
              posicao: col.posicaoAgr,
              nomeUrna: col.nomeUrna,
              numero: col.numero,
              partido: col.partido,
              votos: col.votos,
              pct: col.pct,
              projecao: col.projecao,
              destacado: col.sqcand == sqcandAtual,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mapa de calor ────────────────────────────────────────────────────────────

class _MapaCalorSection extends StatelessWidget {
  const _MapaCalorSection({
    required this.municipios,
    required this.expandido,
    required this.onToggle,
  });

  final List<ApuracaoMunicipioVoto> municipios;
  final bool expandido;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final votados = municipios.where((m) => m.votos > 0).toList();
    final maxVotos = votados.isEmpty
        ? 1
        : votados.map((m) => m.votos).reduce((a, b) => a > b ? a : b);
    final municipiosMapa = votados
        .map(
          (m) => MunicipioVotoModel(
            idMunicipio: m.ibge ?? m.cd,
            nomeMunicipio: m.nome,
            votosMunicipio: m.votos,
            percentualMunicipio: (m.pct ?? 0).toDouble(),
          ),
        )
        .toList();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: ExpansionTile(
          initiallyExpanded: expandido,
          onExpansionChanged: (_) => onToggle(),
          title: Text(
            'Mapa de calor',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${votados.length} município${votados.length == 1 ? '' : 's'} '
            'com votos apurados',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          children: [
            SizedBox(
              height: 320,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.card),
                ),
                child: MapaBaWidget(
                  municipios: municipiosMapa,
                  maxVotos: maxVotos,
                  modoInicialCalor: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Votos por município ──────────────────────────────────────────────────────

class _MunicipiosSection extends StatelessWidget {
  const _MunicipiosSection({
    required this.municipios,
    required this.query,
    required this.ordem,
    required this.searchCtrl,
    required this.onQueryChanged,
    required this.onOrdemChanged,
    this.linhas2022 = const {},
  });

  final List<ApuracaoMunicipioVoto> municipios;
  final Map<String, ApuracaoTerritorioLinha> linhas2022;
  final String query;
  final _OrdemMunicipio ordem;
  final TextEditingController searchCtrl;
  final void Function(String query) onQueryChanged;
  final void Function(_OrdemMunicipio ordem) onOrdemChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (municipios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Text(
          'Ainda sem dados por município',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    final filtrados = query.isEmpty
        ? municipios
        : municipios
              .where((m) => semAcento(m.nome).contains(semAcento(query)))
              .toList();

    final ordenados = [...filtrados]
      ..sort((a, b) {
        switch (ordem) {
          case _OrdemMunicipio.nome:
            return a.nome.compareTo(b.nome);
          case _OrdemMunicipio.posicao:
            return (a.posicao ?? 999999).compareTo(b.posicao ?? 999999);
          case _OrdemMunicipio.votos:
            return b.votos.compareTo(a.votos);
        }
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchCtrl,
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Buscar município...',
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ChipOrdem(
                label: 'Votos',
                selecionado: ordem == _OrdemMunicipio.votos,
                onTap: () => onOrdemChanged(_OrdemMunicipio.votos),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ChipOrdem(
                label: 'Nome',
                selecionado: ordem == _OrdemMunicipio.nome,
                onTap: () => onOrdemChanged(_OrdemMunicipio.nome),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ChipOrdem(
                label: 'Posição',
                selecionado: ordem == _OrdemMunicipio.posicao,
                onTap: () => onOrdemChanged(_OrdemMunicipio.posicao),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (ordenados.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Nenhum município encontrado para "$query".',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else
          ...ordenados.map(
            (m) => _LinhaMunicipio(municipio: m, linha2022: linhas2022[m.cd]),
          ),
      ],
    );
  }
}

class _ChipOrdem extends StatelessWidget {
  const _ChipOrdem({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selecionado,
      onSelected: (_) => onTap(),
      selectedColor: cs.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selecionado ? cs.primary : cs.onSurfaceVariant,
        fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }
}

class _LinhaMunicipio extends StatelessWidget {
  const _LinhaMunicipio({required this.municipio, this.linha2022});

  final ApuracaoMunicipioVoto municipio;
  final ApuracaoTerritorioLinha? linha2022;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final m = municipio;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (m.capital)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        m.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        linha2022?.votos2022 != null
                            ? '2022: ${formatarVotosApuracao(linha2022!.votos2022)}'
                            : 'Nº ${m.cd}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (linha2022?.variacaoVotos != null) ...[
                      const SizedBox(width: 6),
                      _ChipVariacao2022(variacao: linha2022!.variacaoVotos!),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                BarraProgresso(
                  pct: m.pctSecoes ?? 0,
                  height: 4,
                  cor: m.finalizado ? const Color(0xFF16A34A) : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatarVotosApuracao(m.votos),
                  maxLines: 1,
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
              if (m.pct != null)
                Text(
                  formatarPctApuracao(m.pct),
                  maxLines: 1,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip compacto com a variação de votos vs. 2022 (verde quando subiu,
/// vermelho quando caiu) — usado nas linhas de município.
class _ChipVariacao2022 extends StatelessWidget {
  const _ChipVariacao2022({required this.variacao});

  final int variacao;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final subiu = variacao >= 0;
    final cor = subiu ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        '${subiu ? '+' : ''}${formatarVotosApuracao(variacao)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tt.labelSmall?.copyWith(color: cor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
