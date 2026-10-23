import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/friendly_error.dart';
import '../../data/models/demanda_model.dart';
import '../../data/models/demanda_vocab.dart';
import '../providers/demanda_providers.dart';
import 'demanda_chips.dart';

/// Timeline humana: ícone por tipo, descrição, autor e tempo relativo.
class DemandaTimeline extends StatelessWidget {
  const DemandaTimeline({super.key, required this.eventos});
  final List<DemandaEvento> eventos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (eventos.isEmpty) {
      return Text(
        'Nenhum registro ainda.',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      );
    }
    // A API já devolve do mais recente ao mais antigo (índice por created_at DESC).
    return Column(
      children: [
        for (final (i, e) in eventos.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(
                          DemandaVocab.iconeEvento(e.tipo),
                          size: 15,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      if (i < eventos.length - 1)
                        Expanded(
                          child: Container(width: 2, color: cs.outlineVariant),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.descricao, style: tt.bodyMedium),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              [
                                if (e.user != null) e.user!.nome,
                                tempoRelativo(e.createdAt),
                              ].where((s) => s.isNotEmpty).join(' · '),
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            if (e.visivelMunicipe)
                              DemandaChip(
                                rotulo: 'visível ao munícipe',
                                cor: cs.primary,
                                icone: Icons.visibility_outlined,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Caixa de comentário com toggle "visível ao munícipe".
class DemandaCaixaComentario extends ConsumerStatefulWidget {
  const DemandaCaixaComentario({super.key, required this.demandaId});
  final int demandaId;

  @override
  ConsumerState<DemandaCaixaComentario> createState() => _ComentarioState();
}

class _ComentarioState extends ConsumerState<DemandaCaixaComentario> {
  final _ctrl = TextEditingController();
  bool _visivel = false;
  bool _enviando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() => _enviando = true);
    try {
      await ref
          .read(demandaDataSourceProvider)
          .comentar(widget.demandaId, t, visivelMunicipe: _visivel);
      if (!mounted) return;
      _ctrl.clear();
      FocusScope.of(context).unfocus();
      setState(() {
        _visivel = false;
        _enviando = false;
      });
      demandaAtualizada(ref, widget.demandaId);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Escreva um comentário',
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: _enviando
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Enviar comentário',
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _enviar,
                  ),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Visível ao munícipe'),
          value: _visivel,
          onChanged: (v) => setState(() => _visivel = v),
        ),
      ],
    );
  }
}
