import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissoes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/gradient_action_card.dart';
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

                const SizedBox(height: AppSpacing.sm),

                // Painel de atendimentos (full width, gradiente)
                statsAsync.maybeWhen(
                  data: (stats) => _AtendimentosCard(
                    recebidos: stats.atendimentosRecebidosHoje,
                    atendidos: stats.atendimentosAtendidosHoje,
                    aguardando: stats.atendimentosAguardando,
                    arquivados: stats.atendimentosArquivadosHoje,
                  ).animate().fadeIn(delay: 200.ms),
                  orElse: () => ShimmerSkeleton.card(height: 110),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Acesso rápido — a energia da Central Eleitoral no Início
                Text(
                  'ACESSO RÁPIDO',
                  style: AppTextStyles.eyebrow(context),
                ).animate().fadeIn(delay: 220.ms),

                const SizedBox(height: AppSpacing.sm + 2),

                const _AcessoRapidoGrid()
                    .animate()
                    .fadeIn(delay: 260.ms)
                    .slideY(begin: 0.06, end: 0),

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

// ---- Acesso rápido ----

class _AcessoRapidoGrid extends ConsumerWidget {
  const _AcessoRapidoGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temCentral =
        ref.watch(temPermissaoProvider(Permissoes.whatsappCentral));
    final temEleitoral =
        ref.watch(temPermissaoProvider(Permissoes.eleitoralVer));
    final temMunicipes =
        ref.watch(temPermissaoProvider(Permissoes.eleitoresListar));
    final temDemandas =
        ref.watch(temPermissaoProvider(Permissoes.demandasCriar));
    final temAgenda = ref.watch(temPermissaoProvider(Permissoes.agendaVer));

    final cards = <Widget>[
      if (temCentral)
        GradientActionCard(
          titulo: 'Atendimento',
          subtitulo: 'Converse com munícipes no WhatsApp',
          icone: Icons.chat_rounded,
          cores: const [Color(0xFF128C7E), Color(0xFF25D366)],
          onTap: () => context.go('/home/atendimento'),
        ),
      if (temEleitoral)
        GradientActionCard(
          titulo: 'Central Eleitoral',
          subtitulo: 'Mapa de calor, rankings e IA',
          icone: Icons.local_fire_department_rounded,
          cores: const [Color(0xFF16213E), Color(0xFF3949AB)],
          onTap: () => context.go('/home/eleitoral'),
        ),
      if (temMunicipes)
        GradientActionCard(
          titulo: 'Novo Munícipe',
          subtitulo: 'Cadastre um contato agora',
          icone: Icons.person_add_rounded,
          cores: const [Color(0xFF1976D2), Color(0xFF42A5F5)],
          onTap: () => context.push('/home/constituents/new'),
        ),
      if (temDemandas)
        GradientActionCard(
          titulo: 'Nova Demanda',
          subtitulo: 'Registre uma solicitação',
          icone: Icons.post_add_rounded,
          cores: const [Color(0xFFEF6C00), Color(0xFFFFA726)],
          onTap: () => context.push('/home/demands/new'),
        ),
      if (temAgenda)
        GradientActionCard(
          titulo: 'Agenda',
          subtitulo: 'Compromissos e eventos',
          icone: Icons.calendar_month_rounded,
          cores: const [Color(0xFF00897B), Color(0xFF26A69A)],
          onTap: () => context.go('/home/agenda'),
        ),
    ];

    if (cards.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.5,
      children: cards,
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
      _StatCard(
        label: 'Demandas',
        value: stats.totalDemands.toString(),
        detalhe: '+${stats.openDemands} abertas',
        icone: Icons.inbox_rounded,
        cor: const Color(0xFFEF6C00),
      ),
      _StatCard(
        label: 'Munícipes',
        value: _fmt(stats.totalConstituents as int),
        detalhe: '+${stats.newConstituentsToday} hoje',
        icone: Icons.people_rounded,
        cor: const Color(0xFF1976D2),
      ),
      if (isWide)
        _StatCard(
          label: 'Eventos',
          value: stats.upcomingEvents.toString(),
          detalhe: '${stats.eventsThisWeek} esta semana',
          icone: Icons.calendar_month_rounded,
          cor: const Color(0xFF00897B),
        ),
    ];

    return GridView.count(
      crossAxisCount: isWide ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.55,
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

/// Cartão de estatística no padrão novo: pastilha de ícone colorida,
/// número em destaque e detalhe curto.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.detalhe,
    required this.icone,
    required this.cor,
  });

  final String label;
  final String value;
  final String detalhe;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icone, size: 16, color: cor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detalhe,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: cor,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Painel de atendimentos do dia: recebidos, atendidos, aguardando e
/// arquivados — direto da central. Toca → abre a central.
class _AtendimentosCard extends StatelessWidget {
  const _AtendimentosCard({
    required this.recebidos,
    required this.atendidos,
    required this.aguardando,
    required this.arquivados,
  });

  final int recebidos;
  final int atendidos;
  final int aguardando;
  final int arquivados;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/home/atendimento'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF16213E), Color(0xFF128C7E)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.support_agent_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Atendimentos hoje',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.7), size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniStat(valor: recebidos, rotulo: 'Recebidos'),
                  _divisor(),
                  _MiniStat(valor: atendidos, rotulo: 'Atendidos'),
                  _divisor(),
                  _MiniStat(
                    valor: aguardando,
                    rotulo: 'Aguardando',
                    destaque: aguardando > 0,
                  ),
                  _divisor(),
                  _MiniStat(valor: arquivados, rotulo: 'Arquivados'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divisor() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.15),
      );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.valor,
    required this.rotulo,
    this.destaque = false,
  });

  final int valor;
  final String rotulo;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final cor = destaque ? const Color(0xFFFFD54F) : Colors.white;
    return Expanded(
      child: Column(
        children: [
          Text(
            '$valor',
            style: TextStyle(
              color: cor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: (destaque ? cor : Colors.white)
                  .withValues(alpha: destaque ? 0.95 : 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
