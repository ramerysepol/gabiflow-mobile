import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/central_models.dart';
import '../providers/central_providers.dart';
import '../widgets/central_media_widgets.dart';

/// Chat de uma conversa — visual familiar do WhatsApp: fundo bege/escuro,
/// bolhas verde (enviada) e branca (recebida), ticks de status e separadores
/// de data. Toda regra (janela 24h, provedor, lida) vem do servidor.
class CentralChatPage extends ConsumerStatefulWidget {
  const CentralChatPage({
    super.key,
    required this.conversationId,
    this.nomeContato,
    this.telefone,
    this.fotoUrl,
  });

  final int conversationId;
  final String? nomeContato;
  final String? telefone;
  final String? fotoUrl;

  @override
  ConsumerState<CentralChatPage> createState() => _CentralChatPageState();
}

class _CentralChatPageState extends ConsumerState<CentralChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sheetRespostasAberta = false;

  @override
  void initState() {
    super.initState();
    // Digitar "/" no campo vazio abre as respostas rapidas (como no WhatsApp).
    _inputController.addListener(_aoDigitarBarra);
  }

  void _aoDigitarBarra() {
    if (_inputController.text != '/' || _sheetRespostasAberta) return;
    // O listener dispara no meio do frame de layout do teclado; abrir o
    // sheet sincronamente corrompe a arvore (RenderBox not laid out).
    _sheetRespostasAberta = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _sheetRespostasAberta = false;
        return;
      }
      _abrirRespostasRapidas(limparBarra: true, jaMarcado: true);
    });
  }

  // Paleta WhatsApp (proposital: familiaridade acima do tema do tenant).
  static const _fundoClaro = Color(0xFFECE5DD);
  static const _fundoEscuro = Color(0xFF0B141A);
  static const _bolhaMinhaClaro = Color(0xFFDCF8C6);
  static const _bolhaMinhaEscuro = Color(0xFF005C4B);
  static const _tickAzul = Color(0xFF53BDEB);

  @override
  void dispose() {
    _inputController.removeListener(_aoDigitarBarra);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _inputController.text;
    if (texto.trim().isEmpty) return;
    _inputController.clear();
    await ref
        .read(chatProvider(widget.conversationId).notifier)
        .enviarTexto(texto);
  }

  Future<void> _abrirAnexos() async {
    final escolha = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE91E63),
                child: Icon(Icons.photo_camera_rounded, color: Colors.white),
              ),
              title: const Text('Câmera'),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF9C27B0),
                child: Icon(Icons.photo_rounded, color: Colors.white),
              ),
              title: const Text('Galeria'),
              onTap: () => Navigator.of(ctx).pop('galeria'),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF3F51B5),
                child: Icon(Icons.videocam_rounded, color: Colors.white),
              ),
              title: const Text('Vídeo'),
              onTap: () => Navigator.of(ctx).pop('video'),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF607D8B),
                child:
                    Icon(Icons.insert_drive_file_rounded, color: Colors.white),
              ),
              title: const Text('Documento'),
              onTap: () => Navigator.of(ctx).pop('documento'),
            ),
          ],
        ),
      ),
    );
    if (escolha == null || !mounted) return;

    String? caminho;
    String? nome;
    var tipo = 'image';

    if (escolha == 'documento') {
      final resultado = await FilePicker.platform.pickFiles();
      final f = resultado?.files.single;
      if (f?.path == null) return;
      caminho = f!.path;
      nome = f.name;
      tipo = 'document';
    } else {
      final picker = ImagePicker();
      XFile? arquivo;
      switch (escolha) {
        case 'camera':
          arquivo = await picker.pickImage(
              source: ImageSource.camera, imageQuality: 82, maxWidth: 1920);
        case 'galeria':
          arquivo = await picker.pickImage(
              source: ImageSource.gallery, imageQuality: 82, maxWidth: 1920);
        case 'video':
          tipo = 'video';
          arquivo = await picker.pickVideo(
              source: ImageSource.gallery,
              maxDuration: const Duration(minutes: 3));
      }
      if (arquivo == null) return;
      caminho = arquivo.path;
      nome = arquivo.name;
    }
    if (caminho == null || !mounted) return;

    await ref.read(chatProvider(widget.conversationId).notifier).enviarMidia(
          filePath: caminho,
          tipo: tipo,
          filename: nome,
        );
  }

  Future<void> _transferirConversa() async {
    final ds = ref.read(centralDataSourceProvider);
    List<AtendenteResumo> atendentes;
    try {
      atendentes = await ds.listarAtendentes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha ao carregar atendentes: $e')));
      }
      return;
    }
    if (!mounted) return;
    final meuId = ref.read(authProvider).user?.id;
    final opcoes = atendentes.where((a) => a.id != meuId).toList();
    if (opcoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nenhum outro atendente disponível.')));
      return;
    }
    final escolhido = await showModalBottomSheet<AtendenteResumo>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('Transferir para',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ...opcoes.map((a) => ListTile(
                  leading: const CircleAvatar(
                      child: Icon(Icons.person_rounded, size: 20)),
                  title: Text(a.nome),
                  onTap: () => Navigator.of(ctx).pop(a),
                )),
          ],
        ),
      ),
    );
    if (escolhido == null || !mounted) return;
    try {
      await ds.transferirConversa(widget.conversationId,
          paraUsuario: escolhido.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transferida para ${escolhido.nome}.')));
      if (context.canPop()) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao transferir: $e')));
      }
    }
  }

  Future<void> _encerrarConversa() async {
    final motivoCtrl = TextEditingController(text: 'Resolvido');
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar conversa'),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: motivoCtrl,
            decoration: const InputDecoration(
                labelText: 'Motivo', border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Encerrar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await ref
          .read(centralDataSourceProvider)
          .encerrarConversa(widget.conversationId, motivo: motivoCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversa encerrada.')));
      if (context.canPop()) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao encerrar: $e')));
      }
    }
  }

  Future<void> _arquivarConversa() async {
    try {
      await ref
          .read(centralDataSourceProvider)
          .arquivarConversa(widget.conversationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversa arquivada.')));
      if (context.canPop()) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao arquivar: $e')));
      }
    }
  }

  Future<void> _enviarAudio(String caminho) async {
    await ref.read(chatProvider(widget.conversationId).notifier).enviarMidia(
          filePath: caminho,
          tipo: 'audio',
          filename: 'voz.m4a',
        );
  }

  Future<void> _abrirRespostasRapidas({
    bool limparBarra = false,
    bool jaMarcado = false,
  }) async {
    if (!jaMarcado && _sheetRespostasAberta) return;
    _sheetRespostasAberta = true;
    // Fecha o teclado antes: com ele aberto o sheet nasce escondido atras
    // do teclado e a tela parece travada (so a barreira do modal visivel).
    FocusManager.instance.primaryFocus?.unfocus();
    final escolhida = await showModalBottomSheet<RespostaRapida>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const _RespostasRapidasSheet(),
      ),
    );
    _sheetRespostasAberta = false;
    if (!mounted) return;
    if (escolhida != null) {
      _inputController.text = escolhida.conteudo;
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );
    } else if (limparBarra && _inputController.text == '/') {
      _inputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(chatProvider(widget.conversationId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _fundoEscuro : _fundoClaro,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.2),
              foregroundImage:
                  (widget.fotoUrl != null && widget.fotoUrl!.startsWith('http'))
                      ? NetworkImage(widget.fotoUrl!)
                      : null,
              onForegroundImageError:
                  widget.fotoUrl != null ? (_, __) {} : null,
              child: const Icon(Icons.person_rounded,
                  size: 20, color: Color(0xFF128C7E)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nomeContato ?? 'Conversa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  if (widget.telefone != null)
                    Text(widget.telefone!,
                        style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
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
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            onSelected: (acao) {
              switch (acao) {
                case 'transferir':
                  _transferirConversa();
                case 'encerrar':
                  _encerrarConversa();
                case 'arquivar':
                  _arquivarConversa();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'transferir',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.swap_horiz_rounded),
                  title: Text('Transferir conversa'),
                ),
              ),
              PopupMenuItem(
                value: 'encerrar',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle_outline_rounded),
                  title: Text('Encerrar conversa'),
                ),
              ),
              PopupMenuItem(
                value: 'arquivar',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Arquivar'),
                ),
              ),
            ],
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
                // Lista invertida (padrao de chat): ja abre ancorada na
                // ultima mensagem — sem pulo — e mensagens novas nao
                // arrastam a tela de quem esta lendo o historico.
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: estado.mensagens.length,
                    itemBuilder: (context, i) {
                      final real = estado.mensagens.length - 1 - i;
                      final m = estado.mensagens[real];
                      final anterior =
                          real > 0 ? estado.mensagens[real - 1] : null;
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
            onAnexar: _abrirAnexos,
            onEnviarAudio: _enviarAudio,
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

/// Sheet de respostas rapidas: busca, atalhos e cadastro — padrao WhatsApp
/// (abre tambem ao digitar "/" no campo de mensagem).
class _RespostasRapidasSheet extends ConsumerStatefulWidget {
  const _RespostasRapidasSheet();

  @override
  ConsumerState<_RespostasRapidasSheet> createState() =>
      _RespostasRapidasSheetState();
}

class _RespostasRapidasSheetState
    extends ConsumerState<_RespostasRapidasSheet> {
  String _busca = '';

  Future<void> _cadastrar() async {
    final atalhoCtrl = TextEditingController();
    final conteudoCtrl = TextEditingController();
    final salvar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova resposta rápida'),
        content: SizedBox(
          width: 320,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: atalhoCtrl,
              decoration: const InputDecoration(
                labelText: 'Atalho',
                hintText: 'ex.: saudacao',
                prefixText: '/',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: conteudoCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Mensagem',
                hintText: 'Texto que será enviado',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (salvar != true) return;
    final atalho = atalhoCtrl.text.trim();
    final conteudo = conteudoCtrl.text.trim();
    if (atalho.isEmpty || conteudo.isEmpty) return;
    try {
      await ref
          .read(centralDataSourceProvider)
          .criarRespostaRapida(atalho: atalho, conteudo: conteudo);
      ref.invalidate(respostasRapidasProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resposta "/$atalho" cadastrada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao cadastrar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final respostas = ref.watch(respostasRapidasProvider);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: false,
                    onChanged: (v) => setState(() => _busca = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Buscar resposta rápida',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Dimensao fixa: sem ela o botao recebia BoxConstraints de
                // largura infinita e derrubava o layout do sheet inteiro.
                SizedBox(
                  width: 104,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: _cadastrar,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Nova'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: respostas.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Falha ao carregar respostas rápidas.\n$e',
                    textAlign: TextAlign.center),
              ),
              data: (lista) {
                final filtradas = _busca.isEmpty
                    ? lista
                    : lista
                        .where((r) =>
                            r.titulo.toLowerCase().contains(_busca) ||
                            r.conteudo.toLowerCase().contains(_busca))
                        .toList();
                if (filtradas.isEmpty) {
                  return const Center(
                      child: Text('Nenhuma resposta encontrada.'));
                }
                return ListView.builder(
                  itemCount: filtradas.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: const Icon(Icons.bolt_rounded,
                        color: Color(0xFF25D366)),
                    title: Text('/${filtradas[i].titulo}',
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(filtradas[i].conteudo,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.of(ctx).pop(filtradas[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
            MidiaConteudo(mensagem: mensagem, corTexto: corTexto),
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

class _BarraInput extends StatefulWidget {
  const _BarraInput({
    required this.controller,
    required this.enviando,
    required this.onEnviar,
    required this.onRespostasRapidas,
    required this.onAnexar,
    required this.onEnviarAudio,
  });

  final TextEditingController controller;
  final bool enviando;
  final VoidCallback onEnviar;
  final VoidCallback onRespostasRapidas;
  final VoidCallback onAnexar;
  final ValueChanged<String> onEnviarAudio;

  @override
  State<_BarraInput> createState() => _BarraInputState();
}

class _BarraInputState extends State<_BarraInput> {
  final AudioRecorder _gravador = AudioRecorder();
  bool _temTexto = false;
  bool _gravando = false;
  int _segundos = 0;
  Timer? _cronometro;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_aoDigitar);
  }

  void _aoDigitar() {
    final tem = widget.controller.text.trim().isNotEmpty;
    if (tem != _temTexto) setState(() => _temTexto = tem);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_aoDigitar);
    _cronometro?.cancel();
    _gravador.dispose();
    super.dispose();
  }

  Future<void> _comecarGravacao() async {
    if (!await _gravador.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Permita o acesso ao microfone para gravar áudio.')));
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final caminho =
        '${dir.path}/voz_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _gravador.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
      path: caminho,
    );
    if (!mounted) return;
    setState(() {
      _gravando = true;
      _segundos = 0;
    });
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _segundos++);
    });
  }

  Future<void> _pararGravacao({required bool enviar}) async {
    _cronometro?.cancel();
    final caminho = await _gravador.stop();
    if (!mounted) return;
    setState(() => _gravando = false);
    // Gravacao muito curta (toque acidental) e descartada.
    if (enviar && caminho != null && _segundos >= 1) {
      widget.onEnviarAudio(caminho);
    }
  }

  String get _tempo {
    final m = (_segundos ~/ 60).toString().padLeft(2, '0');
    final s = (_segundos % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

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
                child: _gravando
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.fiber_manual_record_rounded,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Text(_tempo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Text(
                              'Solte para enviar',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Respostas rápidas',
                            icon: const Icon(Icons.bolt_rounded),
                            color: const Color(0xFF25D366),
                            onPressed: widget.onRespostasRapidas,
                          ),
                          Expanded(
                            child: TextField(
                              controller: widget.controller,
                              minLines: 1,
                              maxLines: 5,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Mensagem',
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Anexar',
                            icon: const Icon(Icons.attach_file_rounded),
                            color: Colors.grey,
                            onPressed: widget.onAnexar,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 6),
            // Texto digitado → botao enviar; campo vazio → microfone
            // (segurar grava, soltar envia — igual ao WhatsApp).
            _temTexto
                ? SizedBox(
                    width: 46,
                    height: 46,
                    child: Material(
                      color: const Color(0xFF25D366),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.enviando ? null : widget.onEnviar,
                        child: widget.enviando
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
                  )
                : GestureDetector(
                    onLongPressStart: (_) => _comecarGravacao(),
                    onLongPressEnd: (_) => _pararGravacao(enviar: true),
                    onLongPressCancel: () => _pararGravacao(enviar: false),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Segure o microfone para gravar o áudio.'),
                        duration: Duration(seconds: 2),
                      ),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _gravando ? 56 : 46,
                      height: _gravando ? 56 : 46,
                      decoration: BoxDecoration(
                        color: _gravando
                            ? Colors.red
                            : const Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: _gravando ? 28 : 22,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
