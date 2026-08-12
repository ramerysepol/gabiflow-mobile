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
import '../providers/demand_provider.dart';

class DemandFormPage extends ConsumerStatefulWidget {
  const DemandFormPage({super.key, this.demandId});

  final String? demandId;

  bool get isEdit => demandId != null;

  @override
  ConsumerState<DemandFormPage> createState() => _DemandFormPageState();
}

class _DemandFormPageState extends ConsumerState<DemandFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _constituentSearchCtrl = TextEditingController();

  String _prioridade = 'medium';
  String _status = 'pending';
  DateTime? _deadline;
  ConstituentModel? _selectedConstituent;

  static const _prioridades = [
    ('low', 'Baixa'),
    ('medium', 'Média'),
    ('high', 'Alta'),
  ];

  static const _statuses = [
    ('pending', 'Pendente'),
    ('in_progress', 'Em andamento'),
    ('completed', 'Concluída'),
    ('cancelled', 'Cancelada'),
  ];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _categoriaCtrl.dispose();
    _constituentSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final body = <String, dynamic>{
      'titulo': _tituloCtrl.text.trim(),
      'status': _status,
      'prioridade': _prioridade,
      if (_descCtrl.text.isNotEmpty) 'descricao': _descCtrl.text.trim(),
      if (_selectedConstituent != null)
        'constituent_id': _selectedConstituent!.id,
      if (_deadline != null)
        'deadline': DateFormat('yyyy-MM-dd').format(_deadline!),
      if (_categoriaCtrl.text.isNotEmpty)
        'categoria': _categoriaCtrl.text.trim(),
    };

    final result = await ref
        .read(demandFormProvider.notifier)
        .save(body, widget.demandId);

    if (!mounted) return;

    if (result != null) {
      ref.invalidate(demandListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'Demanda atualizada!'
                : 'Demanda criada com sucesso!',
          ),
          backgroundColor: AppColors.successLight,
        ),
      );
      context.pop();
    } else {
      final err = ref.read(demandFormProvider).error;
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
    final formState = ref.watch(demandFormProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar Demanda' : 'Nova Demanda'),
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

              // Descrição
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Prioridade (segmented)
              Text('Prioridade',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<String>(
                segments: _prioridades
                    .map((p) => ButtonSegment(
                          value: p.$1,
                          label: Text(p.$2),
                        ))
                    .toList(),
                selected: {_prioridade},
                onSelectionChanged: (s) =>
                    setState(() => _prioridade = s.first),
              ),
              const SizedBox(height: AppSpacing.md),

              // Status
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses
                    .map((s) => DropdownMenuItem(
                          value: s.$1,
                          child: Text(s.$2),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'pending'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Munícipe (autocomplete)
              _ConstituentAutocomplete(
                controller: _constituentSearchCtrl,
                selectedConstituent: _selectedConstituent,
                onSelected: (c) =>
                    setState(() => _selectedConstituent = c),
                onClear: () => setState(() {
                  _selectedConstituent = null;
                  _constituentSearchCtrl.clear();
                }),
              ),
              const SizedBox(height: AppSpacing.md),

              // Prazo
              InkWell(
                onTap: _pickDeadline,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Prazo',
                    suffixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(
                    _deadline != null
                        ? DateFormat('dd/MM/yyyy').format(_deadline!)
                        : 'Selecionar prazo (opcional)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _deadline != null
                              ? null
                              : cs.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Categoria
              AppInputField(
                label: 'Categoria',
                controller: _categoriaCtrl,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                label: widget.isEdit ? 'Salvar alterações' : 'Criar demanda',
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

// ── Autocomplete munícipe ────────────────────────────────────────────────────

class _ConstituentAutocomplete extends ConsumerWidget {
  const _ConstituentAutocomplete({
    required this.controller,
    required this.selectedConstituent,
    required this.onSelected,
    required this.onClear,
  });

  final TextEditingController controller;
  final ConstituentModel? selectedConstituent;
  final ValueChanged<ConstituentModel> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedConstituent != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Munícipe',
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: onClear,
          ),
        ),
        child: Text(selectedConstituent!.nome),
      );
    }

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
      onSelected: onSelected,
      fieldViewBuilder: (ctx, ctrl, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: ctrl,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Munícipe',
            hintText: 'Digite o nome para buscar...',
            prefixIcon: Icon(Icons.person_search_rounded),
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
