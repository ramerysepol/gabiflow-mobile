import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../providers/event_provider.dart';

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(eventDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evento'),
        actions: [
          asyncData.whenOrNull(
                data: (e) => IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/home/agenda/new?id=$id');
                  },
                ),
              ) ??
              const SizedBox.shrink(),
          asyncData.whenOrNull(
                data: (_) => IconButton(
                  icon: Icon(Icons.delete_rounded,
                      color: Theme.of(context).colorScheme.error),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: asyncData.when(
        loading: () => _LoadingSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: AppSpacing.md),
              const Text('Erro ao carregar evento'),
              TextButton(
                onPressed: () => ref.refresh(eventDetailProvider(id)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (event) {
          final cs = Theme.of(context).colorScheme;
          final start = DateTime.tryParse(event.startDate);
          final end =
              event.endDate != null ? DateTime.tryParse(event.endDate!) : null;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Título
                    Text(event.titulo,
                            style:
                                Theme.of(context).textTheme.headlineSmall)
                        .animate()
                        .fadeIn(),

                    const SizedBox(height: AppSpacing.md),

                    // Cartão de data/hora
                    Card(
                      color: cs.primaryContainer,
                      child: ListTile(
                        leading: Icon(Icons.calendar_month_rounded,
                            color: cs.primary, size: 32),
                        title: Text(
                          start != null
                              ? DateFormat(
                                      "EEEE, d 'de' MMMM 'de' yyyy",
                                      'pt_BR')
                                  .format(start)
                              : event.startDate,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: cs.onPrimaryContainer),
                        ),
                        subtitle: Text(
                          end != null && start != null
                              ? '${DateFormat('HH:mm').format(start)} – ${DateFormat('HH:mm').format(end)}'
                              : start != null
                                  ? DateFormat('HH:mm').format(start)
                                  : '',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: cs.onPrimaryContainer
                                      .withValues(alpha: 0.7)),
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    // Local
                    if (event.location != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.place_rounded,
                              color: cs.primary),
                          title: Text(event.location!,
                              style:
                                  Theme.of(context).textTheme.bodyMedium),
                          subtitle: const Text('Abrir no mapa'),
                          trailing: const Icon(Icons.open_in_new_rounded),
                          onTap: () {
                            final encoded = Uri.encodeComponent(
                                event.location!);
                            launchUrl(
                              Uri.parse(
                                  'https://maps.google.com?q=$encoded'),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                      ).animate().fadeIn(delay: 140.ms),
                    ],

                    // Tipo
                    const SizedBox(height: AppSpacing.sm),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.label_rounded,
                            color: cs.primary),
                        title: const Text('Tipo'),
                        subtitle: Text(_typeLabel(event.type)),
                      ),
                    ).animate().fadeIn(delay: 160.ms),

                    // Descrição
                    if (event.descricao != null &&
                        event.descricao!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text('Descrição',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: cs.primary)),
                      const SizedBox(height: AppSpacing.xs),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(event.descricao!,
                              style:
                                  Theme.of(context).textTheme.bodyMedium),
                        ),
                      ),
                    ],

                    // Participantes
                    if (event.participants.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text('Participantes (${event.participants.length})',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: cs.primary)),
                      const SizedBox(height: AppSpacing.sm),
                      Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: event.participants.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final p = event.participants[i];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: cs.primaryContainer,
                                child: Text(
                                  p.nome.isNotEmpty
                                      ? p.nome[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(p.nome),
                              subtitle: p.telefone != null
                                  ? Text(p.telefone!)
                                  : null,
                              onTap: () => context
                                  .push('/home/constituents/${p.id}'),
                            );
                          },
                        ),
                      ),
                    ] else if (event.participantCount > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text('${event.participantCount} participante(s)',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],

                    const SizedBox(height: AppSpacing.xxl),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        'reuniao' || 'reunião' => 'Reunião',
        'visita' => 'Visita',
        'plenario' || 'plenário' => 'Plenário',
        'agenda_publica' => 'Agenda Pública',
        _ => 'Outro',
      };

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir evento'),
        content:
            const Text('Tem certeza que deseja excluir este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Excluir',
                style: TextStyle(
                    color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    HapticFeedback.heavyImpact();
    final ok = await ref.read(eventFormProvider.notifier).delete(id);

    if (!context.mounted) return;
    if (ok) {
      ref.read(eventListProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento excluído!')),
      );
      context.pop();
    }
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerSkeleton.line(width: 240, height: 28),
          const SizedBox(height: AppSpacing.md),
          ShimmerSkeleton.card(height: 80),
          const SizedBox(height: AppSpacing.sm),
          ShimmerSkeleton.card(height: 60),
          const SizedBox(height: AppSpacing.sm),
          ShimmerSkeleton.card(height: 120),
        ],
      ),
    );
  }
}
