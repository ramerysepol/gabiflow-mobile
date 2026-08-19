import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/eleitoral_providers.dart';
import '../widgets/numero_formatado.dart';

/// Visão Geral — a porta de entrada do sub-app Eleitoral.
///
/// Header "war room" com a eleição ativa, KPIs da eleição e um hub com TODAS
/// as ferramentas do módulo em cards grandes (nada mais escondido em ícones).
class EleitoralVisaoPage extends ConsumerWidget {
  const EleitoralVisaoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eleicao = ref.watch(selectedElectionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corHeader =
        isDark ? const Color(0xFF10151F) : const Color(0xFF16213E);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0F17) : const Color(0xFFF2F4F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: corHeader,
            foregroundColor: Colors.white,
            leading: IconButton(
              tooltip: 'Voltar ao GabiFlow',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.go('/home'),
            ),
            title: const Text(
              'Central Eleitoral',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            actions: [
              if (eleicao != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.how_to_vote_rounded,
                        size: 16, color: Colors.white),
                    label: Text(
                      eleicao.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25)),
                    onPressed: () =>
                        context.push('/home/eleitoral/selecionar'),
                  ),
                ),
            ],
          ),
          if (eleicao == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EscolherEleicao(),
            )
          else ...[
            SliverToBoxAdapter(child: _Kpis()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverToBoxAdapter(child: _HubFerramentas()),
            ),
          ],
        ],
      ),
    );
  }
}

class _EscolherEleicao extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.how_to_vote_rounded,
                size: 56, color: Color(0xFF16213E)),
            const SizedBox(height: 16),
            const Text(
              'Escolha a eleição para começar',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ano, cargo e estado definem todos os números do módulo.',
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push('/home/eleitoral/selecionar'),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Selecionar eleição'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpis extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(estatisticasProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: stats.when(
        loading: () => const SizedBox(
          height: 90,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (e) => Row(
          children: [
            _KpiCard(
              valor: formatarVotos(e.totalCandidatos),
              rotulo: 'Candidatos',
              icone: Icons.groups_rounded,
              cor: const Color(0xFF1976D2),
            ),
            const SizedBox(width: 10),
            _KpiCard(
              valor: formatarVotos(e.candidatosEleitos),
              rotulo:
                  'Eleitos (${e.percentualEleitos.toStringAsFixed(0)}%)',
              icone: Icons.emoji_events_rounded,
              cor: const Color(0xFF388E3C),
            ),
            const SizedBox(width: 10),
            _KpiCard(
              valor: '${e.candidatasMulheresPct.toStringAsFixed(0)}%',
              rotulo: 'Mulheres',
              icone: Icons.female_rounded,
              cor: const Color(0xFF7B1FA2),
            ),
            const SizedBox(width: 10),
            _KpiCard(
              valor: formatarVotos(e.totalPartidos),
              rotulo: 'Partidos',
              icone: Icons.flag_rounded,
              cor: const Color(0xFFEF6C00),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.valor,
    required this.rotulo,
    required this.icone,
    required this.cor,
  });

  final String valor;
  final String rotulo;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icone, size: 18, color: cor),
            const SizedBox(height: 6),
            Text(valor,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5, color: cs.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubFerramentas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ferramentas = [
      (
        'Mapa de Calor',
        'Onde estão os votos, município a município',
        Icons.local_fire_department_rounded,
        const [Color(0xFFE53935), Color(0xFFEF6C00)],
        () => context.go('/home/eleitoral/mapa'),
      ),
      (
        'Candidatos',
        'Busque e explore perfis completos',
        Icons.groups_rounded,
        const [Color(0xFF1976D2), Color(0xFF42A5F5)],
        () => context.go('/home/eleitoral/candidatos'),
      ),
      (
        'Rankings',
        'Municípios, partidos e coligações',
        Icons.leaderboard_rounded,
        const [Color(0xFF388E3C), Color(0xFF66BB6A)],
        () => context.go('/home/eleitoral/rankings'),
      ),
      (
        'Comparar',
        'Até 4 candidatos lado a lado',
        Icons.compare_arrows_rounded,
        const [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
        () => context.push('/home/eleitoral/comparar'),
      ),
      (
        'Análise Estatística',
        'Gênero, situação, partidos e mais',
        Icons.insights_rounded,
        const [Color(0xFF00897B), Color(0xFF26A69A)],
        () => context.push('/home/eleitoral/analise'),
      ),
      (
        'Command Center IA',
        'Briefing, alertas e chat com dados TSE',
        Icons.auto_awesome_rounded,
        const [Color(0xFF16213E), Color(0xFF3949AB)],
        () => context.go('/home/eleitoral/ia'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 12, 4, 10),
          child: Text('Ferramentas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            for (final (titulo, subtitulo, icone, cores, acao) in ferramentas)
              _FerramentaCard(
                titulo: titulo,
                subtitulo: subtitulo,
                icone: icone,
                cores: cores,
                onTap: acao,
              ),
          ],
        ),
      ],
    );
  }
}

class _FerramentaCard extends StatelessWidget {
  const _FerramentaCard({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.cores,
    required this.onTap,
  });

  final String titulo;
  final String subtitulo;
  final IconData icone;
  final List<Color> cores;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cores,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icone, color: Colors.white, size: 26),
                const Spacer(),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 10.5,
                    height: 1.2,
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
