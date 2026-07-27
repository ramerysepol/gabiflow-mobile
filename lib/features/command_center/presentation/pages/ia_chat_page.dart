import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/command_center_providers.dart';
import '../widgets/ia_candidato_picker.dart';
import '../widgets/ia_chat_widgets.dart';

/// Chat streaming do Command Center IA.
/// Cada resposta mostra as consultas reais executadas (tools) e
/// visualizações inline dos dados retornados.
class IaChatPage extends ConsumerStatefulWidget {
  const IaChatPage({super.key, this.initialQuestion});

  final String? initialQuestion;

  @override
  ConsumerState<IaChatPage> createState() => _IaChatPageState();
}

class _IaChatPageState extends ConsumerState<IaChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    var contexto = ref.read(iaContextoProvider);
    if (contexto == null) {
      contexto = await showIaCandidatoPicker(context);
      if (contexto == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
    }
    final q = widget.initialQuestion;
    if (q != null && q.trim().isNotEmpty) {
      ref.read(iaChatProvider.notifier).send(q);
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    ref.read(iaChatProvider.notifier).send(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iaChatProvider);
    final contexto = ref.watch(iaContextoProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Auto-scroll conforme o texto chega
    ref.listen(iaChatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Consultor IA'),
            if (contexto != null)
              Text(
                '${contexto.nomeCandidato} · ${contexto.siglaPartido}',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Limpar conversa',
              onPressed: () =>
                  ref.read(iaChatProvider.notifier).clearConversation(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyChat(onSuggestion: (q) {
                    ref.read(iaChatProvider.notifier).send(q);
                  })
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: state.messages.length,
                    itemBuilder: (_, i) =>
                        IaChatBubble(message: state.messages[i]),
                  ),
          ),

          // ── Input bar ────────────────────────────────────────────────────
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.4)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      enabled: !state.isStreaming,
                      decoration: InputDecoration(
                        hintText: state.isStreaming
                            ? 'Consultando dados...'
                            : 'Pergunte sobre seus dados...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  state.isStreaming
                      ? IconButton.filled(
                          onPressed: () =>
                              ref.read(iaChatProvider.notifier).stop(),
                          icon: const Icon(Icons.stop_rounded),
                          tooltip: 'Parar',
                        )
                      : IconButton.filled(
                          onPressed: _send,
                          icon: const Icon(Icons.arrow_upward_rounded),
                          tooltip: 'Enviar',
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  static const _sugestoes = [
    ('🚀', 'Onde eu posso crescer?'),
    ('🗺️', 'Como está minha cobertura territorial?'),
    ('⚔️', 'Quem foram meus maiores adversários?'),
    ('🎯', 'Quais municípios têm votos mas o gabinete não atua?'),
    ('🏙️', 'Como foi minha votação em Salvador?'),
    ('📊', 'Compare meus votos com os dados do gabinete'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, size: 32, color: cs.onPrimary),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Consultor de Inteligência Eleitoral',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Cada número vem de uma consulta real ao TSE, IBGE\n'
            'e ao seu gabinete. Sem suposições.',
            textAlign: TextAlign.center,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 24),
        for (final (emoji, q) in _sugestoes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSuggestion(q),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(q, style: tt.bodySmall),
                    ),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16, color: cs.primary),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
