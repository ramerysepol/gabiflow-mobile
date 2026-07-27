import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/demand_model.dart';
import '../providers/demand_provider.dart';
import '../widgets/demand_widgets.dart';

class DemandDetailPage extends ConsumerStatefulWidget {
  const DemandDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<DemandDetailPage> createState() => _DemandDetailPageState();
}

class _DemandDetailPageState extends ConsumerState<DemandDetailPage> {
  final _noteController = TextEditingController();
  bool _addingNote = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final content = _noteController.text.trim();
    if (content.isEmpty) return;
    HapticFeedback.mediumImpact();

    final ok = await ref
        .read(demandFormProvider.notifier)
        .addNote(widget.id, content);

    if (!mounted) return;
    if (ok) {
      _noteController.clear();
      setState(() => _addingNote = false);
      ref.invalidate(demandDetailProvider(widget.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota adicionada!')),
      );
    }
  }

  Future<void> _changeStatus(String currentStatus) async {
    final statuses = [
      ('pending', 'Pendente'),
      ('in_progress', 'Em andamento'),
      ('completed', 'Concluída'),
      ('cancelled', 'Cancelada'),
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Mudar status',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...statuses.map(
              (s) => ListTile(
                title: Text(s.$2),
                leading: currentStatus == s.$1
                    ? const Icon(Icons.check_circle_rounded)
                    : const Icon(Icons.radio_button_unchecked_rounded),
                onTap: () => Navigator.of(ctx).pop(s.$1),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (selected == null || selected == currentStatus) return;
    HapticFeedback.mediumImpact();

    final ok = await ref
        .read(demandFormProvider.notifier)
        .updateStatus(widget.id, selected);

    if (!mounted) return;
    if (ok) {
      ref.invalidate(demandDetailProvider(widget.id));
      ref.read(demandListProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status atualizado!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(demandDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demanda'),
        actions: [
          asyncData.whenOrNull(
                data: (d) => IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () =>
                      context.push('/home/demands/new?id=${widget.id}'),
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
              Text('Erro ao carregar demanda'),
              TextButton(
                onPressed: () =>
                    ref.refresh(demandDetailProvider(widget.id)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (demand) => _DemandContent(
          demand: demand,
          onChangeStatus: () => _changeStatus(demand.status),
          addingNote: _addingNote,
          noteController: _noteController,
          onToggleNote: () => setState(() => _addingNote = !_addingNote),
          onSubmitNote: _addNote,
        ),
      ),
    );
  }
}

class _DemandContent extends ConsumerWidget {
  const _DemandContent({
    required this.demand,
    required this.onChangeStatus,
    required this.addingNote,
    required this.noteController,
    required this.onToggleNote,
    required this.onSubmitNote,
  });

  final DemandModel demand;
  final VoidCallback onChangeStatus;
  final bool addingNote;
  final TextEditingController noteController;
  final VoidCallback onToggleNote;
  final VoidCallback onSubmitNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final deadline = demand.deadline != null
        ? DateTime.tryParse(demand.deadline!)
        : null;
    final isOverdue =
        deadline != null && deadline.isBefore(DateTime.now());

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Título
              Text(demand.titulo,
                      style: Theme.of(context).textTheme.headlineSmall)
                  .animate()
                  .fadeIn(),

              const SizedBox(height: AppSpacing.sm),

              // Status + Prioridade
              Row(
                children: [
                  DemandStatusChip(status: demand.status),
                  const SizedBox(width: AppSpacing.sm),
                  DemandPriorityBadge(priority: demand.prioridade),
                ],
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: AppSpacing.md),

              // Munícipe
              if (demand.constituentNome != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.person_rounded, color: cs.primary),
                  ),
                  title: Text('Munícipe',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          )),
                  subtitle: Text(demand.constituentNome!,
                      style: Theme.of(context).textTheme.bodyMedium),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: demand.constituentId != null
                      ? () => context.push(
                          '/home/constituents/${demand.constituentId}')
                      : null,
                ).animate().fadeIn(delay: 120.ms),

              // Prazo
              if (deadline != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isOverdue
                        ? AppColors.dangerContainerLight
                        : cs.tertiaryContainer,
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: isOverdue
                          ? AppColors.dangerLight
                          : cs.tertiary,
                    ),
                  ),
                  title: Text('Prazo',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          )),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(deadline),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isOverdue ? AppColors.dangerLight : null,
                          fontWeight:
                              isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ).animate().fadeIn(delay: 140.ms),

              // Descrição
              if (demand.descricao != null &&
                  demand.descricao!.isNotEmpty) ...[
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
                    child: Text(demand.descricao!,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Mudar status
              OutlinedButton.icon(
                onPressed: onChangeStatus,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Mudar status'),
              ).animate().fadeIn(delay: 200.ms),

              // Timeline de atividades
              if (demand.activities.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Histórico',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: cs.primary)),
                const SizedBox(height: AppSpacing.sm),
                ...demand.activities.asMap().entries.map(
                      (e) => _ActivityItem(
                        activity: e.value,
                        isLast: e.key == demand.activities.length - 1,
                      ),
                    ),
              ],

              // Notas
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notas',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: cs.primary)),
                  IconButton(
                    icon: Icon(
                        addingNote ? Icons.close_rounded : Icons.add_rounded),
                    onPressed: onToggleNote,
                  ),
                ],
              ),

              if (addingNote) ...[
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Escreva uma nota...',
                    filled: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: 'Salvar nota',
                  onPressed: onSubmitNote,
                  fullWidth: false,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (demand.notes.isEmpty && !addingNote)
                Text('Nenhuma nota',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),

              ...demand.notes.map(
                (n) => Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    title: Text(n.content,
                        style: Theme.of(context).textTheme.bodyMedium),
                    subtitle: Text(
                      [
                        if (n.userName != null) n.userName!,
                        if (n.createdAt != null)
                          DateFormat('dd/MM HH:mm').format(
                              DateTime.tryParse(n.createdAt!) ??
                                  DateTime.now()),
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.activity, required this.isLast});

  final DemandActivityModel activity;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: cs.outlineVariant),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.description,
                      style: Theme.of(context).textTheme.bodyMedium),
                  if (activity.createdAt != null)
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(
                          DateTime.tryParse(activity.createdAt!) ??
                              DateTime.now()),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
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

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerSkeleton.line(width: 240, height: 28),
          const SizedBox(height: AppSpacing.sm),
          ShimmerSkeleton.line(width: 120, height: 20),
          const SizedBox(height: AppSpacing.lg),
          ShimmerSkeleton.card(height: 80),
          const SizedBox(height: AppSpacing.md),
          ShimmerSkeleton.card(height: 120),
        ],
      ),
    );
  }
}
