import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/permissoes.dart';
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

  /// Excluir pede confirmacao: no celular o toque errado e' facil, e a demanda
  /// carrega notas, anexos e historico. A exclusao e' logica no servidor, mas o
  /// usuario nao tem como desfazer pelo app — entao a pergunta e' obrigatoria.
  Future<void> _confirmarExclusao(String titulo) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir demanda'),
        content: Text(
          '"$titulo" sairá da lista, junto com suas notas e anexos.\n\n'
          'Só é possível recuperar pelo painel web.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;
    HapticFeedback.mediumImpact();

    final ok = await ref.read(demandFormProvider.notifier).delete(widget.id);
    if (!mounted) return;

    if (ok) {
      ref.read(demandListProvider.notifier).refresh();
      context.pop(); // volta para a lista — a demanda nao existe mais aqui
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demanda excluída')),
      );
    } else {
      final erro = ref.read(demandFormProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro ?? 'Falha ao excluir')),
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
                data: (d) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SePodeVer(
                      permissao: Permissoes.demandasEditar,
                      child: IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: 'Editar',
                        onPressed: () =>
                            context.push('/home/demands/new?id=${widget.id}'),
                      ),
                    ),
                    SePodeVer(
                      permissao: Permissoes.demandasExcluir,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        tooltip: 'Excluir',
                        onPressed: () => _confirmarExclusao(d.titulo),
                      ),
                    ),
                  ],
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
              const Text('Erro ao carregar demanda'),
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

              // Responsável
              if (demand.responsavelNome != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: cs.secondaryContainer,
                    child: Icon(Icons.assignment_ind_rounded,
                        color: cs.secondary),
                  ),
                  title: Text('Responsável',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          )),
                  subtitle: Text(demand.responsavelNome!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ).animate().fadeIn(delay: 130.ms),

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

              // Anexos
              const SizedBox(height: AppSpacing.lg),
              _AnexosSection(demandId: demand.id),

              const SizedBox(height: AppSpacing.xxl),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Anexos da demanda: lista o que ja foi enviado e permite tirar foto ou
/// escolher da galeria.
///
/// No celular a camera e' o registro natural de campo — quem atende esta na
/// rua e fotografa o problema na hora. Por isso a camera vem primeiro na folha
/// de opcoes, e nao a galeria.
class _AnexosSection extends ConsumerWidget {
  const _AnexosSection({required this.demandId});

  final String demandId;

  Future<void> _escolher(BuildContext context, WidgetRef ref) async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (origem == null) return;

    // Comprimir na origem: foto de celular passa de 10 MB com facilidade, e o
    // servidor recusa acima disso. 1600px e 80% mantem legivel um documento
    // fotografado sem estourar o limite nem a franquia de dados de quem esta
    // em campo.
    final XFile? foto = await ImagePicker().pickImage(
      source: origem,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (foto == null || !context.mounted) return;

    final ok = await ref
        .read(attachmentUploadProvider.notifier)
        .upload(demandId, foto.path);

    if (!context.mounted) return;

    if (ok) {
      ref.invalidate(demandAttachmentsProvider(demandId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anexo enviado')),
      );
    } else {
      final erro = ref.read(attachmentUploadProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro ?? 'Falha ao enviar anexo')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final anexos = ref.watch(demandAttachmentsProvider(demandId));
    final enviando = ref.watch(attachmentUploadProvider).isUploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Anexos',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: cs.primary)),
            if (enviando)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.add_a_photo_rounded),
                tooltip: 'Adicionar anexo',
                onPressed: () => _escolher(context, ref),
              ),
          ],
        ),
        anexos.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Row(
            children: [
              Expanded(
                child: Text('Não foi possível carregar os anexos',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.error)),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(demandAttachmentsProvider(demandId)),
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
          data: (lista) {
            if (lista.isEmpty) {
              return Text('Nenhum anexo',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant));
            }
            return Column(
              children: lista
                  .map((a) => Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: Icon(
                            a.isImage
                                ? Icons.image_rounded
                                : Icons.picture_as_pdf_rounded,
                            color: cs.primary,
                          ),
                          title: Text(
                            a.filename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            [
                              if (a.tamanhoLegivel.isNotEmpty) a.tamanhoLegivel,
                              if (a.createdAt != null)
                                DateFormat('dd/MM HH:mm').format(a.createdAt!),
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
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
