import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/central_models.dart';
import '../providers/central_providers.dart';

/// Chat de uma conversa — visual familiar do WhatsApp: fundo bege/escuro,
/// bolhas verde (enviada) e branca (recebida), ticks de status e separadores
/// de data. Toda regra (janela 24h, provedor, lida) vem do servidor.
class CentralChatPage extends ConsumerStatefulWidget {
  const CentralChatPage({
    super.key,
    required this.conversationId,
    this.nomeContato,
    this.telefone,
  });

  final int conversationId;
  final String? nomeContato;
  final String? telefone;

  @override
  ConsumerState<CentralChatPage> createState() => _CentralChatPageState();
}

class _CentralChatPageState extends ConsumerState<CentralChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  int _ultimaQtd = 0;

  // Paleta WhatsApp (proposital: familiaridade acima do tema do tenant).
  static const _fundoClaro = Color(0xFFECE5DD);
  static const _fundoEscuro = Color(0xFF0B141A);
  static const _bolhaMinhaClaro = Color(0xFFDCF8C6);
  static const _bolhaMinhaEscuro = Color(0xFF005C4B);
  static const _tickAzul = Color(0xFF53BDEB);

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _rolarParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _enviar() async {
    final texto = _inputController.text;
    if (texto.trim().isEmpty) return;
    _inputController.clear();
    await ref
        .read(chatProvider(widget.conversationId).notifier)
        .enviarTexto(texto);
  }

  Future<void> _abrirRespostasRapidas() async {
    final respostas =
        await ref.read(respostasRapidasProvider.future).catchError((_) {
      return <RespostaRapida>[];
    });
    if (!mounted) return;
    if (respostas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma resposta rápida cadastrada.')),
      );
      return;
    }
    final escolhida = await showModalBottomSheet<RespostaRapida>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView.builder(
        itemCount: respostas.length,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.bolt_rounded, color: Color(0xFF25D366)),
          title: Text(respostas[i].titulo,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(respostas[i].conteudo,
              maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => Navigator.of(ctx).pop(respostas[i]),
        ),
      ),
    );
    if (escolhida != null) {
      _inputController.text = escolhida.conteudo;
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(chatProvider(widget.conversationId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Autoscroll quando chegam mensagens novas.
    if (estado.mensagens.length != _ultimaQtd) {
      _ultimaQtd = estado.mensagens.length;
      _rolarParaFim();
    }

    return Scaffold(
      backgroundColor: isDark ? _fundoEscuro : _fundoClaro,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.nomeContato ?? 'Conversa',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (widget.telefone != null)
              Text(widget.telefone!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Assumir conversa',
            icon: const Icon(Icons.support_agent_rounded),
            onPressed: () async {
              final userId = ref.read(authProvider).user?.id;
              if (userId == null) return;
              final ok = await ref
                  .read(chatProvider(widget.conversationId).notifier)
                  .assumir(userId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Conversa assumida por você.'
                      : 'Não foi possível assumir a conversa.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (estado.erro != null)
            MaterialBanner(
              backgroundColor: Colors.red.shade50,
              content: Text(
                estado.erro!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.red.shade800, fontSize: 12),
              ),
              actions: [
                TextButton(
                  onPressed: () => ref
                      .read(chatProvider(widget.conversationId).notifier)
                      .carregar(),
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
          Expanded(
            child: estado.carregando && estado.mensagens.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: estado.mensagens.length,
                    itemBuilder: (context, i) {
                      final m = estado.mensagens[i];
                      final anterior =
                          i > 0 ? estado.mensagens[i - 1] : null;
                      return Column(
                        children: [
                          if (_diaDiferente(anterior, m))
                            _SeparadorData(data: m.createdAt.toLocal()),
                          _Bolha(
                            mensagem: m,
                            isDark: isDark,
                            corMinha:
                                isDark ? _bolhaMinhaEscuro : _bolhaMinhaClaro,
                            tickAzul: _tickAzul,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _BarraInput(
            controller: _inputController,
            enviando: estado.enviando,
            onEnviar: _enviar,
            onRespostasRapidas: _abrirRespostasRapidas,
          ),
        ],
      ),
    );
  }

  bool _diaDiferente(Mensagem? anterior, Mensagem atual) {
    if (anterior == null) return true;
    final a = anterior.createdAt.toLocal();
    final b = atual.createdAt.toLocal();
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }
}

class _SeparadorData extends StatelessWidget {
  const _SeparadorData({required this.data});

  final DateTime data;

  String get _rotulo {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dia = DateTime(data.year, data.month, data.day);
    if (dia == hoje) return 'Hoje';
    if (dia == hoje.subtract(const Duration(days: 1))) return 'Ontem';
    return DateFormat('dd/MM/yyyy').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _rotulo,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Bolha extends StatelessWidget {
  const _Bolha({
    required this.mensagem,
    required this.isDark,
    required this.corMinha,
    required this.tickAzul,
  });

  final Mensagem mensagem;
  final bool isDark;
  final Color corMinha;
  final Color tickAzul;

  @override
  Widget build(BuildContext context) {
    if (mensagem.sistema) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            mensagem.previewTexto,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final minha = mensagem.minha;
    final corBolha = minha
        ? corMinha
        : (isDark ? const Color(0xFF202C33) : Colors.white);
    final corTexto = isDark || !minha && isDark
        ? Colors.white
        : Colors.black87;

    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: corBolha,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: Radius.circular(minha ? 10 : 2),
            bottomRight: Radius.circular(minha ? 2 : 10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mensagem.quotedMessagePreview != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: const Border(
                    left: BorderSide(color: Color(0xFF25D366), width: 3),
                  ),
                ),
                child: Text(
                  mensagem.quotedMessagePreview!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: corTexto.withValues(alpha: 0.7),
                  ),
                ),
              ),
            Text(
              mensagem.previewTexto,
              style: TextStyle(fontSize: 15, color: corTexto, height: 1.25),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(mensagem.createdAt.toLocal()),
                  style: TextStyle(
                    fontSize: 11,
                    color: corTexto.withValues(alpha: 0.55),
                  ),
                ),
                if (minha) ...[
                  const SizedBox(width: 3),
                  _Ticks(status: mensagem.status, azul: tickAzul),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ticks de status identicos ao WhatsApp:
/// relogio (pendente) → ✓ (enviada) → ✓✓ (entregue) → ✓✓ azul (lida/ouvida)
/// → circulo de erro (falhou).
class _Ticks extends StatelessWidget {
  const _Ticks({required this.status, required this.azul});

  final String status;
  final Color azul;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'pending':
        return Icon(Icons.schedule_rounded,
            size: 14, color: Colors.black.withValues(alpha: 0.4));
      case 'sent':
        return Icon(Icons.done_rounded,
            size: 15, color: Colors.black.withValues(alpha: 0.45));
      case 'delivered':
        return Icon(Icons.done_all_rounded,
            size: 15, color: Colors.black.withValues(alpha: 0.45));
      case 'read':
      case 'played':
        return Icon(Icons.done_all_rounded, size: 15, color: azul);
      case 'failed':
      case 'error':
        return const Icon(Icons.error_outline_rounded,
            size: 14, color: Colors.red);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BarraInput extends StatelessWidget {
  const _BarraInput({
    required this.controller,
    required this.enviando,
    required this.onEnviar,
    required this.onRespostasRapidas,
  });

  final TextEditingController controller;
  final bool enviando;
  final VoidCallback onEnviar;
  final VoidCallback onRespostasRapidas;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF202C33) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Respostas rápidas',
                      icon: const Icon(Icons.bolt_rounded),
                      color: const Color(0xFF25D366),
                      onPressed: onRespostasRapidas,
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Mensagem',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 46,
              height: 46,
              child: Material(
                color: const Color(0xFF25D366),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: enviando ? null : onEnviar,
                  child: enviando
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
