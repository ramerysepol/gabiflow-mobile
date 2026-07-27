import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/demand_model.dart';
import '../providers/demand_provider.dart';
import '../widgets/demand_widgets.dart';

class DemandsListPage extends ConsumerStatefulWidget {
  const DemandsListPage({super.key});

  @override
  ConsumerState<DemandsListPage> createState() => _DemandsListPageState();
}

class _DemandsListPageState extends ConsumerState<DemandsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  static const _tabs = [
    ('all', 'Todas'),
    ('pending', 'Pendentes'),
    ('in_progress', 'Em andamento'),
    ('completed', 'Concluídas'),
    ('cancelled', 'Canceladas'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _scrollController.addListener(_onScroll);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final status = _tabs[_tabController.index].$1;
      ref.read(demandListProvider.notifier).filterByStatus(status);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(demandListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(demandListProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // TabBar com contadores
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: _tabs.map((t) {
                final count = _countForStatus(t.$1, state.statusCounts);
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.$2),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(demandListProvider.notifier).refresh(),
                child: _buildBody(state),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_demands',
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/home/demands/new');
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  int _countForStatus(String status, DemandStatusCounts? counts) {
    if (counts == null) return 0;
    switch (status) {
      case 'pending':
        return counts.pending;
      case 'in_progress':
        return counts.inProgress;
      case 'completed':
        return counts.completed;
      case 'cancelled':
        return counts.cancelled;
      default:
        return counts.pending + counts.inProgress;
    }
  }

  Widget _buildBody(DemandListState state) {
    if (state.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 6,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => ShimmerSkeleton.card(height: 88),
      );
    }

    if (state.items.isEmpty) {
      return AppEmptyState(
        title: 'Nenhuma demanda',
        subtitle: 'Registre uma nova demanda tocando no botão +',
        actionLabel: 'Nova demanda',
        onAction: () => context.push('/home/demands/new'),
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
        return _DemandCard(demand: state.items[i])
            .animate()
            .fadeIn(delay: Duration(milliseconds: i * 30));
      },
    );
  }
}

// ── Demand Card ──────────────────────────────────────────────────────────────

class _DemandCard extends StatelessWidget {
  const _DemandCard({required this.demand});

  final DemandModel demand;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final deadline = demand.deadline != null
        ? DateTime.tryParse(demand.deadline!)
        : null;
    final isOverdue =
        deadline != null && deadline.isBefore(DateTime.now());

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push('/home/demands/${demand.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      demand.titulo,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  DemandPriorityBadge(priority: demand.prioridade),
                ],
              ),
              const SizedBox(height: 4),
              if (demand.constituentNome != null)
                Text(
                  demand.constituentNome!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  DemandStatusChip(status: demand.status),
                  if (deadline != null) ...[
                    const Spacer(),
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: isOverdue
                          ? AppColors.dangerLight
                          : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yy').format(deadline),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isOverdue
                                ? AppColors.dangerLight
                                : cs.onSurfaceVariant,
                            fontWeight: isOverdue
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

