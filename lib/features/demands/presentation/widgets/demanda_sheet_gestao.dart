import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/friendly_error.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/demanda_model.dart';
import '../../data/models/demanda_vocab.dart';
import '../providers/demanda_providers.dart';
import 'demanda_sheet_base.dart';

void _erro(BuildContext c, Object e) => ScaffoldMessenger.of(
  c,
).showSnackBar(SnackBar(content: Text(mensagemAmigavel(e))));

/// Atribuir responsável.
class DemandaSheetAtribuir extends ConsumerStatefulWidget {
  const DemandaSheetAtribuir({super.key, required this.demanda});
  final DemandaDetalhe demanda;

  @override
  ConsumerState<DemandaSheetAtribuir> createState() => _AtribuirState();
}

class _AtribuirState extends ConsumerState<DemandaSheetAtribuir> {
  bool _salvando = false;

  Future<void> _atribuir(int? userId) async {
    setState(() => _salvando = true);
    try {
      await ref
          .read(demandaDataSourceProvider)
          .atribuir(widget.demanda.id, userId);
      if (!mounted) return;
      demandaAtualizada(ref, widget.demanda.id);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _erro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opcoes = ref.watch(demandaOpcoesProvider);
    final meuId = ref.watch(authProvider).user?.id;
    final atual = widget.demanda.responsavel?.id;
    return DemandaSheetCorpo(
      titulo: 'Atribuir responsável',
      children: [
        if (_salvando) const LinearProgressIndicator(minHeight: 2),
        if (meuId != null && atual != meuId)
          ListTile(
            leading: const Icon(Icons.person_pin_circle_outlined),
            title: const Text('Assumir para mim'),
            onTap: _salvando ? null : () => _atribuir(meuId),
          ),
        opcoes.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(mensagemAmigavel(e)),
          data: (o) => Column(
            children: [
              for (final r in o.responsaveis)
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(r.nome),
                  trailing: r.id == atual
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: _salvando ? null : () => _atribuir(r.id),
                ),
            ],
          ),
        ),
        if (atual != null)
          ListTile(
            leading: const Icon(Icons.person_off_outlined),
            title: const Text('Remover responsável'),
            onTap: _salvando ? null : () => _atribuir(null),
          ),
      ],
    );
  }
}

/// Encaminhar ao órgão (opcionalmente gerando ofício).
class DemandaSheetEncaminhar extends ConsumerStatefulWidget {
  const DemandaSheetEncaminhar({super.key, required this.demanda});
  final DemandaDetalhe demanda;

  @override
  ConsumerState<DemandaSheetEncaminhar> createState() => _EncaminharState();
}

class _EncaminharState extends ConsumerState<DemandaSheetEncaminhar> {
  static const _outro = -1;
  int? _orgao;
  final _nomeLivre = TextEditingController();
  DateTime? _prazo;
  bool _oficio = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _orgao = widget.demanda.orgao?.id;
  }

  @override
  void dispose() {
    _nomeLivre.dispose();
    super.dispose();
  }

  Future<void> _escolherPrazo() async {
    final h = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: h.add(const Duration(days: 15)),
      firstDate: h,
      lastDate: h.add(const Duration(days: 365)),
    );
    if (d != null && mounted) setState(() => _prazo = d);
  }

  Future<void> _enviar() async {
    final livre = _orgao == _outro || _orgao == null;
    final nome = _nomeLivre.text.trim();
    if (livre && nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha ou informe o órgão.')),
      );
      return;
    }
    setState(() => _enviando = true);
    try {
      await ref
          .read(demandaDataSourceProvider)
          .encaminhar(
            widget.demanda.id,
            orgaoId: livre ? null : _orgao,
            orgaoNome: livre ? nome : null,
            prazoResposta: _prazo == null
                ? null
                : DateFormat('yyyy-MM-dd').format(_prazo!),
            gerarOficio: _oficio,
          );
      if (!mounted) return;
      demandaAtualizada(ref, widget.demanda.id);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      _erro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgaos =
        ref.watch(demandaOpcoesProvider).valueOrNull?.orgaos ?? const [];
    final valor = orgaos.any((o) => o.id == _orgao)
        ? _orgao
        : (_orgao == _outro ? _outro : null);
    final livre = valor == null || valor == _outro;
    return DemandaSheetCorpo(
      titulo: 'Encaminhar ao órgão',
      subtitulo: 'Registra o encaminhamento e acompanha a resposta',
      children: [
        DropdownButtonFormField<int>(
          initialValue: valor,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Órgão',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final o in orgaos)
              if (o.id != null)
                DropdownMenuItem(
                  value: o.id,
                  child: Text(o.nome, overflow: TextOverflow.ellipsis),
                ),
            const DropdownMenuItem(
              value: _outro,
              child: Text('Outro (digitar)'),
            ),
          ],
          onChanged: (v) => setState(() => _orgao = v),
        ),
        if (livre) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _nomeLivre,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome do órgão',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _escolherPrazo,
          icon: const Icon(Icons.event_outlined),
          label: Text(
            _prazo == null
                ? 'Prazo de resposta (opcional)'
                : 'Resposta até ${DateFormat('dd/MM/yyyy').format(_prazo!)}',
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Gerar ofício'),
          subtitle: const Text('Cria o ofício a partir da demanda'),
          value: _oficio,
          onChanged: (v) => setState(() => _oficio = v ?? false),
        ),
        const SizedBox(height: 8),
        DemandaBotaoSheet(
          rotulo: 'Encaminhar',
          icone: Icons.send_rounded,
          carregando: _enviando,
          onPressed: _enviar,
        ),
      ],
    );
  }
}

/// Anexar arquivo: câmera, galeria ou arquivos.
class DemandaSheetAnexar extends ConsumerStatefulWidget {
  const DemandaSheetAnexar({super.key, required this.demanda});
  final DemandaDetalhe demanda;

  @override
  ConsumerState<DemandaSheetAnexar> createState() => _AnexarState();
}

class _AnexarState extends ConsumerState<DemandaSheetAnexar> {
  static const _tipos = ['anexo', 'laudo', 'comprovante', 'foto'];
  String _tipo = 'anexo';
  bool _enviando = false;

  Future<void> _escolher(String origem) async {
    String? caminho;
    try {
      if (origem == 'arquivo') {
        caminho = (await FilePicker.pickFile())?.path;
      } else {
        final x = await ImagePicker().pickImage(
          source: origem == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 82,
          maxWidth: 1920,
        );
        caminho = x?.path;
      }
    } catch (e) {
      if (mounted) _erro(context, e);
      return;
    }
    if (caminho == null || !mounted) return;
    setState(() => _enviando = true);
    try {
      await ref
          .read(demandaDataSourceProvider)
          .enviarAnexo(widget.demanda.id, caminho, tipo: _tipo);
      if (!mounted) return;
      demandaAtualizada(ref, widget.demanda.id);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      _erro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemandaSheetCorpo(
      titulo: 'Anexar',
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final t in _tipos)
              ChoiceChip(
                label: Text(t[0].toUpperCase() + t.substring(1)),
                selected: _tipo == t,
                onSelected: (_) => setState(() => _tipo = t),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_enviando)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Câmera'),
            onTap: () => _escolher('camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Galeria'),
            onTap: () => _escolher('galeria'),
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: const Text('Arquivo (PDF, documento)'),
            onTap: () => _escolher('arquivo'),
          ),
        ],
      ],
    );
  }
}

/// Editar dados básicos (PATCH).
class DemandaSheetEditar extends ConsumerStatefulWidget {
  const DemandaSheetEditar({super.key, required this.demanda});
  final DemandaDetalhe demanda;

  @override
  ConsumerState<DemandaSheetEditar> createState() => _EditarState();
}

class _EditarState extends ConsumerState<DemandaSheetEditar> {
  late final _titulo = TextEditingController(text: widget.demanda.titulo);
  late final _descricao = TextEditingController(text: widget.demanda.descricao);
  late final _obs = TextEditingController(text: widget.demanda.observacoes);
  late String _prioridade = widget.demanda.prioridade;
  late DateTime? _prazo = parseData(widget.demanda.prazo);
  bool _salvando = false;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _escolherPrazo() async {
    final h = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _prazo ?? h,
      firstDate: h.subtract(const Duration(days: 365)),
      lastDate: h.add(const Duration(days: 730)),
    );
    if (d != null && mounted) setState(() => _prazo = d);
  }

  Future<void> _salvar() async {
    if (_titulo.text.trim().isEmpty) return;
    final d = widget.demanda;
    final corpo = <String, dynamic>{
      if (_titulo.text.trim() != d.titulo) 'titulo': _titulo.text.trim(),
      if (_descricao.text.trim() != d.descricao)
        'descricao': _descricao.text.trim(),
      if (_obs.text.trim() != (d.observacoes ?? ''))
        'observacoes': _obs.text.trim(),
      if (_prioridade != d.prioridade) 'prioridade': _prioridade,
      if (_prazo != null &&
          DateFormat('yyyy-MM-dd').format(_prazo!) !=
              (d.prazo ?? '').split('T').first)
        'prazo': DateFormat('yyyy-MM-dd').format(_prazo!),
    };
    if (corpo.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _salvando = true);
    try {
      await ref.read(demandaDataSourceProvider).editar(d.id, corpo);
      if (!mounted) return;
      demandaAtualizada(ref, d.id);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _erro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemandaSheetCorpo(
      titulo: 'Editar demanda',
      children: [
        TextField(
          controller: _titulo,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Título',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descricao,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Descrição',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _obs,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Observações',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final p in DemandaVocab.prioridadeLista)
              ChoiceChip(
                label: Text(DemandaVocab.prioridade(p)),
                selected: _prioridade == p,
                onSelected: (_) => setState(() => _prioridade = p),
              ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _escolherPrazo,
          icon: const Icon(Icons.event_outlined),
          label: Text(
            _prazo == null
                ? 'Definir prazo'
                : 'Prazo: ${DateFormat('dd/MM/yyyy').format(_prazo!)}',
          ),
        ),
        const SizedBox(height: 16),
        DemandaBotaoSheet(
          rotulo: 'Salvar alterações',
          carregando: _salvando,
          onPressed: _salvar,
        ),
      ],
    );
  }
}
