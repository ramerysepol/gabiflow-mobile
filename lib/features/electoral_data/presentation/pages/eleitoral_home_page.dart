import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../providers/eleitoral_providers.dart';
import '../../data/models/selected_election_model.dart';
import '../widgets/candidato_card.dart';

class EleitoralHomePage extends ConsumerStatefulWidget {
  const EleitoralHomePage({super.key});

  @override
  ConsumerState<EleitoralHomePage> createState() => _EleitoralHomePageState();
}

class _EleitoralHomePageState extends ConsumerState<EleitoralHomePage> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  bool _showShowcase = false;
  bool _redirectChecked = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final election = ref.read(selectedElectionProvider);
    if (election == null) {
      // Sem seleção → vai para o seletor
      if (mounted) context.go('/home/eleitoral/selecionar');
      return;
    }
    setState(() => _redirectChecked = true);
    await _checkShowcase();
    ref.read(candidatosListProvider.notifier).refresh();
  }

  Future<void> _checkShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('eleitoral_showcase_seen') ?? false;
    if (!seen && mounted) {
      setState(() => _showShowcase = true);
    }
  }

  Future<void> _dismissShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eleitoral_showcase_seen', true);
    if (mounted) setState(() => _showShowcase = false);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(candidatosListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && value == _searchCtrl.text) {
        ref.read(filtrosSelecionadosProvider.notifier).setSearch(value);
      }
    });
  }

  void _trocarEleicao() {
    // Limpa estados derivados
    ref.read(microrregiaoSelecionadaProvider.notifier).state = null;
    _searchCtrl.clear();
    ref.read(filtrosSelecionadosProvider.notifier).setSearch('');
    context.go('/home/eleitoral/selecionar');
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final election = ref.watch(selectedElectionProvider);

    // Enquanto verifica se precisa redirecionar, mostra loading
    if (!_redirectChecked || election == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final state = ref.watch(candidatosListProvider);
    final cs = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corHeader =
        isDark ? const Color(0xFF10151F) : const Color(0xFF16213E);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: corHeader,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.groups_rounded, color: Color(0xFF64B5F6), size: 22),
            SizedBox(width: 8),
            Text('Candidatos',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            tooltip: 'Análise da eleição',
            onPressed: () => context.push('/home/eleitoral/analise'),
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded),
            tooltip: 'Comparar candidatos',
            onPressed: () => context.push('/home/eleitoral/comparar'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Showcase de onboarding ────────────────────────────────────
          if (_showShowcase) _ShowcaseCard(onDismiss: _dismissShowcase),

          // ── Header: contexto da eleição selecionada ───────────────────
          _EleicaoHeaderCard(
            election: election,
            onTrocar: _trocarEleicao,
          ),

          // ── Banner do Command Center IA ───────────────────────────────
          _CommandCenterBanner(
            onTap: () => context.go('/home/eleitoral/ia'),
          ),

          const SizedBox(height: 4),

          // ── Campo de busca ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar candidato...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(filtrosSelecionadosProvider.notifier)
                              .setSearch('');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // ── Filtro por cidade (eleições municipais: prefeito/vereador) ──
          if (election.ano % 4 == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Consumer(builder: (context, ref, _) {
                final cidade = ref.watch(cidadeFiltroProvider);
                return cidade.isEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: ActionChip(
                          avatar: const Icon(Icons.location_city_rounded,
                              size: 16),
                          label: const Text('Filtrar por cidade',
                              style: TextStyle(fontSize: 12)),
                          onPressed: () => _perguntarCidade(context),
                        ),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: InputChip(
                          avatar: const Icon(Icons.location_city_rounded,
                              size: 16, color: Color(0xFF1976D2)),
                          label: Text(cidade,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                          onPressed: () => _perguntarCidade(context),
                          onDeleted: () => ref
                              .read(cidadeFiltroProvider.notifier)
                              .state = '',
                        ),
                      );
              }),
            ),
          const SizedBox(height: 8),

          // ── Lista ─────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(candidatosListProvider.notifier).refresh(),
              child: _buildList(state, cs),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _perguntarCidade(BuildContext context) async {
    final ctrl =
        TextEditingController(text: ref.read(cidadeFiltroProvider));
    final cidade = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtrar por cidade'),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'ex.: Salvador',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(''),
            child: const Text('Limpar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    if (cidade != null) {
      ref.read(cidadeFiltroProvider.notifier).state = cidade.trim();
    }
  }

  Widget _buildList(CandidatosListState state, ColorScheme cs) {
    if (state.isLoading) {
      return ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ShimmerSkeleton.card(height: 72),
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return AppEmptyState(
        title: 'Erro ao carregar',
        subtitle: state.error!,
        actionLabel: 'Tentar novamente',
        onAction: () => ref.read(candidatosListProvider.notifier).refresh(),
      );
    }

    if (state.items.isEmpty) {
      return const AppEmptyState(
        title: 'Nenhum candidato encontrado',
        subtitle: 'Tente ajustar a busca ou troque a eleição',
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == state.items.length) {
          return state.isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }
        final candidato = state.items[i];
        return CandidatoCard(
          candidato: candidato,
          onTap: () => context.push(
              '/home/eleitoral/candidato/${candidato.sequencial}'),
        );
      },
    );
  }
}

// ─── Banner do Command Center IA ─────────────────────────────────────────────

class _CommandCenterBanner extends StatelessWidget {
  const _CommandCenterBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: cs.onPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Command Center IA',
                    style: tt.labelLarge?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Insights, alertas e chat com dados reais do TSE',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.85),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.onPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'NOVO',
                style: tt.labelSmall?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: cs.onPrimary),
          ],
        ),
      ),
    );
  }
}

// ─── Header com contexto da eleição ──────────────────────────────────────────

class _EleicaoHeaderCard extends StatelessWidget {
  const _EleicaoHeaderCard({
    required this.election,
    required this.onTrocar,
  });

  final SelectedElection election;
  final VoidCallback onTrocar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.how_to_vote_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              election.labelCompleto,
              style: tt.labelMedium?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTrocar,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_rounded,
                      size: 14, color: cs.onPrimary),
                  const SizedBox(width: 4),
                  Text(
                    'Trocar',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
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

// ─── Showcase de onboarding ───────────────────────────────────────────────────

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explore os Dados Eleitorais',
                style: tt.titleSmall?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: cs.onPrimary, size: 18),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _ShowcaseItem(
                  icon: Icons.map_outlined, text: 'Votos no mapa\ninterativo'),
              SizedBox(width: 12),
              _ShowcaseItem(
                  icon: Icons.analytics_outlined,
                  text: 'Dados IBGE\npor município'),
              SizedBox(width: 12),
              _ShowcaseItem(
                  icon: Icons.compare_arrows, text: 'Compare\ncandidatos'),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDismiss,
              child: Text(
                'Pular',
                style: tt.labelMedium
                    ?.copyWith(color: cs.onPrimary.withValues(alpha: 0.8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseItem extends StatelessWidget {
  const _ShowcaseItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.onPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: cs.onPrimary, size: 20),
            const SizedBox(height: 4),
            Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onPrimary,
                    fontSize: 10,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
