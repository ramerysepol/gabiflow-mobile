import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/permissoes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../constituents/data/models/constituent_model.dart';
import '../../../constituents/presentation/providers/constituent_provider.dart';
import '../../data/models/agenda_tipos.dart';
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
  bool _diaTodo = false;
  bool _privado = false;
  final List<ConstituentModel> _participants = [];

  /// Na edicao os campos so' aparecem depois que o evento chega do servidor.
  bool _carregando = false;
  String? _erroAoCarregar;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _carregarEvento();
  }

  /// Preenche o formulario com o que esta' gravado. Sem isto a tela de edicao
  /// abria em branco e salvar apagava titulo, local e horario do compromisso.
  Future<void> _carregarEvento() async {
    setState(() {
      _carregando = true;
      _erroAoCarregar = null;
    });

    try {
      final e = await ref.read(eventDetailProvider(widget.eventId!).future);
      if (!mounted) return;

      _tituloCtrl.text = e.titulo;
      _descCtrl.text = e.descricao ?? '';
      _locationCtrl.text = e.location ?? '';

      final inicio = DateTime.tryParse(e.startDate);
      final fim = e.endDate != null ? DateTime.tryParse(e.endDate!) : null;

      setState(() {
        _type = agendaTipoDe(e.type).valor;
        _diaTodo = e.diaTodo;
        _privado = e.privado;
        if (inicio != null) {
          _startDate = inicio;
          _startTime = TimeOfDay.fromDateTime(inicio);
        }
        if (fim != null) {
          _endDate = fim;
          _endTime = TimeOfDay.fromDateTime(fim);
        }
        _participants
          ..clear()
          // Participante da agenda e' nome livre, nao um eleitor cadastrado —
          // o id aqui e' o da propria linha em agenda_participantes.
          ..addAll(e.participants.map(
            (p) => ConstituentModel(id: p.id, nome: p.nome, telefone: p.telefone),
          ));
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erroAoCarregar = 'Não foi possível carregar o compromisso';
      });
    }
  }

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
    // Fim antes do inicio passava direto e so' aparecia como evento torto na
    // agenda; o servidor tambem recusa, mas avisar aqui evita a ida e volta.
    if (_endDate != null) {
      final ini = DateTime.parse(_buildIso(_startDate, _startTime));
      final fim = DateTime.parse(_buildIso(_endDate, _endTime));
      if (fim.isBefore(ini)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O término não pode ser antes do início')),
        );
        return;
      }
    }

    HapticFeedback.mediumImpact();

    final body = <String, dynamic>{
      'titulo': _tituloCtrl.text.trim(),
      'start_date': _buildIso(_startDate, _startTime),
      'agenda_tipo': _type,
      'dia_todo': _diaTodo,
      'privado': _privado,
      if (_descCtrl.text.isNotEmpty) 'descricao': _descCtrl.text.trim(),
      if (_endDate != null) 'end_date': _buildIso(_endDate, _endTime),
      if (_locationCtrl.text.isNotEmpty) 'location': _locationCtrl.text.trim(),
      // A agenda guarda participante por nome/telefone, nao por id de eleitor.
      // Enviar `participant_ids` fazia os convidados serem descartados sem
      // aviso — nem chegavam ao banco.
      'participants': _participants
          .map((p) => {
                'nome': p.nome,
                if (p.telefone != null) 'telefone': p.telefone,
                if (p.email != null) 'email': p.email,
              })
          .toList(),
    };

    final result = await ref
        .read(eventFormProvider.notifier)
        .save(body, widget.eventId);

    if (!mounted) return;

    if (result != null) {
      ref.read(eventListProvider.notifier).refresh();
      // Sem invalidar, a tela de detalhe volta com os valores em cache.
      if (widget.isEdit) ref.invalidate(eventDetailProvider(widget.eventId!));
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

    // Chegar aqui sem permissao so' acontece por link direto ou por um item de
    // menu que ficou visivel; melhor explicar do que deixar salvar e tomar 403.
    final permissaoNecessaria =
        widget.isEdit ? Permissoes.agendaEditar : Permissoes.agendaCriar;
    if (!ref.watch(temPermissaoProvider(permissaoNecessaria))) {
      return const SemPermissao(titulo: 'Compromisso');
    }

    if (_carregando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Compromisso')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_erroAoCarregar != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Compromisso')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: cs.error),
              const SizedBox(height: AppSpacing.sm),
              Text(_erroAoCarregar!),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _carregarEvento,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Editar Compromisso' : 'Novo Compromisso',
        ),
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

              // Tipo — mesma lista e mesmas cores do painel (agendaTipos).
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: agendaTipos
                    .map((t) => DropdownMenuItem(
                          value: t.valor,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: t.cor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  t.rotulo,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'outro'),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Dia todo e privado — colunas que o painel ja' usa e o app
              // ignorava por completo.
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _diaTodo,
                onChanged: (v) => setState(() => _diaTodo = v),
                title: const Text('Dia todo'),
                subtitle: const Text('Ocupa o dia inteiro, sem horário'),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _privado,
                onChanged: (v) => setState(() => _privado = v),
                title: const Text('Privado'),
                subtitle: const Text('Não aparece na agenda pública'),
              ),
              const SizedBox(height: AppSpacing.sm),

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
