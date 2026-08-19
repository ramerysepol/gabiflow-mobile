import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../command_center/data/models/ia_contexto_model.dart';
import '../../../command_center/presentation/providers/command_center_providers.dart';
import '../../data/models/candidato_stats_model.dart';
import '../providers/eleitoral_providers.dart';
import '../widgets/eleicao_contexto_chip.dart';
import '../widgets/erro_inline.dart';
import '../widgets/hierarquia_tree.dart';
import '../widgets/kpis_candidato.dart';
import '../widgets/ranking_item.dart';
import '../widgets/top_municipios_list.dart';
import 'candidato_mapa_page.dart';

class CandidatoDetailPage extends ConsumerWidget {
  const CandidatoDetailPage({super.key, required this.sequencial});

  final String sequencial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(candidatoDetalheProvider(sequencial));

    return asyncData.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(4, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerSkeleton.card(height: 80),
          )),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: ErroInline(
          mensagem: 'Não foi possível carregar o candidato',
          onRetry: () => ref.invalidate(candidatoDetalheProvider(sequencial)),
        ),
      ),
      data: (full) => _CandidatoView(full: full, sequencial: sequencial),
    );
  }
}

class _CandidatoView extends ConsumerStatefulWidget {
  const _CandidatoView({required this.full, required this.sequencial});

  final CandidatoFullModel full;
  final String sequencial;

  @override
  ConsumerState<_CandidatoView> createState() => _CandidatoViewState();
}

class _CandidatoViewState extends ConsumerState<_CandidatoView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final full = widget.full;
    final c = full.candidato;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'ia_candidato_fab',
        onPressed: () async {
          await ref.read(iaContextoProvider.notifier).select(
                IaContexto(
                  sequencial: widget.sequencial,
                  nomeCandidato:
                      c.nomeUrna.isNotEmpty ? c.nomeUrna : c.nome,
                  siglaPartido: c.siglaPartido,
                  cargo: c.cargo,
                  votosTotal: full.stats.votosTotal,
                  fotoUrl: c.fotoUrl,
                ),
              );
          if (context.mounted) context.go('/home/eleitoral/ia');
        },
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text('Analisar com IA'),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) {
          return [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              // Chip de contexto como action no topo — não sobrepõe o hero
              actions: [
                IconButton(
                  icon: const Icon(Icons.science_outlined),
                  tooltip: 'Simulador de projeção',
                  onPressed: () => context.push(
                    Uri(
                      path:
                          '/home/eleitoral/candidato/${widget.sequencial}/simulador',
                      queryParameters: {'nome': c.nomeUrna},
                    ).toString(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12, top: 8),
                  child: EleicaoContextoChip(),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [cs.primaryContainer, cs.surface],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 52),
                          child: Center(
                            child: _HeroCandidato(
                              nomeUrna: c.nomeUrna,
                              fotoUrl: c.fotoUrl,
                              sigla: c.siglaPartido,
                              cargo: c.cargo,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Resumo'),
                  Tab(text: 'Mapa'),
                  Tab(text: 'Hierarquia'),
                  Tab(text: 'Rankings'),
                ],
                isScrollable: false,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Resumo ────────────────────────────────────────────────────
            _ResumoTab(full: full),
            // ── Mapa ──────────────────────────────────────────────────────
            _MapaTab(sequencial: widget.sequencial),
            // ── Hierarquia ────────────────────────────────────────────────
            HierarquiaTree(sequencial: widget.sequencial),
            // ── Rankings ──────────────────────────────────────────────────
            _RankingsTab(sequencial: widget.sequencial),
          ],
        ),
      ),
    );
  }
}

/// Converte cargo do formato snake_case para título legível.
/// Ex: "deputado_federal" → "Deputado Federal"
String _formatCargo(String cargo) {
  return cargo
      .split('_')
      .map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
      .join(' ');
}

class _HeroCandidato extends StatelessWidget {
  const _HeroCandidato({
    required this.nomeUrna,
    required this.fotoUrl,
    required this.sigla,
    required this.cargo,
  });

  final String nomeUrna;
  final String? fotoUrl;
  final String sigla;
  final String cargo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inicial = nomeUrna.isNotEmpty ? nomeUrna[0].toUpperCase() : '?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar 96px centralizado
        CircleAvatar(
          radius: 48,
          backgroundColor: cs.primaryContainer,
          child: fotoUrl != null && fotoUrl!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: fotoUrl!,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Text(
                      inicial,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                )
              : Text(
                  inicial,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        // Nome do candidato
        Text(
          nomeUrna,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // Sigla · Cargo — exibe apenas sigla, sem repetir o nome do partido
        Text(
          '$sigla · ${_formatCargo(cargo)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ResumoTab extends StatelessWidget {
  const _ResumoTab({required this.full});

  final CandidatoFullModel full;

  @override
  Widget build(BuildContext context) {
    final stats = full.stats;
    final topMunicipios = full.topMunicipios;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bio
        if (full.candidato.bio != null && full.candidato.bio!.isNotEmpty) ...[
          Text(full.candidato.bio!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
        ],
        // KPIs
        KpisCandidato(stats: stats),
        const SizedBox(height: 16),
        // Maior/Menor votação
        if (stats.maiorVotacaoMunicipio != null)
          _MunicipioDestaqueCard(
            titulo: 'Maior votação',
            municipio: stats.maiorVotacaoMunicipio!.nome,
            votos: stats.maiorVotacaoMunicipio!.votos,
            icon: Icons.trending_up,
            positive: true,
          ),
        const SizedBox(height: 8),
        if (stats.menorVotacaoMunicipio != null)
          _MunicipioDestaqueCard(
            titulo: 'Menor votação',
            municipio: stats.menorVotacaoMunicipio!.nome,
            votos: stats.menorVotacaoMunicipio!.votos,
            icon: Icons.trending_down,
            positive: false,
          ),
        const SizedBox(height: 16),
        // Top municípios
        TopMunicipiosList(municipios: topMunicipios),
      ],
    );
  }
}

class _MunicipioDestaqueCard extends StatelessWidget {
  const _MunicipioDestaqueCard({
    required this.titulo,
    required this.municipio,
    required this.votos,
    required this.icon,
    required this.positive,
  });

  final String titulo;
  final String municipio;
  final int votos;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                Text(municipio, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(
            votos.toString(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MapaTab extends ConsumerWidget {
  const _MapaTab({required this.sequencial});

  final String sequencial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapaAsync = ref.watch(candidatoMapaProvider(sequencial));

    return mapaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErroInline(
        mensagem: 'Não foi possível carregar o mapa',
        onRetry: () => ref.invalidate(candidatoMapaProvider(sequencial)),
      ),
      data: (data) => Column(
        children: [
          Expanded(
            child: CandidatoMapaPage(
              sequencial: sequencial,
              municipios: data.municipios,
              maxVotos: data.maxVotosMunicipio,
              embedded: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingsTab extends ConsumerWidget {
  const _RankingsTab({required this.sequencial});

  final String sequencial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mostra rankings por municípios como padrão nesta aba
    final filtros = ref.watch(filtrosSelecionadosProvider);
    final params = RankingParams(tipo: 'municipios', cargo: filtros.cargo);
    final asyncData = ref.watch(rankingProvider(params));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErroInline(
        mensagem: 'Não foi possível carregar o ranking',
        onRetry: () => ref.invalidate(rankingProvider(params)),
      ),
      data: (ranking) {
        if (ranking.items.isEmpty) {
          return const Center(child: Text('Nenhum dado de ranking disponível'));
        }
        return ListView.separated(
          itemCount: ranking.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) => RankingItemWidget(
            posicao: i + 1,
            item: ranking.items[i],
            tipo: params.tipo,
          ),
        );
      },
    );
  }
}
