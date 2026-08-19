import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/permissoes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/agenda_tipos.dart';
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
              // Google Calendar: status/conexão/sync manual
              const SliverToBoxAdapter(child: _GoogleCalendarCard()),

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
      // Sem `schedule:create` o botao nem aparece — oferecer e depois recusar
      // com 403 seria pior do que nao oferecer.
      floatingActionButton: SePodeVer(
        permissao: Permissoes.agendaCriar,
        child: FloatingActionButton(
          heroTag: 'fab_agenda',
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/home/agenda/new');
          },
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildEventsSliver(EventListState state) {
    final events = state.eventsForDay(_selectedDay);

    if (events.isEmpty) {
      // Quem nao pode criar nao deve ler "Toque em + para criar": o botao nao
      // existe para essa pessoa, e a frase viraria uma instrucao impossivel.
      final podeCriar = ref.watch(temPermissaoProvider(Permissoes.agendaCriar));
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: AppEmptyState(
            title: 'Sem compromissos',
            subtitle: podeCriar
                ? 'Nenhum compromisso para este dia.\nToque em + para criar.'
                : 'Nenhum compromisso para este dia.',
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tipo = agendaTipoDe(event.type);
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
                  color: tipo.cor,
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
                          // Privado e sincronizado sao informacoes que mudam o
                          // que a pessoa espera do compromisso, entao ficam no
                          // topo do card, junto do tipo.
                          if (event.privado)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.lock_outline_rounded,
                                  size: 13, color: cs.onSurfaceVariant),
                            ),
                          if (event.sincronizadoGoogle)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.event_available_rounded,
                                  size: 13, color: cs.onSurfaceVariant),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tipo.cor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                  AppRadius.full),
                            ),
                            child: Text(
                              agendaTipoRotuloCurto(event.type),
                              style: TextStyle(
                                color: tipo.cor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (event.diaTodo) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.today_rounded,
                                size: 14, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              'Dia todo',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ] else if (start != null) ...[
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

/// Card do Google Calendar no topo da Agenda: mostra o status da conexão,
/// permite conectar (OAuth no navegador) e sincronizar manualmente.
/// A sincronização em si é do servidor (bidirecional) — o app só aciona.
class _GoogleCalendarCard extends ConsumerStatefulWidget {
  const _GoogleCalendarCard();

  @override
  ConsumerState<_GoogleCalendarCard> createState() =>
      _GoogleCalendarCardState();
}

class _GoogleCalendarCardState extends ConsumerState<_GoogleCalendarCard> {
  bool _sincronizando = false;
  bool _conectando = false;

  Future<void> _conectar() async {
    setState(() => _conectando = true);
    try {
      final url =
          await ref.read(googleAgendaDatasourceProvider).authUrl();
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Conclua a autorização no navegador e volte — depois puxe para atualizar.'),
          duration: Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha ao iniciar conexão: $e')));
      }
    } finally {
      if (mounted) setState(() => _conectando = false);
    }
  }

  Future<void> _sincronizar() async {
    setState(() => _sincronizando = true);
    try {
      await ref.read(googleAgendaDatasourceProvider).sincronizar();
      ref.invalidate(googleAgendaStatusProvider);
      await ref.read(eventListProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Agenda sincronizada com o Google.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao sincronizar: $e')));
      }
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(googleAgendaStatusProvider);
    final cs = Theme.of(context).colorScheme;

    return status.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: s.conectado
                ? const Color(0xFF4285F4).withValues(alpha: 0.08)
                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: s.conectado
                  ? const Color(0xFF4285F4).withValues(alpha: 0.35)
                  : cs.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                s.conectado
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                size: 20,
                color: s.conectado
                    ? const Color(0xFF4285F4)
                    : cs.outline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.conectado
                          ? 'Google Calendar conectado'
                          : 'Google Calendar',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      s.conectado
                          ? (s.erroSync != null
                              ? 'Erro na última sync'
                              : s.ultimaSync != null
                                  ? 'Sync: ${DateFormat('dd/MM HH:mm').format(s.ultimaSync!.toLocal())}'
                                  : 'Conectado — sincronize agora')
                          : 'Veja seus compromissos do Google aqui',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: s.erroSync != null
                            ? cs.error
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (s.conectado)
                IconButton(
                  tooltip: 'Sincronizar agora',
                  onPressed: _sincronizando ? null : _sincronizar,
                  icon: _sincronizando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync_rounded,
                          size: 20, color: Color(0xFF4285F4)),
                )
              else
                TextButton(
                  onPressed: _conectando ? null : _conectar,
                  child: _conectando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Conectar',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
