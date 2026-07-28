import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../whatsapp/presentation/widgets/whatsapp_send_sheet.dart';
import '../../data/models/constituent_extras.dart';
import '../../data/models/constituent_model.dart';
import '../providers/constituent_provider.dart';

class ConstituentsListPage extends ConsumerStatefulWidget {
  const ConstituentsListPage({super.key});

  @override
  ConsumerState<ConstituentsListPage> createState() =>
      _ConstituentsListPageState();
}

class _ConstituentsListPageState extends ConsumerState<ConstituentsListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Busca com debounce: 1 requisição a cada pausa de digitação,
  /// não uma por tecla.
  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(constituentListProvider.notifier).search(q);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(constituentListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(constituentListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _searchController,
              onSearch: _onSearchChanged,
            ),
            _FiltrosBar(
              filters: state.filters,
              onChanged: (f) => ref
                  .read(constituentListProvider.notifier)
                  .aplicarFiltros(f),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(constituentListProvider.notifier).refresh(),
                child: _buildBody(state),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_constituents',
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/home/constituents/new');
        },
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }

  Widget _buildBody(ConstituentListState state) {
    if (state.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 8,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => ShimmerSkeleton.card(height: 76),
      );
    }

    // Erro real ≠ base vazia: sem isso, falha de rede vira
    // "nenhum munícipe encontrado" e esconde o problema.
    if (state.error != null && state.items.isEmpty) {
      return AppEmptyState(
        title: 'Não foi possível carregar',
        subtitle: state.error!,
        actionLabel: 'Tentar novamente',
        onAction: () =>
            ref.read(constituentListProvider.notifier).refresh(),
      );
    }

    if (state.items.isEmpty) {
      return AppEmptyState(
        title: 'Nenhum munícipe encontrado',
        subtitle: state.searchQuery.isNotEmpty
            ? 'Tente buscar por outro nome ou telefone.'
            : 'Cadastre o primeiro munícipe tocando no botão +',
        actionLabel: 'Cadastrar munícipe',
        onAction: () => context.push('/home/constituents/new'),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.xs),
      itemBuilder: (ctx, i) {
        if (i == state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _ConstituentTile(
          constituent: state.items[i],
          index: i,
        ).animate().fadeIn(delay: Duration(milliseconds: i * 30));
      },
    );
  }
}

// ── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: SearchBar(
        controller: controller,
        hintText: 'Buscar munícipe...',
        leading: const Icon(Icons.search_rounded),
        trailing: [
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                controller.clear();
                onSearch('');
              },
            ),
        ],
        onChanged: onSearch,
        elevation: const WidgetStatePropertyAll(1),
      ),
    );
  }
}

// ── Tile com swipe ───────────────────────────────────────────────────────────

class _ConstituentTile extends StatelessWidget {
  const _ConstituentTile(
      {required this.constituent, required this.index});

  final ConstituentModel constituent;
  final int index;

  String _initials(String nome) {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return nome.isNotEmpty ? nome[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(constituent.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => false, // nunca apaga; só revela ações
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.phone_rounded, color: cs.primary),
              onPressed: () => _call(constituent.telefone ?? constituent.whatsapp),
            ),
            IconButton(
              icon: Icon(Icons.chat_rounded, color: cs.primary),
              onPressed: () => _openWhatsApp(
                  constituent.whatsapp ?? constituent.telefone),
            ),
          ],
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () {
            context.push('/home/constituents/${constituent.id}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    _initials(constituent.nome),
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        constituent.nome,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (constituent.cidade != null) constituent.cidade!,
                          if (constituent.telefone != null)
                            constituent.telefone!,
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (constituent.tags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: constituent.tags
                              .take(3)
                              .map((t) => _TagChip(label: t))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _call(String? phone) {
    if (phone == null) return;
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    launchUrl(Uri.parse('tel:+55$clean'));
  }

  void _openWhatsApp(String? phone) {
    if (phone == null) return;
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    launchUrl(
      Uri.parse('https://wa.me/55$clean'),
      mode: LaunchMode.externalApplication,
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
            ),
      ),
    );
  }
}

// ─── Barra de filtros ────────────────────────────────────────────────────────

class _FiltrosBar extends ConsumerWidget {
  const _FiltrosBar({required this.filters, required this.onChanged});

  final ConstituentFilters filters;
  final ValueChanged<ConstituentFilters> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facets = ref.watch(constituentFacetsProvider).valueOrNull;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 4),
        children: [
          // Botão de filtros (abre sheet)
          _ChipFiltro(
            icon: Icons.tune_rounded,
            label: filters.quantidadeAtivos > 0
                ? 'Filtros (${filters.quantidadeAtivos})'
                : 'Filtros',
            ativo: filters.quantidadeAtivos > 0,
            onTap: () async {
              final novo = await showModalBottomSheet<ConstituentFilters>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => _FiltrosSheet(atual: filters),
              );
              if (novo != null) onChanged(novo);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          // Envio de WhatsApp em massa (respeita filtros ativos)
          _ChipFiltro(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            ativo: false,
            onTap: () {
              final estado = ref.read(constituentListProvider);
              WhatsAppSendSheet.showBulk(
                context,
                filtros: estado.filters,
                search: estado.searchQuery.isEmpty ? null : estado.searchQuery,
                totalEstimado: estado.total > 0 ? estado.total : null,
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          // Aniversariantes de hoje (chip rápido)
          _ChipFiltro(
            icon: Icons.cake_rounded,
            label: facets != null && facets.aniversariantesHoje > 0
                ? 'Aniversariantes (${facets.aniversariantesHoje})'
                : 'Aniversariantes',
            ativo: filters.aniversariantes == 'hoje',
            onTap: () => onChanged(
              filters.aniversariantes == 'hoje'
                  ? filters.copyWith(limparAniversariantes: true)
                  : filters.copyWith(aniversariantes: 'hoje'),
            ),
          ),
          // Chips dos filtros ativos (remoção rápida)
          if (filters.cidade != null) ...[
            const SizedBox(width: AppSpacing.sm),
            _ChipFiltro(
              icon: Icons.location_city_rounded,
              label: filters.cidade!,
              ativo: true,
              onTap: () => onChanged(filters.copyWith(limparCidade: true)),
              trailing: Icons.close_rounded,
            ),
          ],
          if (filters.tag != null) ...[
            const SizedBox(width: AppSpacing.sm),
            _ChipFiltro(
              icon: Icons.sell_outlined,
              label: filters.tag!,
              ativo: true,
              onTap: () => onChanged(filters.copyWith(limparTag: true)),
              trailing: Icons.close_rounded,
            ),
          ],
          if (filters.nivelApoio != null) ...[
            const SizedBox(width: AppSpacing.sm),
            _ChipFiltro(
              icon: Icons.favorite_rounded,
              label: 'Apoio ${filters.nivelApoio}',
              ativo: true,
              onTap: () => onChanged(filters.copyWith(limparNivel: true)),
              trailing: Icons.close_rounded,
            ),
          ],
          if (filters.sort == 'nome') ...[
            const SizedBox(width: AppSpacing.sm),
            _ChipFiltro(
              icon: Icons.sort_by_alpha_rounded,
              label: 'A–Z',
              ativo: true,
              onTap: () => onChanged(filters.copyWith(sort: 'recentes')),
              trailing: Icons.close_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.icon,
    required this.label,
    required this.ativo,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool ativo;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ativo
              ? cs.primaryContainer
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ativo
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: ativo ? cs.onPrimaryContainer : cs.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ativo ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Icon(trailing,
                  size: 13,
                  color:
                      ativo ? cs.onPrimaryContainer : cs.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Sheet de filtros ────────────────────────────────────────────────────────

class _FiltrosSheet extends ConsumerStatefulWidget {
  const _FiltrosSheet({required this.atual});

  final ConstituentFilters atual;

  @override
  ConsumerState<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends ConsumerState<_FiltrosSheet> {
  late String? _cidade = widget.atual.cidade;
  late String? _tag = widget.atual.tag;
  late String? _nivel = widget.atual.nivelApoio;
  late String? _aniversariantes = widget.atual.aniversariantes;
  late String _sort = widget.atual.sort;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final facetsAsync = ref.watch(constituentFacetsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Text('Filtrar munícipes',
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pop(ConstituentFilters.vazios),
                    child: const Text('Limpar tudo'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: facetsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                            'Não foi possível carregar as opções de filtro'),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () =>
                              ref.invalidate(constituentFacetsProvider),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (facets) => ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    _tituloSecao('Ordenação'),
                    Wrap(
                      spacing: 8,
                      children: [
                        _opcao('Mais recentes', _sort == 'recentes',
                            () => setState(() => _sort = 'recentes')),
                        _opcao('Nome A–Z', _sort == 'nome',
                            () => setState(() => _sort = 'nome')),
                      ],
                    ),
                    _tituloSecao('Aniversariantes'),
                    Wrap(
                      spacing: 8,
                      children: [
                        _opcao(
                            'Hoje',
                            _aniversariantes == 'hoje',
                            () => setState(() => _aniversariantes =
                                _aniversariantes == 'hoje' ? null : 'hoje')),
                        _opcao(
                            'Do mês',
                            _aniversariantes == 'mes',
                            () => setState(() => _aniversariantes =
                                _aniversariantes == 'mes' ? null : 'mes')),
                      ],
                    ),
                    _tituloSecao('Nível de apoio'),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final n in const [
                          ('alto', 'Alto'),
                          ('medio', 'Médio'),
                          ('baixo', 'Baixo'),
                        ])
                          _opcao(
                              n.$2,
                              _nivel == n.$1,
                              () => setState(() =>
                                  _nivel = _nivel == n.$1 ? null : n.$1)),
                      ],
                    ),
                    if (facets.tags.isNotEmpty) ...[
                      _tituloSecao('Etiquetas'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in facets.tags.take(20))
                            _opcao(
                                '${t.valor} (${t.total})',
                                _tag == t.valor,
                                () => setState(() =>
                                    _tag = _tag == t.valor ? null : t.valor)),
                        ],
                      ),
                    ],
                    if (facets.cidades.isNotEmpty) ...[
                      _tituloSecao('Cidade'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in facets.cidades.take(20))
                            _opcao(
                                '${c.valor} (${c.total})',
                                _cidade == c.valor,
                                () => setState(() => _cidade =
                                    _cidade == c.valor ? null : c.valor)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(
                        ConstituentFilters(
                          cidade: _cidade,
                          tag: _tag,
                          nivelApoio: _nivel,
                          aniversariantes: _aniversariantes,
                          sort: _sort,
                        ),
                      ),
                      child: const Text('Aplicar filtros'),
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

  Widget _tituloSecao(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      );

  Widget _opcao(String label, bool selecionado, VoidCallback onTap) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selecionado,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
    );
  }
}
