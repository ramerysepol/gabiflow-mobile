import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/constituent_model.dart';
import '../providers/constituent_provider.dart';

/// Formulário de munícipe (criar/editar).
///
/// Em modo edição, se o model não vier por parâmetro, os dados são buscados
/// pelo id — o formulário NUNCA abre em branco ao editar.
class ConstituentFormPage extends ConsumerWidget {
  const ConstituentFormPage({
    super.key,
    this.constituentId,
    this.existing,
  });

  final String? constituentId;
  final ConstituentModel? existing;

  bool get isEdit => constituentId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Criação, ou edição com dados já em mãos → direto pro form
    if (!isEdit || existing != null) {
      return _FormScaffold(existing: existing, constituentId: constituentId);
    }

    // Edição sem dados → busca pelo id antes de montar o form
    final async = ref.watch(constituentDetailProvider(constituentId!));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Editar Munícipe')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Editar Munícipe')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 36, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                const Text('Não foi possível carregar os dados do munícipe'),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.invalidate(constituentDetailProvider(constituentId!)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (model) =>
          _FormScaffold(existing: model, constituentId: constituentId),
    );
  }
}

class _FormScaffold extends ConsumerStatefulWidget {
  const _FormScaffold({required this.existing, required this.constituentId});

  final ConstituentModel? existing;
  final String? constituentId;

  bool get isEdit => constituentId != null;

  @override
  ConsumerState<_FormScaffold> createState() => _FormScaffoldState();
}

class _FormScaffoldState extends ConsumerState<_FormScaffold> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _cpfCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _enderecoCtrl;
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _complementoCtrl;
  late final TextEditingController _bairroCtrl;
  late final TextEditingController _cidadeCtrl;
  late final TextEditingController _cepCtrl;
  late final TextEditingController _profissaoCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _tagInputCtrl;

  String? _estado;
  String? _genero;
  String? _nivelApoio;
  DateTime? _dataNascimento;
  bool _voluntario = false;
  List<String> _tags = [];

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  static const _ufs = [
    'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS',
    'MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC',
    'SP','SE','TO',
  ];

  static const _generos = ['Masculino', 'Feminino', 'Outro'];
  static const _niveisApoio = [
    ('alto', 'Alto'),
    ('medio', 'Médio'),
    ('baixo', 'Baixo'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nomeCtrl = TextEditingController(text: e?.nome ?? '');
    _cpfCtrl = TextEditingController(
        text: e?.cpf != null ? _cpfMask.maskText(e!.cpf!) : '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _telefoneCtrl = TextEditingController(
        text: e?.telefone != null ? _phoneMask.maskText(e!.telefone!) : '');
    _enderecoCtrl = TextEditingController(text: e?.endereco ?? '');
    _numeroCtrl = TextEditingController(text: e?.numero ?? '');
    _complementoCtrl = TextEditingController(text: e?.complemento ?? '');
    _bairroCtrl = TextEditingController(text: e?.bairro ?? '');
    _cidadeCtrl = TextEditingController(text: e?.cidade ?? '');
    _cepCtrl = TextEditingController(
        text: e?.cep != null ? _cepMask.maskText(e!.cep!) : '');
    _profissaoCtrl = TextEditingController(text: e?.profissao ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _tagInputCtrl = TextEditingController();
    _estado = _ufs.contains(e?.estado) ? e?.estado : null;
    _genero = _generos.contains(e?.genero) ? e?.genero : null;
    _nivelApoio =
        _niveisApoio.any((n) => n.$1 == e?.nivelApoio) ? e?.nivelApoio : null;
    _voluntario = e?.voluntario ?? false;
    _tags = List.from(e?.tags ?? []);
    if (e?.dataNascimento != null && e!.dataNascimento!.isNotEmpty) {
      _dataNascimento = DateTime.tryParse(e.dataNascimento!.split('T').first);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nomeCtrl, _cpfCtrl, _emailCtrl, _telefoneCtrl,
      _enderecoCtrl, _numeroCtrl, _complementoCtrl, _bairroCtrl,
      _cidadeCtrl, _cepCtrl, _profissaoCtrl, _notesCtrl, _tagInputCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Validações ────────────────────────────────────────────────────────────

  String? _validarEmail(String? v) {
    if (v == null || v.trim().isEmpty) return null; // opcional
    final ok = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(v.trim());
    return ok ? null : 'E-mail inválido';
  }

  String? _validarCpf(String? v) {
    if (v == null || v.trim().isEmpty) return null; // opcional
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return 'CPF incompleto';
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return 'CPF inválido';
    // Dígitos verificadores
    int calc(int len) {
      var soma = 0;
      for (var i = 0; i < len; i++) {
        soma += int.parse(digits[i]) * (len + 1 - i);
      }
      final resto = (soma * 10) % 11;
      return resto == 10 ? 0 : resto;
    }

    if (calc(9) != int.parse(digits[9]) || calc(10) != int.parse(digits[10])) {
      return 'CPF inválido';
    }
    return null;
  }

  String? _validarTelefone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // opcional
    final digits = v.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? null : 'Telefone incompleto';
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    String limpo(TextEditingController c) => c.text.trim();

    final body = <String, dynamic>{
      'nome': limpo(_nomeCtrl),
      'cpf': _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
      'email': limpo(_emailCtrl),
      'telefone': _telefoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
      'endereco': limpo(_enderecoCtrl),
      'numero': limpo(_numeroCtrl),
      'complemento': limpo(_complementoCtrl),
      'bairro': limpo(_bairroCtrl),
      'cidade': limpo(_cidadeCtrl),
      'estado': _estado ?? '',
      'cep': _cepCtrl.text.replaceAll(RegExp(r'\D'), ''),
      'genero': _genero ?? '',
      'profissao': limpo(_profissaoCtrl),
      'nivel_apoio': _nivelApoio ?? '',
      'voluntario': _voluntario,
      'tags': _tags,
      'observacoes': limpo(_notesCtrl),
      if (_dataNascimento != null)
        'data_nascimento':
            _dataNascimento!.toIso8601String().split('T').first,
    };

    final result = await ref
        .read(constituentFormProvider.notifier)
        .save(body, widget.constituentId);

    if (!mounted) return;

    if (result != null) {
      ref.invalidate(constituentListProvider);
      if (widget.constituentId != null) {
        ref.invalidate(constituentDetailProvider(widget.constituentId!));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'Munícipe atualizado com sucesso!'
                : 'Munícipe cadastrado com sucesso!',
          ),
          backgroundColor: AppColors.successLight,
        ),
      );
      context.pop();
    } else {
      final err = ref.read(constituentFormProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Não foi possível salvar. Tente novamente.'),
          backgroundColor: AppColors.dangerLight,
        ),
      );
    }
  }

  void _addTag(String tag) {
    final t = tag.trim();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() {
        _tags.add(t);
        _tagInputCtrl.clear();
      });
    }
  }

  Future<void> _escolherNascimento() async {
    final hoje = DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(hoje.year - 30),
      firstDate: DateTime(1900),
      lastDate: hoje,
      locale: const Locale('pt', 'BR'),
      helpText: 'Data de nascimento',
    );
    if (selecionada != null) {
      setState(() => _dataNascimento = selecionada);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(constituentFormProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar Munícipe' : 'Novo Munícipe'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _secao(context, 'Dados pessoais'),
              AppInputField(
                label: 'Nome completo *',
                controller: _nomeCtrl,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nome é obrigatório' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cpfCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [_cpfMask],
                      validator: _validarCpf,
                      decoration: const InputDecoration(labelText: 'CPF'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: InkWell(
                      onTap: _escolherNascimento,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Nascimento',
                          suffixIcon: Icon(Icons.calendar_today_outlined,
                              size: 18),
                        ),
                        child: Text(
                          _dataNascimento != null
                              ? '${_dataNascimento!.day.toString().padLeft(2, '0')}/'
                                  '${_dataNascimento!.month.toString().padLeft(2, '0')}/'
                                  '${_dataNascimento!.year}'
                              : '—',
                          style: tt.bodyLarge,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _genero,
                      decoration: const InputDecoration(labelText: 'Gênero'),
                      items: _generos
                          .map((g) =>
                              DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _genero = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppInputField(
                      label: 'Profissão',
                      controller: _profissaoCtrl,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _secao(context, 'Contato'),
              AppInputField(
                label: 'E-mail',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validarEmail,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  // Campo unico: `eleitores` guarda so' `telefone` — conferido
                  // nos 14 bancos, nao existe coluna `whatsapp` em nenhum, e o
                  // painel tambem so' tem um telefone. Havia um segundo campo
                  // "WhatsApp" aqui cujo conteudo era descartado sem aviso: na
                  // criacao virava alternativa ao telefone (perdia quando os
                  // dois vinham preenchidos) e na edicao era ignorado de vez.
                  Expanded(
                    child: TextFormField(
                      controller: _telefoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [_phoneMask],
                      validator: _validarTelefone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone / WhatsApp',
                        helperText: 'Usado para o envio de mensagens',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _secao(context, 'Endereço'),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AppInputField(
                      label: 'Endereço',
                      controller: _enderecoCtrl,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppInputField(
                      label: 'Nº',
                      controller: _numeroCtrl,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppInputField(
                      label: 'Complemento',
                      controller: _complementoCtrl,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppInputField(
                      label: 'Bairro',
                      controller: _bairroCtrl,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AppInputField(
                      label: 'Cidade',
                      controller: _cidadeCtrl,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _estado,
                      decoration: const InputDecoration(labelText: 'UF'),
                      items: _ufs
                          .map((uf) => DropdownMenuItem(
                                value: uf,
                                child: Text(uf),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _estado = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _cepCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [_cepMask],
                decoration: const InputDecoration(labelText: 'CEP'),
              ),
              const SizedBox(height: AppSpacing.lg),

              _secao(context, 'Relacionamento'),
              DropdownButtonFormField<String>(
                initialValue: _nivelApoio,
                decoration:
                    const InputDecoration(labelText: 'Nível de apoio'),
                items: _niveisApoio
                    .map((n) => DropdownMenuItem(
                          value: n.$1,
                          child: Text(n.$2),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _nivelApoio = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                value: _voluntario,
                onChanged: (v) => setState(() => _voluntario = v),
                title: const Text('Voluntário'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: AppSpacing.sm),

              Text('Etiquetas',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagInputCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Nova etiqueta...',
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: _addTag,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _addTag(_tagInputCtrl.text),
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: _tags
                      .map((t) => Chip(
                            label: Text(t),
                            onDeleted: () =>
                                setState(() => _tags.remove(t)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                label: widget.isEdit ? 'Salvar alterações' : 'Cadastrar munícipe',
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

  Widget _secao(BuildContext context, String titulo) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        titulo.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
      ),
    );
  }
}
