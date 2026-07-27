import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../dashboard/data/models/recent_activity_model.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

/// Dashboard principal com KPI cards, atividade recente e pull-to-refresh.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final isWide = MediaQuery.sizeOf(context).width > 600;

    return RefreshIndicator(
      onRefresh: () async => ref.read(dashboardRefreshProvider)(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.lg,
              AppSpacing.screenH,
              AppSpacing.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // KPI grid
                statsAsync.when(
                  loading: () => _KpiSkeletonGrid(isWide: isWide),
                  error: (e, _) => _ErrorBanner(
                    onRetry: () => ref.refresh(dashboardStatsProvider),
                  ),
                  data: (stats) => _KpiGrid(stats: stats, isWide: isWide),
                ),

                const SizedBox(height: AppSpacing.lg),

                // KPI mensagens (full width)
                statsAsync.maybeWhen(
                  data: (stats) => KpiCard(
                    label: 'MENSAGENS',
                    value: stats.messagesSent.toString(),
                    trendDelta: '${stats.messagestoday}',
                    trendLabel: 'hoje',
                    trendPositive: stats.messagestoday > 0,
                    icon: Icons.chat_bubble_outline_rounded,
                  ).animate().fadeIn(delay: 200.ms),
                  orElse: () => ShimmerSkeleton.card(height: 110),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Seção atividade recente
                Text(
                  'ATIVIDADE RECENTE',
                  style: AppTextStyles.eyebrow(context),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: AppSpacing.sm + 2),

                statsAsync.when(
                  loading: () => _ActivitySkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (stats) => _ActivityList(
                    activities: stats.recentActivities.take(5).toList(),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- KPI grid ----

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats, required this.isWide});

  final dynamic stats;
  final bool isWide;

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      KpiCard(
        label: 'DEMANDAS',
        value: stats.totalDemands.toString(),
        trendDelta: '+${stats.openDemands}',
        trendLabel: 'abertas',
        trendPositive: true,
        icon: Icons.inbox_rounded,
      ),
      KpiCard(
        label: 'MUNÍCIPES',
        value: _fmt(stats.totalConstituents as int),
        trendDelta: '+${stats.newConstituentsToday}',
        trendLabel: 'hoje',
        trendPositive: true,
        icon: Icons.people_rounded,
      ),
      if (isWide)
        KpiCard(
          label: 'EVENTOS',
          value: stats.upcomingEvents.toString(),
          trendDelta: '${stats.eventsThisWeek}',
          trendLabel: 'esta semana',
          trendPositive: true,
          icon: Icons.calendar_month_rounded,
        ),
    ];

    return GridView.count(
      crossAxisCount: isWide ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.2,
      children: cards
          .asMap()
          .entries
          .map(
            (e) => e.value
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 + e.key * 80))
                .slideY(begin: 0.08, end: 0),
          )
          .toList(),
    );
  }
}

class _KpiSkeletonGrid extends StatelessWidget {
  const _KpiSkeletonGrid({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: isWide ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.2,
      children: List.generate(
        isWide ? 3 : 2,
        (_) => ShimmerSkeleton.card(height: 110),
      ),
    );
  }
}

// ---- Activity list ----

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.activities});

  final List<RecentActivityModel> activities;

  IconData _iconForType(String type) {
    switch (type) {
      case 'constituent_created':
        return Icons.person_add_rounded;
      case 'demand_resolved':
        return Icons.assignment_turned_in_rounded;
      case 'event_created':
        return Icons.event_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: Text('Nenhuma atividade recente')),
      );
    }

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: activities.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final a = activities[i];
            final cs = Theme.of(context).colorScheme;
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(a.type),
                  size: 16,
                  color: cs.primary,
                ),
              ),
              title: Text(
                a.displayTitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                a.displaySubtitle,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                a.timeAgo,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ).animate().fadeIn(
                  delay: Duration(milliseconds: 300 + i * 60),
                );
          },
        ),
      ),
    );
  }
}

class _ActivitySkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              ShimmerSkeleton.circle(size: 36),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerSkeleton.line(width: 160, height: 14),
                    const SizedBox(height: 6),
                    ShimmerSkeleton.line(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Error banner ----

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.dangerContainerDark
            : AppColors.dangerContainerLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: isDark ? AppColors.dangerDark : AppColors.dangerLight,
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(child: Text('Erro ao carregar estatísticas')),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
