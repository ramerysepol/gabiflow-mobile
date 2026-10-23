import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/friendly_error.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../constituents/data/models/constituent_model.dart';
import '../../../constituents/presentation/providers/constituent_provider.dart';
import '../../data/models/demanda_extras.dart';
import '../../data/models/demanda_model.dart';
import '../../data/models/demanda_vocab.dart';
import '../providers/demanda_providers.dart';
import '../widgets/demanda_saude_form.dart';
import '../widgets/municipe_picker.dart';

/// Nova demanda com Assistente: cola o texto, a IA preenche, o atendente confirma.
class DemandaNovaPage extends ConsumerStatefulWidget {
  const DemandaNovaPage({
    super.key,
    this.eleitorId,
    this.conversationId,
    this.textoInicial,
  });

  final int? eleitorId;
  final int? conversationId;
  final String? textoInicial;

  @override
  ConsumerState<DemandaNovaPage> createState() => _DemandaNovaPageState();
}

class _DemandaNovaPageState extends ConsumerState<DemandaNovaPage> {
  final _form = GlobalKey<FormState>();
  late final _texto = TextEditingController(text: widget.textoInicial);
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _saude = SaudeFormController();

  ConstituentModel? _municipe;
  String _area = 'geral';
  String _prioridade = 'media';
  late String _canal = widget.conversationId != null
      ? 'whatsapp'
      : 'presencial';
  int? _orgaoId;
  String? _resumoIa;
  List<String> _tags = const [];
  DateTime? _prazoManual;
  final Set<String> _ia = {};
  bool _gerandoIa = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final id = widget.eleitorId;
    if (id != null) _carregarMunicipe(id);
  }

  @override
  void dispose() {
    _texto.dispose();
    _titulo.dispose();
    _descricao.dispose();
    _saude.dispose();
    super.dispose();
  }

  void _aviso(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _carregarMunicipe(int id) async {
    try {
      final m = await ref
          .read(constituentDataSourceProvider)
          .getConstituentById('$id');
      if (mounted) setState(() => _municipe = m);
    } catch (_) {
      // Sem o munícipe pré-carregado o usuário escolhe manualmente.
    }
  }

  Future<void> _escolherMunicipe() async {
    final m = await escolherMunicipe(context);
    if (m != null && mounted) setState(() => _municipe = m);
  }

  Future<void> _preencherComIa() async {
    final temTexto = _texto.text.trim().isNotEmpty;
    if (!temTexto && widget.conversationId == null) {
      _aviso('Cole a mensagem ou descreva o pedido primeiro.');
      return;
    }
    setState(() => _gerandoIa = true);
    try {
      final s = await ref
          .read(demandaDataSourceProvider)
          .sugerirIa(
            texto: _texto.text,
            conversationId: widget.conversationId,
            eleitorId: _municipe != null ? int.tryParse(_municipe!.id) : null,
          );
      if (!mounted) return;
      setState(() {
        _ia.clear();
        if (s.titulo.isNotEmpty) {
          _titulo.text = s.titulo;
          _ia.add('titulo');
        }
        if (s.resumo.isNotEmpty) {
          _descricao.text = s.resumo;
          _resumoIa = s.resumo;
          _ia.add('descricao');
        }
        _area = s.area == 'saude' ? 'saude' : 'geral';
        _ia.add('area');
        if (DemandaVocab.prioridadeLista.contains(s.prioridade)) {
          _prioridade = s.prioridade;
          _ia.add('prioridade');
        }
        if (s.canal != null && DemandaVocab.canalLista.contains(s.canal)) {
          _canal = s.canal!;
        }
        if (s.orgaoSugerido?.id != null) {
          _orgaoId = s.orgaoSugerido!.id;
          _ia.add('orgao');
        }
        if (_area == 'saude' && s.saude != null) {
          _saude.preencher(s.saude!);
          _ia.addAll(['tipoPedido', 'urgenciaClinica']);
          if ((s.saude!.especialidade ?? '').isNotEmpty) {
            _ia.add('especialidade');
          }
        }
        _tags = s.tags;
      });
    } catch (e) {
      if (mounted) _aviso(mensagemAmigavel(e));
    } finally {
      if (mounted) setState(() => _gerandoIa = false);
    }
  }

  DateTime _prazoCalculado(DemandaConfig cfg) {
    final dias = cfg.diasPara(
      area: _area,
      prioridade: _prioridade,
      urgenciaClinica: _saude.urgencia,
    );
    final h = DateTime.now();
    return DateTime(h.year, h.month, h.day).add(Duration(days: dias));
  }

  Future<void> _escolherPrazo(DateTime inicial) async {
    final h = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: inicial.isBefore(h) ? h : inicial,
      firstDate: DateTime(h.year, h.month, h.day),
      lastDate: h.add(const Duration(days: 730)),
    );
    if (d != null && mounted) setState(() => _prazoManual = d);
  }

  Future<void> _salvar() async {
    if (_municipe == null) {
      _aviso('Escolha o munícipe da demanda.');
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _salvando = true);
    try {
      final corpo = <String, dynamic>{
        'titulo': _titulo.text.trim(),
        'descricao': _descricao.text.trim(),
        'eleitorId': int.parse(_municipe!.id),
        'area': _area,
        'prioridade': _prioridade,
        'canal': _canal,
        if (_orgaoId != null) 'orgaoId': _orgaoId,
        if (_prazoManual != null)
          'prazo': DateFormat('yyyy-MM-dd').format(_prazoManual!),
        if (_tags.isNotEmpty) 'tags': _tags,
        if (widget.conversationId != null)
          'conversationId': widget.conversationId,
        if (_resumoIa != null) 'resumoIa': _resumoIa,
        if (_area == 'saude') 'saude': _saude.toJson(),
      };
      final d = await ref.read(demandaDataSourceProvider).criar(corpo);
      if (!mounted) return;
      ref.read(demandaListaProvider.notifier).recarregar(silencioso: true);
      context.pushReplacement('/home/demands/${d.id}');
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        _aviso(mensagemAmigavel(e));
      }
    }
  }

  InputDecoration _dec(String rotulo, String campo, {String? ajuda}) =>
      InputDecoration(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text(rotulo), if (_ia.contains(campo)) const IaBadge()],
        ),
        helperText: ajuda,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final opcoes = ref.watch(demandaOpcoesProvider).valueOrNull;
    final config =
        ref.watch(demandaConfigProvider).valueOrNull ?? const DemandaConfig();
    final prazo = _prazoManual ?? _prazoCalculado(config);
    final dias = prazo
        .difference(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        )
        .inDays;

    return Scaffold(
      appBar: AppBar(title: const Text('Nova demanda')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _assistente(cs, tt),
              const SizedBox(height: AppSpacing.md),
              _campoMunicipe(cs),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final a in const ['geral', 'saude'])
                    ButtonSegment(
                      value: a,
                      icon: Icon(DemandaVocab.iconeArea(a), size: 18),
                      label: Text(DemandaVocab.area(a)),
                    ),
                ],
                selected: {_area},
                onSelectionChanged: (s) => setState(() {
                  _area = s.first;
                  _ia.remove('area');
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _titulo,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Título', 'titulo'),
                onChanged: (_) => _ia.remove('titulo'),
                validator: (v) =>
                    (v ?? '').trim().length < 3 ? 'Informe o título' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descricao,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Descrição', 'descricao'),
                onChanged: (_) => _ia.remove('descricao'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Descreva o pedido' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_area == 'saude') ...[
                DemandaSaudeForm(
                  controller: _saude,
                  especialidades: opcoes?.especialidades ?? const [],
                  nomeMunicipe: _municipe?.nome,
                  iaCampos: _ia,
                  aoAlterar: () => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text('Prioridade', style: tt.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in DemandaVocab.prioridadeLista)
                    ChoiceChip(
                      label: Text(DemandaVocab.prioridade(p)),
                      selected: _prioridade == p,
                      selectedColor: DemandaVocab.corPrioridade(
                        context,
                        p,
                      ).withValues(alpha: 0.2),
                      onSelected: (_) => setState(() {
                        _prioridade = p;
                        _ia.remove('prioridade');
                      }),
                    ),
                  if (_ia.contains('prioridade')) const IaBadge(),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: ValueKey(_canal),
                initialValue: _canal,
                decoration: _dec('Canal de recebimento', 'canal'),
                items: [
                  for (final c in DemandaVocab.canalLista)
                    DropdownMenuItem(
                      value: c,
                      child: Text(DemandaVocab.canal(c)),
                    ),
                ],
                onChanged: (v) => setState(() => _canal = v ?? _canal),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int?>(
                key: ValueKey('orgao$_orgaoId'),
                initialValue:
                    opcoes?.orgaos.any((o) => o.id == _orgaoId) == true
                    ? _orgaoId
                    : null,
                isExpanded: true,
                decoration: _dec('Órgão de destino (opcional)', 'orgao'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Nenhum'),
                  ),
                  for (final o in opcoes?.orgaos ?? const <DemandaOrgao>[])
                    DropdownMenuItem<int?>(
                      value: o.id,
                      child: Text(o.nome, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _orgaoId = v;
                  _ia.remove('orgao');
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              _cartaoPrazo(cs, tt, prazo, dias),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_salvando ? 'Salvando...' : 'Registrar demanda'),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _assistente(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('Assistente', style: tt.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _texto,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: widget.conversationId != null
                  ? 'Cole a mensagem ou deixe vazio para usar a conversa do WhatsApp'
                  : 'Cole a mensagem ou descreva o pedido do munícipe',
              filled: true,
              fillColor: cs.surface,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _gerandoIa ? null : _preencherComIa,
              icon: _gerandoIa
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(_gerandoIa ? 'Analisando...' : 'Preencher com IA'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoMunicipe(ColorScheme cs) {
    final m = _municipe;
    return Semantics(
      button: true,
      label: m == null ? 'Escolher munícipe' : 'Munícipe ${m.nome}, trocar',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: _escolherMunicipe,
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Munícipe',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.search),
          ),
          child: Text(
            m?.nome ?? 'Toque para buscar o munícipe',
            style: TextStyle(color: m == null ? cs.onSurfaceVariant : null),
          ),
        ),
      ),
    );
  }

  Widget _cartaoPrazo(ColorScheme cs, TextTheme tt, DateTime prazo, int dias) {
    final fmt = DateFormat('dd/MM/yyyy').format(prazo);
    final texto = dias <= 0
        ? 'Vence hoje — $fmt'
        : 'Vence em $dias ${dias == 1 ? 'dia' : 'dias'} — $fmt';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Icon(Icons.event_outlined, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prazo (SLA)', style: tt.labelMedium),
                Text(texto, style: tt.bodyMedium),
                if (_prazoManual != null)
                  Text(
                    'Definido manualmente',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _escolherPrazo(prazo),
            child: const Text('Alterar'),
          ),
          if (_prazoManual != null)
            IconButton(
              tooltip: 'Voltar ao prazo automático',
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: () => setState(() => _prazoManual = null),
            ),
        ],
      ),
    );
  }
}
