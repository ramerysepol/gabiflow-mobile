import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../constituents/data/models/constituent_model.dart';
import '../../../constituents/presentation/providers/constituent_provider.dart';
import '../providers/event_provider.dart';

class EventFormPage extends ConsumerStatefulWidget {
  const EventFormPage({super.key, this.eventId});

  final String? eventId;

  bool get isEdit => eventId != null;

  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _participantSearchCtrl = TextEditingController();

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  String _type = 'reuniao';
  final List<ConstituentModel> _participants = [];

  static const _types = [
    ('reuniao', 'Reunião'),
    ('visita', 'Visita'),
    ('plenario', 'Plenário'),
    ('agenda_publica', 'Agenda Pública'),
    ('outro', 'Outro'),
  ];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _participantSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    setState(() {
      _startDate = d;
      _startTime = t;
    });
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    setState(() {
      _endDate = d;
      _endTime = t;
    });
  }

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null) return 'Selecionar';
    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    if (time == null) return dateStr;
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$dateStr $h:$m';
  }

  String _buildIso(DateTime? date, TimeOfDay? time) {
    if (date == null) return '';
    final h = time?.hour ?? 0;
    final m = time?.minute ?? 0;
    return DateTime(date.year, date.month, date.day, h, m).toIso8601String();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data de início')),
      );
      return;
    }
    HapticFeedback.mediumImpact();

    final body = <String, dynamic>{
      'titulo': _tituloCtrl.text.trim(),
      'start_date': _buildIso(_startDate, _startTime),
      'type': _type,
      if (_descCtrl.text.isNotEmpty) 'descricao': _descCtrl.text.trim(),
      if (_endDate != null) 'end_date': _buildIso(_endDate, _endTime),
      if (_locationCtrl.text.isNotEmpty) 'location': _locationCtrl.text.trim(),
      if (_participants.isNotEmpty)
        'participant_ids': _participants.map((p) => p.id).toList(),
    };

    final result = await ref
        .read(eventFormProvider.notifier)
        .save(body, widget.eventId);

    if (!mounted) return;

    if (result != null) {
      ref.read(eventListProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit ? 'Evento atualizado!' : 'Evento criado!',
          ),
          backgroundColor: AppColors.successLight,
        ),
      );
      context.pop();
    } else {
      final err = ref.read(eventFormProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${err ?? "Tente novamente"}'),
          backgroundColor: AppColors.dangerLight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(eventFormProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar Evento' : 'Novo Evento'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Título
              AppInputField(
                label: 'Título *',
                controller: _tituloCtrl,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Título é obrigatório' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Tipo
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: _types
                    .map((t) => DropdownMenuItem(
                          value: t.$1,
                          child: Text(t.$2),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'reuniao'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Data/hora início
              InkWell(
                onTap: _pickStart,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data e hora de início *',
                    suffixIcon: Icon(Icons.event_rounded),
                  ),
                  child: Text(
                    _formatDateTime(_startDate, _startTime),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _startDate == null
                              ? cs.onSurfaceVariant
                              : null,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Data/hora fim (opcional)
              InkWell(
                onTap: _pickEnd,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data e hora de fim (opcional)',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_endDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () =>
                                setState(() {
                                  _endDate = null;
                                  _endTime = null;
                                }),
                          ),
                        const Icon(Icons.event_rounded),
                      ],
                    ),
                  ),
                  child: Text(
                    _formatDateTime(_endDate, _endTime),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _endDate == null
                              ? cs.onSurfaceVariant
                              : null,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Local
              AppInputField(
                label: 'Local',
                controller: _locationCtrl,
                prefixIcon: const Icon(Icons.place_rounded),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),

              // Descrição
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Participantes
              Text('Participantes',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),

              _ParticipantAutocomplete(
                onSelected: (c) {
                  if (!_participants.any((p) => p.id == c.id)) {
                    setState(() => _participants.add(c));
                  }
                },
              ),

              if (_participants.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: _participants
                      .map((p) => Chip(
                            label: Text(p.nome),
                            onDeleted: () =>
                                setState(() => _participants.remove(p)),
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                label: widget.isEdit ? 'Salvar alterações' : 'Criar evento',
                isLoading: formState.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Autocomplete participante ────────────────────────────────────────────────

class _ParticipantAutocomplete extends ConsumerWidget {
  const _ParticipantAutocomplete({required this.onSelected});

  final ValueChanged<ConstituentModel> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Autocomplete<ConstituentModel>(
      displayStringForOption: (c) => c.nome,
      optionsBuilder: (textEditingValue) async {
        if (textEditingValue.text.length < 2) return const [];
        final ds = ref.read(constituentDataSourceProvider);
        try {
          final result = await ds.getConstituents(
              search: textEditingValue.text, limit: 10);
          return result.items;
        } catch (_) {
          return const [];
        }
      },
      onSelected: (c) {
        onSelected(c);
      },
      fieldViewBuilder: (ctx, ctrl, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: ctrl,
          focusNode: focusNode,
          decoration: const InputDecoration(
            hintText: 'Adicionar participante...',
            prefixIcon: Icon(Icons.person_add_rounded),
          ),
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = options.elementAt(i);
                return ListTile(
                  dense: true,
                  title: Text(c.nome),
                  subtitle: c.cidade != null ? Text(c.cidade!) : null,
                  onTap: () => onSelected(c),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
