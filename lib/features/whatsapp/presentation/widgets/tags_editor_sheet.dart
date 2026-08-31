import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/central_providers.dart';
import 'central_visuals.dart';

/// Editor de etiquetas de uma conversa: marca/desmarca do catalogo, cria nova
/// etiqueta com cor, e salva (PUT substitui o array — igual ao web). Retorna a
/// nova lista de nomes aplicada, ou null se cancelou.
class TagsEditorSheet extends ConsumerStatefulWidget {
  const TagsEditorSheet({super.key, required this.conversationId});

  final int conversationId;

  static Future<List<String>?> mostrar(
    BuildContext context,
    int conversationId,
  ) {
    // Tela cheia (Navigator.push) em vez de bottom sheet — o modal estava
    // congelando em alguns aparelhos.
    return Navigator.of(context).push<List<String>>(
      MaterialPageRoute<List<String>>(
        builder: (_) => TagsEditorSheet(conversationId: conversationId),
      ),
    );
  }

  @override
  ConsumerState<TagsEditorSheet> createState() => _TagsEditorSheetState();
}

class _TagsEditorSheetState extends ConsumerState<TagsEditorSheet> {
  final _novaCtrl = TextEditingController();
  final Set<String> _selecionadas = {};
  bool _carregando = true;
  bool _salvando = false;
  String _corNova = _paleta.first;

  static const List<String> _paleta = [
    '#EF4444', '#F97316', '#EAB308', '#22C55E', '#06B6D4',
    '#3B82F6', '#6366F1', '#A855F7', '#EC4899', '#6B7280',
  ];

  @override
  void initState() {
    super.initState();
    _carregarAtuais();
  }

  Future<void> _carregarAtuais() async {
    try {
      final atuais = await ref
          .read(centralDataSourceProvider)
          .etiquetasDaConversa(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _selecionadas.addAll(atuais);
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _novaCtrl.dispose();
    super.dispose();
  }

  Future<void> _criarNova() async {
    final nome = _novaCtrl.text.trim();
    if (nome.isEmpty) return;
    try {
      await ref
          .read(centralDataSourceProvider)
          .criarEtiqueta(nome, cor: _corNova);
      if (!mounted) return;
      _novaCtrl.clear();
      setState(() => _selecionadas.add(nome));
      ref.invalidate(etiquetasCatalogoProvider); // recarrega catalogo c/ cor
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao criar etiqueta: $e')));
      }
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await ref.read(centralDataSourceProvider).atualizarEtiquetasConversa(
            widget.conversationId,
            _selecionadas.toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(_selecionadas.toList());
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao salvar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = ref.watch(etiquetasCatalogoProvider);
    final cores = ref.watch(catalogoCoresEtiquetasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etiquetas'),
        actions: [
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salvar'),
          ),
        ],
      ),
      // ListView simples (scrollable robusto) com CheckboxListTile — sem Wrap
      // dentro de scroll, que travava o layout neste device.
      body: catalogo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Falha ao carregar o catálogo:\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (lista) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (_carregando) const LinearProgressIndicator(minHeight: 2),
            if (lista.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhuma etiqueta no catálogo. Crie a primeira abaixo.'),
              ),
            ...lista.map((e) {
              final resolvida = resolverEtiqueta(e.nome, cores);
              return CheckboxListTile(
                value: _selecionadas.contains(e.nome),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selecionadas.add(e.nome);
                  } else {
                    _selecionadas.remove(e.nome);
                  }
                }),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: CircleAvatar(radius: 9, backgroundColor: resolvida.cor),
                title: Text(e.nome),
                dense: true,
              );
            }),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Criar nova etiqueta',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _novaCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Nome da etiqueta',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _criarNova(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _criarNova,
                        child: const Text('Criar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Paleta em scroll horizontal (sem Wrap).
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _paleta.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final hex = _paleta[i];
                        final cor = resolverEtiqueta('x:$hex', const {}).cor;
                        final sel = _corNova == hex;
                        return GestureDetector(
                          onTap: () => setState(() => _corNova = hex),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: cor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sel ? Colors.black : Colors.white24,
                                width: sel ? 3 : 1.5,
                              ),
                            ),
                            child: sel
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
