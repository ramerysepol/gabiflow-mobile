import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/acao_social_models.dart';
import '../providers/acao_social_providers.dart';
import '../widgets/acao_social_widgets.dart';

/// Lista de eventos (mutiroes) da Acao Social. Toque abre a central do
/// evento (cadastrados, vagas, atendimentos).
class AcaoSocialEventosPage extends ConsumerWidget {
  const AcaoSocialEventosPage({super.key});

  static const _filtros = [
    ('ativo', 'Ativos'),
    ('finalizado', 'Finalizados'),
    ('todos', 'Todos'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventosAcaoSocialProvider);
    final notifier = ref.read(eventosAcaoSocialProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ação Social'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: notifier.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    for (final f in _filtros)
                      ButtonSegment(value: f.$1, label: Text(f.$2)),
                  ],
                  selected: {state.filtro},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => notifier.setFiltro(s.first),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: notifier.refresh,
                child: _corpo(context, state, notifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corpo(
      BuildContext context, EventosState state, EventosNotifier notifier) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => ShimmerSkeleton.card(height: 118),
      );
    }
    if (state.error != null && state.items.isEmpty) {
      return ListView(children: [
        AppEmptyState(
          title: 'Não foi possível carregar',
          subtitle: state.error!,
          actionLabel: 'Tentar novamente',
          onAction: notifier.refresh,
        ),
      ]);
    }
    if (state.items.isEmpty) {
      return ListView(children: [
        AppEmptyState(
          title: state.filtro == 'ativo'
              ? 'Nenhum evento ativo'
              : 'Nenhum evento encontrado',
          subtitle: 'Os eventos são criados nas configurações do painel web.',
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _EventoCard(evento: state.items[i])
          .animate()
          .fadeIn(delay: Duration(milliseconds: i * 30)),
    );
  }
}

class _EventoCard extends StatelessWidget {
  const _EventoCard({required this.evento});

  final EventoAcaoSocial evento;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final faixa = corStatusEvento(evento.status);
    final progresso = evento.totalVagas > 0
        ? (evento.totalUtilizadas / evento.totalVagas).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/home/acao-social/evento/${evento.id}'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: faixa),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              evento.nome,
                              style: tt.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusChip(
                            rotulo: rotuloStatusEvento(evento.status),
                            cor: faixa,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.event_rounded,
                              size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(formatarData(evento.dataEvento),
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                          if (evento.localEvento != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.place_rounded,
                                size: 14, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                evento.localEvento!,
                                style: tt.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              child: LinearProgressIndicator(
                                value: progresso,
                                minHeight: 6,
                                backgroundColor:
                                    cs.surfaceContainerHighest,
                                color: corNivelVagas(evento.nivel, cs),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SlotStatusBadge(
                            total: evento.totalVagas,
                            utilizadas: evento.totalUtilizadas,
                            compacto: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${evento.totalEspecialidades} '
                        '${evento.totalEspecialidades == 1 ? 'especialidade' : 'especialidades'}'
                        ' · tag ${evento.tag}',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
