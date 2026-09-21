import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/acao_social_models.dart';
import '../providers/acao_social_providers.dart';

/// Cadastro presencial de municipe no evento ("Cadastrar e Atender" do
/// painel). O servidor faz upsert por telefone e adiciona a tag do evento.
/// Devolve [CadastroPresencialResult] via pop() para a central abrir o
/// seletor de especialidades.
class CadastroMunicipePage extends ConsumerStatefulWidget {
  const CadastroMunicipePage({super.key, required this.eventoId});

  final String eventoId;

  @override
  ConsumerState<CadastroMunicipePage> createState() =>
      _CadastroMunicipePageState();
}

class _CadastroMunicipePageState extends ConsumerState<CadastroMunicipePage> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _cep = TextEditingController();
  final _endereco = TextEditingController();
  final _numero = TextEditingController();
  final _complemento = TextEditingController();
  final _bairro = TextEditingController();
  final _cidade = TextEditingController();
  DateTime? _nascimento;
  String? _genero;
  String? _estado;
  bool _buscandoCep = false;

  final _maskTelefone = MaskTextInputFormatter(
      mask: '(##) #####-####', filter: {'#': RegExp(r'\d')});
  final _maskCep =
      MaskTextInputFormatter(mask: '#####-###', filter: {'#': RegExp(r'\d')});

  static const _generos = [
    'Masculino',
    'Feminino',
    'Outro',
    'Prefiro não informar',
  ];

  static const _ufs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO',
  ];

  @override
  void dispose() {
    for (final c in [
      _nome, _telefone, _email, _cep, _endereco, _numero, _complemento,
      _bairro, _cidade,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Capitaliza preservando preposicoes (mesma regra do painel).
  static String _capitalizar(String s) {
    const minusculas = {'da', 'de', 'do', 'das', 'dos', 'e', 'em', 'com'};
    return s
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => minusculas.contains(p)
            ? p
            : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  Future<void> _buscarCep() async {
    final digitos = _cep.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um CEP com 8 dígitos.')));
      return;
    }
    setState(() => _buscandoCep = true);
    try {
      final end =
          await ref.read(acaoSocialDataSourceProvider).buscarCep(digitos);
      if (!mounted) return;
      if (end == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CEP não encontrado.')));
      } else {
        setState(() {
          if (end.logradouro != null) _endereco.text = end.logradouro!;
          if (end.bairro != null) _bairro.text = end.bairro!;
          if (end.cidade != null) _cidade.text = end.cidade!;
          if (end.uf != null && _ufs.contains(end.uf)) _estado = end.uf;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível consultar o CEP agora.')));
      }
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _escolherNascimento() async {
    final hoje = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _nascimento ?? DateTime(hoje.year - 30, hoje.month, hoje.day),
      firstDate: DateTime(1900),
      lastDate: hoje,
      helpText: 'Data de nascimento',
    );
    if (d != null) setState(() => _nascimento = d);
  }

  Future<void> _salvar(EventoAcaoSocial evento) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final dados = <String, dynamic>{
      'nome': _capitalizar(_nome.text),
      'telefone': _telefone.text.replaceAll(RegExp(r'\D'), ''),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'data_nascimento': _nascimento == null
          ? null
          : DateFormat('yyyy-MM-dd').format(_nascimento!),
      'genero': _genero,
      'cep': _cep.text.trim().isEmpty ? null : _cep.text.trim(),
      'endereco':
          _endereco.text.trim().isEmpty ? null : _capitalizar(_endereco.text),
      'numero': _numero.text.trim().isEmpty ? null : _numero.text.trim(),
      'complemento':
          _complemento.text.trim().isEmpty ? null : _complemento.text.trim(),
      'bairro': _bairro.text.trim().isEmpty ? null : _capitalizar(_bairro.text),
      'cidade': _cidade.text.trim().isEmpty ? null : _capitalizar(_cidade.text),
      'estado': _estado,
    };

    final r = await ref
        .read(acaoSocialAcoesProvider.notifier)
        .cadastrarMunicipe(evento, dados);
    if (!mounted) return;
    if (r == null) {
      final erro = ref.read(acaoSocialAcoesProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(erro ?? 'Não foi possível cadastrar.'),
        backgroundColor: AppColors.dangerLight,
      ));
      return;
    }
    context.pop(r);
  }

  @override
  Widget build(BuildContext context) {
    final eventoAsync = ref.watch(eventoAcaoSocialProvider(widget.eventoId));
    final acoes = ref.watch(acaoSocialAcoesProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar munícipe')),
      body: eventoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(mensagemErroAcaoSocial(e))),
        data: (evento) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
            children: [
              Text(evento.nome,
                  style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.md),
              Text('Dados pessoais', style: tt.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              AppInputField(
                label: 'Nome completo *',
                controller: _nome,
                textInputAction: TextInputAction.next,
                validator: (v) => (v ?? '').trim().length < 3
                    ? 'Informe o nome completo'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _telefone,
                inputFormatters: [_maskTelefone],
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Telefone (com DDD) *',
                  hintText: '(71) 99999-9999',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                validator: (v) =>
                    (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10
                        ? 'Informe um telefone válido com DDD'
                        : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppInputField(
                label: 'E-mail',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  return t.contains('@') && t.contains('.')
                      ? null
                      : 'E-mail inválido';
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _escolherNascimento,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Nascimento',
                          suffixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        child: Text(
                          _nascimento == null
                              ? '—'
                              : DateFormat('dd/MM/yyyy').format(_nascimento!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _genero,
                      // isExpanded: "Prefiro não informar" nao cabe em meia
                      // largura e estourava a Row em 27 px.
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Gênero'),
                      items: [
                        for (final g in _generos)
                          DropdownMenuItem(value: g, child: Text(g)),
                      ],
                      onChanged: (v) => setState(() => _genero = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Endereço', style: tt.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cep,
                      inputFormatters: [_maskCep],
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: (_) => _buscarCep(),
                      decoration: const InputDecoration(labelText: 'CEP'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      // Dentro de uma Row a largura e' ilimitada; o tema
                      // pede largura minima infinita e o layout estoura
                      // (tela em branco). Largura minima zero aqui.
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: _buscandoCep ? null : _buscarCep,
                      icon: _buscandoCep
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search_rounded),
                      label: const Text('Buscar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppInputField(
                label: 'Endereço',
                controller: _endereco,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppInputField(
                      label: 'Número',
                      controller: _numero,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: AppInputField(
                      label: 'Complemento',
                      controller: _complemento,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppInputField(
                label: 'Bairro',
                controller: _bairro,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppInputField(
                      label: 'Cidade',
                      controller: _cidade,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _estado,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'UF'),
                      items: [
                        for (final uf in _ufs)
                          DropdownMenuItem(value: uf, child: Text(uf)),
                      ],
                      onChanged: (v) => setState(() => _estado = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'O munícipe recebe a tag "${evento.tag}" e, se já existir pelo telefone, tem o cadastro atualizado.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Cadastrar e atender',
                icon: Icons.medical_services_rounded,
                isLoading: acoes.isLoading,
                onPressed: () => _salvar(evento),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
