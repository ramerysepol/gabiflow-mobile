import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/event_model.dart';
import '../providers/event_provider.dart';

class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventListProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(eventListProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              // Calendário
              SliverToBoxAdapter(
                child: state.isLoading
                    ? ShimmerSkeleton.card(height: 320)
                    : TableCalendar<EventModel>(
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2030),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (d) =>
                            isSameDay(d, _selectedDay),
                        eventLoader: (day) =>
                            state.eventsForDay(day),
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Mês'
                        },
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDay = selected;
                            _focusedDay = focused;
                          });
                        },
                        onPageChanged: (focused) {
                          _focusedDay = focused;
                          ref
                              .read(eventListProvider.notifier)
                              .fetchMonth(focused);
                        },
                        calendarStyle: CalendarStyle(
                          markerDecoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: cs.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle:
                              TextStyle(color: cs.onPrimaryContainer),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        locale: 'pt_BR',
                      ).animate().fadeIn(),
              ),

              const SliverToBoxAdapter(
                  child: Divider(height: 1)),

              // Título da lista do dia selecionado
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    _formatSelectedDay(_selectedDay),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: cs.primary),
                  ),
                ),
              ),

              // Eventos do dia
              _buildEventsSliver(state),

              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_agenda',
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/home/agenda/new');
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEventsSliver(EventListState state) {
    final events = state.eventsForDay(_selectedDay);

    if (events.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: AppEmptyState(
            title: 'Sem eventos',
            subtitle: 'Nenhum evento para este dia.\nToque em + para criar.',
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _EventTile(event: events[i])
              .animate()
              .fadeIn(delay: Duration(milliseconds: i * 50)),
          childCount: events.length,
        ),
      ),
    );
  }

  String _formatSelectedDay(DateTime d) {
    final now = DateTime.now();
    if (isSameDay(d, now)) return 'Hoje';
    if (isSameDay(d, now.add(const Duration(days: 1)))) return 'Amanhã';
    return DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(d);
  }
}

// ── Event tile ───────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final EventModel event;

  Color _typeColor(BuildContext context, String type) {
    final cs = Theme.of(context).colorScheme;
    return switch (type) {
      'reuniao' || 'reunião' => cs.primary,
      'visita' => AppColors.successLight,
      'plenario' || 'plenário' => AppColors.warningLight,
      'agenda_publica' || 'agenda pública' => AppColors.infoLight,
      _ => cs.secondary,
    };
  }

  String _typeLabel(String type) => switch (type) {
        'reuniao' || 'reunião' => 'Reunião',
        'visita' => 'Visita',
        'plenario' || 'plenário' => 'Plenário',
        'agenda_publica' => 'Ag. Pública',
        _ => 'Evento',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final start = DateTime.tryParse(event.startDate);
    final end = event.endDate != null
        ? DateTime.tryParse(event.endDate!)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push('/home/agenda/${event.id}'),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Faixa de cor do tipo
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _typeColor(context, event.type),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.card),
                    bottomLeft: Radius.circular(AppRadius.card),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.titulo,
                              style:
                                  Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _typeColor(context, event.type)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                  AppRadius.full),
                            ),
                            child: Text(
                              _typeLabel(event.type),
                              style: TextStyle(
                                color: _typeColor(context, event.type),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (start != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 14,
                                color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              end != null
                                  ? '${DateFormat('HH:mm').format(start)} – ${DateFormat('HH:mm').format(end)}'
                                  : DateFormat('HH:mm').format(start),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                      if (event.location != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.place_rounded,
                                size: 14,
                                color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: cs.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant, size: 20),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}
