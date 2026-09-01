import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../electoral_data/presentation/providers/eleitoral_providers.dart';
import '../../data/models/ia_contexto_model.dart';
import '../../data/models/ia_models.dart';
import '../providers/command_center_providers.dart';
import '../widgets/ia_candidato_picker.dart';
import '../widgets/ia_visualization_view.dart';

final _numFmt = NumberFormat.decimalPattern('pt_BR');

/// Hub do Command Center IA Eleitoral.
/// Insight do dia, alertas, briefing e radar — tudo cruzando TSE × gabinete.
class CommandCenterPage extends ConsumerWidget {
  const CommandCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contexto = ref.watch(iaContextoProvider);
    final election = ref.watch(selectedElectionProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corHeader =
        isDark ? const Color(0xFF10151F) : const Color(0xFF16213E);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: corHeader,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Voltar ao GabiFlow',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: Color(0xFFFFD54F), size: 22),
            SizedBox(width: 8),
            Text('Command Center',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        actions: [
          if (contexto != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Trocar candidato',
              onPressed: () => showIaCandidatoPicker(context),
            ),
        ],
      ),
      body: contexto == null
          ? _EmptyContexto(onSelect: () => showIaCandidatoPicker(context))
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(iaInsightProvider);
                ref.invalidate(iaAlertasProvider);
                ref.invalidate(iaBriefingProvider);
                ref.invalidate(iaRadarProvider);
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _HeroHeader(
                    contexto: contexto,
                    electionLabel: election?.labelCompleto ?? '',
                  ),
                  const _AskBar(),
                  const SizedBox(height: 8),
                  const _InsightDiaCard(),
                  const _AlertasSection(),
                  const _BriefingSection(),
                  const _RadarSection(),
                ],
              ),
            ),
    );
  }
}

// ─── Estado vazio: escolher candidato ────────────────────────────────────────

class _EmptyContexto extends StatelessWidget {
  const _EmptyContexto({required this.onSelect});

  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, size: 40, color: cs.onPrimary),
            ),
            const SizedBox(height: 20),
            Text(
              'Command Center Eleitoral',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Consultoria de inteligência eleitoral em tempo real. '
              'Cada número vem de uma consulta real aos dados do TSE, '
              'IBGE e do seu gabinete — sem suposições.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.person_search_rounded, size: 18),
              label: const Text('Escolher candidato'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero header ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.contexto, required this.electionLabel});

  final IaContexto contexto;
  final String electionLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary,
            Color.lerp(cs.primary, cs.tertiary, 0.55)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Marca d'água decorativa
          Positioned(
            right: -28,
            top: -28,
            child: Icon(
              Icons.auto_awesome,
              size: 130,
              color: cs.onPrimary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -34,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.onPrimary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 11, color: cs.onPrimary),
                      const SizedBox(width: 5),
                      Text(
                        'IA ELEITORAL · DADOS REAIS TSE',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 8.5,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.onPrimary.withValues(alpha: 0.7),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor:
                            cs.onPrimary.withValues(alpha: 0.22),
                        backgroundImage: contexto.fotoUrl != null
                            ? CachedNetworkImageProvider(contexto.fotoUrl!)
                            : null,
                        child: contexto.fotoUrl == null
                            ? Text(
                                contexto.nomeCandidato.isNotEmpty
                                    ? contexto.nomeCandidato[0]
                                    : '?',
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contexto.nomeCandidato,
                            style: tt.titleLarge?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            electionLabel.isNotEmpty
                                ? '${contexto.siglaPartido} · $electionLabel'
                                : contexto.siglaPartido,
                            style: tt.labelSmall?.copyWith(
                              color:
                                  cs.onPrimary.withValues(alpha: 0.75),
                              fontSize: 10.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Stat chips "vidro"
                Row(
                  children: [
                    _HeroStat(
                      icon: Icons.how_to_vote_rounded,
                      value: _numFmt.format(contexto.votosTotal),
                      label: 'votos',
                    ),
                    const SizedBox(width: 8),
                    _HeroStat(
                      icon: Icons.workspace_premium_rounded,
                      value: _cargoCurto(contexto.cargo),
                      label: 'cargo',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _cargoCurto(String cargo) {
    final c = cargo.replaceAll('_', ' ');
    if (c.isEmpty) return '—';
    return c
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.onPrimary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: cs.onPrimary.withValues(alpha: 0.9)),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelMedium?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.65),
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Barra "Pergunte à IA" + sugestões ───────────────────────────────────────

class _AskBar extends ConsumerWidget {
  const _AskBar();

  static const _sugestoes = [
    'Onde eu posso crescer?',
    'Quais municípios têm votos mas o gabinete não atua?',
    'Quem foram meus maiores adversários?',
    'Como está minha cobertura territorial?',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: GestureDetector(
            onTap: () => context.push('/home/eleitoral/ia/chat'),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome,
                        size: 18, color: cs.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pergunte qualquer coisa aos seus dados...',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      size: 20, color: cs.primary),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: _FadeBordaHorizontal(
            child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 24, 0),
            children: [
              for (final s in _sugestoes)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => context.push(
                      Uri(
                        path: '/home/eleitoral/ia/chat',
                        queryParameters: {'q': s},
                      ).toString(),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 13, color: cs.primary),
                          const SizedBox(width: 5),
                          Text(
                            s,
                            style: tt.labelSmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Máscara de fade na borda direita para faixas com rolagem horizontal —
/// o conteúdo se dissolve em vez de ser cortado seco na borda da tela.
class _FadeBordaHorizontal extends StatelessWidget {
  const _FadeBordaHorizontal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.92, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}

// ─── Insight do dia ──────────────────────────────────────────────────────────

class _InsightDiaCard extends ConsumerWidget {
  const _InsightDiaCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(iaInsightProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: async.when(
        loading: () => ShimmerSkeleton.card(height: 88),
        error: (_, __) => const SizedBox.shrink(),
        data: (insight) => insight.insight.isEmpty
            ? const SizedBox.shrink()
            : Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Acento lateral
                      Container(width: 4, color: cs.tertiary),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: cs.tertiaryContainer,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                        Icons.lightbulb_rounded,
                                        size: 15,
                                        color: cs.onTertiaryContainer),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'INSIGHT DO DIA',
                                    style: tt.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                      fontSize: 9.5,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const Spacer(),
                                  _TipoBadge(tipo: insight.tipo),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () =>
                                        ref.invalidate(iaInsightProvider),
                                    child: Icon(Icons.refresh_rounded,
                                        size: 16,
                                        color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                insight.insight,
                                style: tt.bodySmall?.copyWith(
                                  height: 1.5,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _TipoBadge extends StatelessWidget {
  const _TipoBadge({required this.tipo});

  final String tipo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tipo.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: cs.tertiary,
            ),
      ),
    );
  }
}

// ─── Alertas ─────────────────────────────────────────────────────────────────

class _AlertasSection extends ConsumerWidget {
  const _AlertasSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(iaAlertasProvider);

    return async.when(
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: ShimmerSkeleton.card(height: 90),
      ),
      error: (_, __) => _ErroCard(
        mensagem: 'Não foi possível carregar os alertas',
        onRetry: () => ref.invalidate(iaAlertasProvider),
      ),
      data: (alertas) {
        if (alertas.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
                icon: Icons.notifications_active_outlined,
                title: 'Alertas inteligentes'),
            SizedBox(
              height: 148,
              child: _FadeBordaHorizontal(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 24, 0),
                  itemCount: alertas.length,
                  itemBuilder: (_, i) => _AlertaCard(alerta: alertas[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AlertaCard extends StatelessWidget {
  const _AlertaCard({required this.alerta});

  final IaAlertaModel alerta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final (color, icon, rotulo) = switch (alerta.tipo) {
      'urgente' => (cs.error, Icons.priority_high_rounded, 'URGENTE'),
      'risco' => (
          Colors.orange.shade800,
          Icons.warning_amber_rounded,
          'RISCO'
        ),
      'oportunidade' => (
          Colors.green.shade700,
          Icons.trending_up_rounded,
          'OPORTUNIDADE'
        ),
      _ => (cs.primary, Icons.info_outline_rounded, 'INFO'),
    };

    return Container(
      width: 252,
      margin: const EdgeInsets.only(right: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(icon, size: 14, color: color),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        rotulo,
                        style: tt.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 8.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    alerta.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      alerta.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (alerta.acaoSugerida != null)
                    Row(
                      children: [
                        Icon(Icons.arrow_forward_rounded,
                            size: 11, color: color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alerta.acaoSugerida!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Briefing ────────────────────────────────────────────────────────────────

class _BriefingSection extends ConsumerWidget {
  const _BriefingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(iaBriefingProvider);
    final cs = Theme.of(context).colorScheme;

    return async.when(
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: ShimmerSkeleton.card(height: 160),
      ),
      error: (_, __) => _ErroCard(
        mensagem: 'Não foi possível carregar o briefing',
        onRetry: () => ref.invalidate(iaBriefingProvider),
      ),
      data: (b) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
                icon: Icons.summarize_outlined, title: 'Briefing territorial'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatBox(
                    label: 'Cobertura',
                    value:
                        '${b.stats.coberturaTerritorialPct.toStringAsFixed(0)}%',
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  _StatBox(
                    label: 'Com voto',
                    value: _numFmt.format(b.stats.municipiosComVoto),
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  _StatBox(
                    label: 'Sem voto',
                    value: _numFmt.format(b.stats.municipiosSemVoto),
                    color: cs.error,
                  ),
                ],
              ),
            ),
            if (b.melhorMesorregiao != null || b.piorMesorregiao != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      if (b.melhorMesorregiao != null)
                        _MesoRow(
                          icon: Icons.trending_up_rounded,
                          color: Colors.green.shade700,
                          label: 'Melhor mesorregião',
                          meso: b.melhorMesorregiao!,
                        ),
                      if (b.melhorMesorregiao != null &&
                          b.piorMesorregiao != null)
                        Divider(
                            height: 16,
                            color:
                                cs.outlineVariant.withValues(alpha: 0.4)),
                      if (b.piorMesorregiao != null)
                        _MesoRow(
                          icon: Icons.trending_down_rounded,
                          color: cs.error,
                          label: 'Pior mesorregião',
                          meso: b.piorMesorregiao!,
                        ),
                    ],
                  ),
                ),
              ),
            if (b.topMunicipios.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: _TopMunicipiosMini(municipios: b.topMunicipios),
              ),
          ],
        );
      },
    );
  }
}

class _MesoRow extends StatelessWidget {
  const _MesoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.meso,
  });

  final IconData icon;
  final Color color;
  final String label;
  final IaBriefingMesorregiao meso;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant, fontSize: 9.5)),
              Text(
                meso.mesorregiao,
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          '${_numFmt.format(meso.totalVotos)} votos',
          style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TopMunicipiosMini extends StatelessWidget {
  const _TopMunicipiosMini({required this.municipios});

  final List<IaBriefingMunicipio> municipios;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final top = municipios.take(5).toList();
    final maxVotos =
        top.map((m) => m.votos).fold<int>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top municípios',
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final m in top)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
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
                    style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700, fontSize: 10.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Radar territorial ───────────────────────────────────────────────────────

class _RadarSection extends ConsumerWidget {
  const _RadarSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(iaRadarProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return async.when(
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: ShimmerSkeleton.card(height: 150),
      ),
      error: (_, __) => _ErroCard(
        mensagem: 'Não foi possível carregar o radar territorial',
        onRetry: () => ref.invalidate(iaRadarProvider),
      ),
      data: (radar) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
                icon: Icons.radar_rounded, title: 'Radar territorial'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    RadarPresencaPie(
                      forte: radar.resumo.comPresencaForte,
                      apenasVotos: radar.resumo.apenasVotos,
                      semPresenca: radar.resumo.semPresenca,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendaRow(
                            color: Colors.green.shade600,
                            label: 'Presença forte',
                            value: radar.resumo.comPresencaForte,
                          ),
                          _LegendaRow(
                            color: Colors.orange.shade600,
                            label: 'Apenas votos',
                            value: radar.resumo.apenasVotos,
                          ),
                          _LegendaRow(
                            color: cs.outlineVariant,
                            label: 'Sem presença',
                            value: radar.resumo.semPresenca,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_numFmt.format(radar.resumo.totalConstituintes)} constituintes · '
                            '${_numFmt.format(radar.resumo.totalDemandas)} demandas',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (radar.municipios.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Maior influência',
                          style: tt.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      for (final m in radar.municipios.take(5))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: switch (m.classificacao) {
                                    'forte' => Colors.green.shade600,
                                    'moderada' => Colors.orange.shade600,
                                    _ => cs.outlineVariant,
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  m.nomeMunicipio,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.labelSmall
                                      ?.copyWith(fontSize: 11),
                                ),
                              ),
                              Text(
                                'score ${m.score.toStringAsFixed(1)}',
                                style: tt.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (radar.oportunidades.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up_rounded,
                              size: 15, color: Colors.green.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'Oportunidades de crescimento',
                            style: tt.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gabinete presente, mas poucos votos — potencial de conversão.',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final m in radar.oportunidades.take(4))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m.nomeMunicipio,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.labelSmall
                                      ?.copyWith(fontSize: 11),
                                ),
                              ),
                              Text(
                                '${m.constituintes} contatos · '
                                '${_numFmt.format(m.votos)} votos',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _LegendaRow extends StatelessWidget {
  const _LegendaRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: tt.labelSmall?.copyWith(fontSize: 10.5)),
          ),
          Text(
            _numFmt.format(value),
            style: tt.labelSmall
                ?.copyWith(fontWeight: FontWeight.w700, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

// ─── Card compacto de erro com retry ─────────────────────────────────────────

class _ErroCard extends StatelessWidget {
  const _ErroCard({required this.mensagem, required this.onRetry});

  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 16, color: cs.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensagem,
                style: tt.labelSmall?.copyWith(color: cs.onErrorContainer),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Tentar', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: cs.primary),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
