import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/friendly_error.dart';
import '../../data/models/demanda_model.dart';
import '../../data/models/demanda_vocab.dart';
import '../providers/demanda_providers.dart';
import 'demanda_sheet_base.dart';

const _statusComModelo = {
  'em_andamento',
  'aguardando_retorno',
  'concluida',
  'cancelada',
};

/// Mudar status, com prévia editável da mensagem ao munícipe.
class DemandaSheetStatus extends ConsumerStatefulWidget {
  const DemandaSheetStatus({super.key, required this.demanda});
  final DemandaDetalhe demanda;

  @override
  ConsumerState<DemandaSheetStatus> createState() => _State();
}

class _State extends ConsumerState<DemandaSheetStatus> {
  String? _novo;
  final _comentario = TextEditingController();
  final _mensagem = TextEditingController();
  bool _temPrevia = false;
  bool _notificar = false;
  bool _carregandoPrevia = false;
  bool _enviando = false;

  bool get _temTelefone =>
      (widget.demanda.municipe?.telefone ?? '').trim().isNotEmpty;

  @override
  void dispose() {
    _comentario.dispose();
    _mensagem.dispose();
    super.dispose();
  }

  Future<void> _escolher(String status) async {
    setState(() {
      _novo = status;
      _temPrevia = false;
      _notificar = false;
      _mensagem.clear();
    });
    if (!_statusComModelo.contains(status) || !_temTelefone) return;
    setState(() => _carregandoPrevia = true);
    try {
      final txt = await ref
          .read(demandaDataSourceProvider)
          .previaRetorno(widget.demanda.id, status: status);
      if (!mounted || _novo != status) return;
      setState(() {
        _mensagem.text = txt;
        _temPrevia = txt.trim().isNotEmpty;
        _notificar = _temPrevia;
      });
    } catch (_) {
      // Sem prévia: o status muda normalmente, só não oferece o aviso.
    } finally {
      if (mounted) setState(() => _carregandoPrevia = false);
    }
  }

  Future<void> _salvar() async {
    final novo = _novo;
    if (novo == null) return;
    setState(() => _enviando = true);
    try {
      await ref
          .read(demandaDataSourceProvider)
          .mudarStatus(
            widget.demanda.id,
            novo,
            comentario: _comentario.text,
            notificarMunicipe: _notificar,
            mensagem: _mensagem.text,
          );
      if (!mounted) return;
      demandaAtualizada(ref, widget.demanda.id);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagemAmigavel(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final atual = widget.demanda.status;
    return DemandaSheetCorpo(
      titulo: 'Mudar status',
      subtitulo: 'Hoje: ${DemandaVocab.status(atual)}',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final s in DemandaVocab.statusLista.where((e) => e != atual))
              ChoiceChip(
                label: Text(DemandaVocab.status(s)),
                selected: _novo == s,
                selectedColor: DemandaVocab.corStatus(
                  context,
                  s,
                ).withValues(alpha: 0.2),
                onSelected: (_) => _escolher(s),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _comentario,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Comentário (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        if (_carregandoPrevia)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_temPrevia) ...[
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Avisar o munícipe pelo WhatsApp'),
            value: _notificar,
            onChanged: (v) => setState(() => _notificar = v),
          ),
          if (_notificar)
            TextField(
              controller: _mensagem,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Mensagem ao munícipe',
                helperText: 'Você pode editar antes de enviar',
                border: OutlineInputBorder(),
              ),
            ),
        ] else if (_novo != null &&
            _statusComModelo.contains(_novo) &&
            !_temTelefone &&
            !_carregandoPrevia)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Munícipe sem telefone: não é possível avisá-lo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 16),
        DemandaBotaoSheet(
          rotulo: _notificar ? 'Salvar e avisar' : 'Salvar',
          carregando: _enviando,
          onPressed: _novo == null ? null : _salvar,
        ),
      ],
    );
  }
}

/// Retornar ao munícipe (mensagem avulsa pelo WhatsApp).
class DemandaSheetRetorno extends ConsumerStatefulWidget {
  const DemandaSheetRetorno({super.key, required this.demanda});
  final DemandaDetalhe demanda;

  @override
  ConsumerState<DemandaSheetRetorno> createState() => _RetornoState();
}

class _RetornoState extends ConsumerState<DemandaSheetRetorno> {
  final _mensagem = TextEditingController();
  bool _carregando = true;
  bool _enviando = false;

  bool get _temTelefone =>
      (widget.demanda.municipe?.telefone ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _carregarPrevia();
  }

  @override
  void dispose() {
    _mensagem.dispose();
    super.dispose();
  }

  Future<void> _carregarPrevia() async {
    if (!_temTelefone) {
      setState(() => _carregando = false);
      return;
    }
    try {
      final txt = await ref
          .read(demandaDataSourceProvider)
          .previaRetorno(widget.demanda.id, status: widget.demanda.status);
      if (mounted && _mensagem.text.isEmpty) _mensagem.text = txt;
    } catch (_) {
      // Campo vazio: o atendente escreve do zero.
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _enviar() async {
    if (_mensagem.text.trim().isEmpty) return;
    setState(() => _enviando = true);
    try {
      await ref
          .read(demandaDataSourceProvider)
          .enviarRetorno(widget.demanda.id, _mensagem.text);
      if (!mounted) return;
      demandaAtualizada(ref, widget.demanda.id);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagemAmigavel(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.demanda.municipe?.nome ?? 'o munícipe';
    return DemandaSheetCorpo(
      titulo: 'Retornar ao munícipe',
      subtitulo: 'Mensagem de WhatsApp para $nome',
      children: [
        if (!_temTelefone)
          const Text('Este munícipe não tem telefone cadastrado.')
        else ...[
          if (_carregando) const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
          TextField(
            controller: _mensagem,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Mensagem',
              helperText: 'Prévia editável — inclui o protocolo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DemandaBotaoSheet(
            rotulo: 'Enviar pelo WhatsApp',
            icone: Icons.send_rounded,
            carregando: _enviando,
            onPressed: _enviar,
          ),
        ],
      ],
    );
  }
}
