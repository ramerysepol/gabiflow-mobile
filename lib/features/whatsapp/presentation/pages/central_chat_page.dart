import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/central_models.dart';
import '../providers/central_providers.dart';
import 'contato_detalhes_page.dart';
import '../widgets/central_media_widgets.dart';
import '../widgets/central_visuals.dart';
import '../widgets/tags_editor_sheet.dart';
import '../widgets/template_picker_sheet.dart';
import '../widgets/transfer_sheet.dart';

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
    this.canal,
    this.contaCanal,
  });

  final int conversationId;
  final String? nomeContato;
  final String? telefone;
  final String? fotoUrl;
  final String? canal; // whatsapp | instagram | messenger | webchat
  final String? contaCanal; // channel_account_id ('app' distingue App de Site)

  @override
  ConsumerState<CentralChatPage> createState() => _CentralChatPageState();
}

class _CentralChatPageState extends ConsumerState<CentralChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sheetRespostasAberta = false;
  bool _telefoneCopiado = false;
  bool _nomeCopiado = false;
  Mensagem? _respondendo; // mensagem sendo citada na resposta

  String get _canalEfetivo =>
      canalEfetivo(widget.canal ?? 'whatsapp', widget.contaCanal);
  bool get _ehAppOuSite =>
      canalAppOuSite(widget.canal ?? 'whatsapp', widget.contaCanal);

  // Renderizar as bolhas so' depois da transicao de rota: construir a lista
  // (com midia, avatares...) no meio da animacao derrubava frames e as
  // mensagens "pipocavam" durante o slide.
  bool _transicaoConcluida = false;

  @override
  void initState() {
    super.initState();
    // Digitar "/" no campo vazio abre as respostas rapidas (como no WhatsApp).
    _inputController.addListener(_aoDigitarBarra);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final anim = ModalRoute.of(context)?.animation;
      if (anim == null || anim.isCompleted) {
        setState(() => _transicaoConcluida = true);
        return;
      }
      void aoTerminar(AnimationStatus status) {
        if (status != AnimationStatus.completed) return;
        anim.removeStatusListener(aoTerminar);
        if (mounted) setState(() => _transicaoConcluida = true);
      }

      anim.addStatusListener(aoTerminar);
    });
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

  /// Copia o telefone sem o DDI 55 (mesma regra do ChatHeader.tsx da web).
  Future<void> _copiarTelefone() async {
    if (widget.telefone == null) return;
    final digitos = widget.telefone!.replaceAll(RegExp(r'\D'), '');
    final semDdi = digitos.startsWith('55') ? digitos.substring(2) : digitos;
    await Clipboard.setData(ClipboardData(text: semDdi));
    if (!mounted) return;
    setState(() => _telefoneCopiado = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Telefone copiado!'),
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _telefoneCopiado = false);
    });
  }

  /// A conversa correspondente na lista carregada (pode ser null se veio por
  /// deep-link e a lista ainda nao tem o item).
  ConversaResumo? _conversaDaLista() {
    for (final c in ref.read(conversasProvider).conversas) {
      if (c.id == widget.conversationId) return c;
    }
    return null;
  }

  Future<void> _assumir() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    try {
      await ref
          .read(centralDataSourceProvider)
          .assumirConversa(widget.conversationId, userId);
      ref.read(conversasProvider.notifier).carregar(silencioso: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversa assumida por você.')),
      );
      setState(() {}); // esconde o banner
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível assumir: $e')),
        );
      }
    }
  }

  /// Copia o nome do contato — util quando a conversa vem do app/site, para
  /// localizar o estudante no backoffice (paridade com o ChatHeader.tsx da web).
  Future<void> _copiarNome() async {
    final nome = widget.nomeContato?.trim();
    if (nome == null || nome.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: nome));
    if (!mounted) return;
    setState(() => _nomeCopiado = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nome copiado!'),
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _nomeCopiado = false);
    });
  }

  Future<void> _selecionarTemplate() async {
    final escolhido = await TemplatePickerSheet.show(context);
    if (escolhido == null || !mounted) return;
    final ok = await ref
        .read(chatProvider(widget.conversationId).notifier)
        .enviarTemplateMeta(
          metaTemplateName: escolhido.templateName,
          metaTemplateLanguage: escolhido.language,
          templateVariables: escolhido.templateVariables,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Template enviado.'
              : 'Falha ao enviar template. Tente novamente.',
        ),
      ),
    );
  }

  Future<void> _enviar() async {
    final texto = _inputController.text;
    if (texto.trim().isEmpty) return;
    _inputController.clear();
    final ctx = _respondendo?.id;
    if (_respondendo != null) setState(() => _respondendo = null);
    await ref
        .read(chatProvider(widget.conversationId).notifier)
        .enviarTexto(texto, contextMessageId: (ctx != null && ctx > 0) ? ctx : null);
  }

  void _responderMensagem(Mensagem m) {
    setState(() => _respondendo = m);
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> _excluirMensagem(Mensagem m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir mensagem'),
        content: const Text(
            'A mensagem some da central. O destinatário continua vendo (o '
            'WhatsApp não permite apagar no aparelho dele).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true || m.id < 0) return;
    await ref
        .read(chatProvider(widget.conversationId).notifier)
        .excluir(m.id);
  }

  Future<void> _encaminharMensagem(Mensagem m) async {
    if (m.id < 0) return;
    final ds = ref.read(centralDataSourceProvider);
    // Escolhe uma conversa de destino entre as abertas.
    final conversas = ref.read(conversasProvider).conversas;
    final escolhida = await showModalBottomSheet<ConversaResumo>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Encaminhar para',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ...conversas
                .where((c) => c.id != widget.conversationId)
                .map((c) => ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.person_rounded, size: 20)),
                      title: Text(c.displayName),
                      subtitle: Text(c.lastMessage ?? '',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.of(ctx).pop(c),
                    )),
          ],
        ),
      ),
    );
    if (escolhida == null || !mounted) return;
    try {
      await ds.encaminharMensagem(widget.conversationId, m.id,
          paraConversa: escolhida.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Encaminhada para ${escolhida.displayName}.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao encaminhar: $e')));
      }
    }
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
                child: Icon(
                  Icons.insert_drive_file_rounded,
                  color: Colors.white,
                ),
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
            source: ImageSource.camera,
            imageQuality: 82,
            maxWidth: 1920,
          );
        case 'galeria':
          arquivo = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 82,
            maxWidth: 1920,
          );
        case 'video':
          tipo = 'video';
          arquivo = await picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 3),
          );
      }
      if (arquivo == null) return;
      caminho = arquivo.path;
      nome = arquivo.name;
    }
    if (caminho == null || !mounted) return;

    await ref
        .read(chatProvider(widget.conversationId).notifier)
        .enviarMidia(filePath: caminho, tipo: tipo, filename: nome);
  }

  Future<void> _transferirConversa() async {
    final r = await TransferSheet.mostrar(context);
    if (r == null || !mounted) return;
    try {
      await ref.read(centralDataSourceProvider).transferirConversa(
            widget.conversationId,
            paraUsuario: r.paraUsuario,
            paraDepartamento: r.paraDepartamento,
            motivo: r.motivo,
            notas: r.notas,
          );
      if (!mounted) return;
      final destino = r.nomeDestino ?? 'destino';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transferida para $destino.')),
      );
      if (context.canPop()) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Falha ao transferir: $e')));
      }
    }
  }

  Future<void> _agendarMensagem() async {
    final msgCtrl = TextEditingController();
    final now = DateTime.now();
    final data = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now.add(const Duration(hours: 1)),
    );
    if (data == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (hora == null || !mounted) return;
    final quando =
        DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agendar mensagem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Envio em ${DateFormat('dd/MM/yyyy HH:mm').format(quando)}'),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mensagem',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Agendar')),
        ],
      ),
    );
    if (ok != true || !mounted || msgCtrl.text.trim().isEmpty) return;
    try {
      await ref.read(centralDataSourceProvider).agendarMensagem(
            widget.conversationId,
            mensagem: msgCtrl.text.trim(),
            quando: quando,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Mensagem agendada para ${DateFormat('dd/MM HH:mm').format(quando)}.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao agendar: $e')));
      }
    }
  }

  Future<void> _exportarPdf() async {
    try {
      final url =
          await ref.read(centralDataSourceProvider).urlExportarPdf(widget.conversationId);
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o PDF.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao exportar: $e')));
      }
    }
  }

  void _usarSugestao(String s) {
    _inputController.text = s;
    _inputController.selection =
        TextSelection.collapsed(offset: _inputController.text.length);
  }

  Future<void> _sugestaoIA() async {
    // Sem dialog de loading separado (o pop dele empurrava a propria pagina
    // fora). Abre o sheet direto e carrega DENTRO dele com FutureBuilder.
    final future = ref
        .read(centralDataSourceProvider)
        .sugestoesIA(widget.conversationId);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          child: FutureBuilder<List<String>>(
            future: future,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final erro = snap.hasError;
              final sugestoes = snap.data ?? const <String>[];
              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text('Sugestões da IA',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ]),
                  ),
                  if (erro)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Não foi possível gerar sugestões agora.'),
                    )
                  else if (sugestoes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Sem sugestões no momento.'),
                    )
                  else
                    ...sugestoes.map((s) => Card(
                          child: ListTile(
                            title: Text(s),
                            trailing: const Icon(Icons.north_east_rounded,
                                size: 18),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _usarSugestao(s);
                            },
                          ),
                        )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _editarEtiquetas() async {
    final novas = await TagsEditorSheet.mostrar(context, widget.conversationId);
    if (novas == null || !mounted) return;
    // Atualiza a lista de conversas ao voltar (os chips refletem a mudanca).
    ref.read(conversasProvider.notifier).carregar(silencioso: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Etiquetas atualizadas.')),
    );
  }

  Future<void> _encerrarConversa() async {
    final notasCtrl = TextEditingController();
    String resolucao = 'resolved';
    const opcoes = [
      ('resolved', 'Resolvido'),
      ('unresolved', 'Não resolvido'),
      ('inactive', 'Inativo / sem retorno'),
    ];
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Encerrar atendimento'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resolução',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ...opcoes.map((o) => RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: o.$1,
                      groupValue: resolucao,
                      onChanged: (v) => setLocal(() => resolucao = v!),
                      title: Text(o.$2),
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: notasCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
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
              child: const Text('Encerrar'),
            ),
          ],
        ),
      ),
    );
    if (confirmar != true || !mounted) return;
    final motivoPorResolucao = {
      'resolved': 'Resolvido',
      'unresolved': 'Não resolvido',
      'inactive': 'Inativo / sem retorno',
    };
    try {
      await ref.read(centralDataSourceProvider).encerrarConversa(
            widget.conversationId,
            motivo: motivoPorResolucao[resolucao],
            resolucao: resolucao,
            notas: notasCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Conversa encerrada.')));
      if (context.canPop()) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Falha ao encerrar: $e')));
      }
    }
  }

  Future<void> _enviarAudio(String caminho) async {
    await ref
        .read(chatProvider(widget.conversationId).notifier)
        .enviarMidia(filePath: caminho, tipo: 'audio', filename: 'voz.m4a');
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
              onForegroundImageError: widget.fotoUrl != null
                  ? (_, __) {}
                  : null,
              child: const Icon(
                Icons.person_rounded,
                size: 20,
                color: Color(0xFF128C7E),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.nomeContato ?? 'Conversa',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Copiar nome: util p/ conversas do app/site (localizar o
                      // estudante no backoffice), como no ChatHeader.tsx da web.
                      if (_ehAppOuSite)
                        InkWell(
                          onTap: _copiarNome,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              _nomeCopiado
                                  ? Icons.check_rounded
                                  : Icons.copy_rounded,
                              size: 14,
                              color: _nomeCopiado
                                  ? const Color(0xFF25D366)
                                  : Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CanalBadge(_canalEfetivo, size: 11, comLabel: true),
                      if (widget.telefone != null &&
                          widget.telefone!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: GestureDetector(
                            onTap: _copiarTelefone,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.telefone!,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _telefoneCopiado
                                      ? Icons.check_rounded
                                      : Icons.copy_rounded,
                                  size: 12,
                                  color: _telefoneCopiado
                                      ? const Color(0xFF25D366)
                                      : Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (estado.janelaExpirada) ...[
                        const SizedBox(width: 6),
                        const Text(
                          'Janela expirada',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sugestão da IA',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: _sugestaoIA,
          ),
          IconButton(
            tooltip: 'Informações',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              final base = _conversaDaLista();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ContatoDetalhesPage(
                    conversationId: widget.conversationId,
                    base: base,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            onSelected: (acao) {
              switch (acao) {
                case 'etiquetas':
                  _editarEtiquetas();
                case 'agendar':
                  _agendarMensagem();
                case 'exportar':
                  _exportarPdf();
                case 'transferir':
                  _transferirConversa();
                case 'encerrar':
                  _encerrarConversa();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'etiquetas',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.label_outline_rounded),
                  title: Text('Etiquetas'),
                ),
              ),
              PopupMenuItem(
                value: 'agendar',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.schedule_send_rounded),
                  title: Text('Agendar mensagem'),
                ),
              ),
              PopupMenuItem(
                value: 'exportar',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.picture_as_pdf_rounded),
                  title: Text('Exportar PDF'),
                ),
              ),
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
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Builder(builder: (context) {
            final conv = _conversaDaLista();
            final meuId = ref.watch(authProvider).user?.id;
            // Mostra o convite a assumir quando a conversa nao esta atribuida a
            // mim (igual ao web: ao entrar, pergunta se quer assumir).
            final naoAtribuida = conv != null && conv.assignedTo != meuId;
            if (!naoAtribuida) return const SizedBox.shrink();
            return Material(
              color: const Color(0xFF25D366).withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent_rounded,
                        color: Color(0xFF128C7E), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        conv.assignedTo == null
                            ? 'Esta conversa ainda não foi assumida.'
                            : 'Atribuída a ${conv.assignedToName ?? 'outro atendente'}.',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    TextButton(
                      onPressed: _assumir,
                      child: const Text('Assumir'),
                    ),
                  ],
                ),
              ),
            );
          }),
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
            child: !_transicaoConcluida
                ? const SizedBox.expand()
                : estado.carregando && estado.mensagens.isEmpty
                ? const Center(child: CircularProgressIndicator())
                // Lista invertida (padrao de chat): ja abre ancorada na
                // ultima mensagem — sem pulo — e mensagens novas nao
                // arrastam a tela de quem esta lendo o historico.
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    itemCount: estado.mensagens.length,
                    itemBuilder: (context, i) {
                      final real = estado.mensagens.length - 1 - i;
                      final m = estado.mensagens[real];
                      final anterior = real > 0
                          ? estado.mensagens[real - 1]
                          : null;
                      return Column(
                        children: [
                          if (_diaDiferente(anterior, m))
                            _SeparadorData(data: m.createdAt.toLocal()),
                          _Bolha(
                            mensagem: m,
                            isDark: isDark,
                            corMinha: isDark
                                ? _bolhaMinhaEscuro
                                : _bolhaMinhaClaro,
                            tickAzul: _tickAzul,
                            onResponder: _responderMensagem,
                            onEncaminhar: _encaminharMensagem,
                            onExcluir: m.minha ? _excluirMensagem : null,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (!estado.janelaExpirada &&
              estado.janela?.status == 'expiring_soon')
            Container(
              width: double.infinity,
              color: Colors.amber.withValues(alpha: 0.18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: Color(0xFFB45309),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Janela expira em breve',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (estado.janelaExpirada)
            Container(
              width: double.infinity,
              color: Colors.amber.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Color(0xFFB45309),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Janela de 24h expirada. Use um template para enviar '
                      'mensagem.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                    ),
                  ),
                ],
              ),
            ),
          if (_respondendo != null)
            Container(
              width: double.infinity,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Container(width: 3, height: 34, color: const Color(0xFF25D366)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _respondendo!.minha ? 'Você' : 'Contato',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF25D366)),
                        ),
                        Text(
                          _respondendo!.previewTexto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => setState(() => _respondendo = null),
                  ),
                ],
              ),
            ),
          estado.janelaExpirada
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton.icon(
                      onPressed: _selecionarTemplate,
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('Selecionar Template'),
                    ),
                  ),
                )
              : _BarraInput(
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

  Future<void> _excluirResposta(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir resposta rápida'),
        content: const Text('Tem certeza que deseja excluir?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(centralDataSourceProvider).excluirRespostaRapida(id);
      ref.invalidate(respostasRapidasProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao excluir: $e')));
      }
    }
  }

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Falha ao cadastrar: $e')));
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Falha ao carregar respostas rápidas.\n$e',
                  textAlign: TextAlign.center,
                ),
              ),
              data: (lista) {
                final filtradas = _busca.isEmpty
                    ? lista
                    : lista
                          .where(
                            (r) =>
                                r.titulo.toLowerCase().contains(_busca) ||
                                r.conteudo.toLowerCase().contains(_busca),
                          )
                          .toList();
                if (filtradas.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma resposta encontrada.'),
                  );
                }
                return ListView.builder(
                  itemCount: filtradas.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF25D366),
                    ),
                    title: Text(
                      '/${filtradas[i].titulo}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      filtradas[i].conteudo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Colors.redAccent),
                      tooltip: 'Excluir',
                      onPressed: () => _excluirResposta(filtradas[i].id),
                    ),
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
    this.onResponder,
    this.onEncaminhar,
    this.onExcluir,
  });

  final Mensagem mensagem;
  final bool isDark;
  final Color corMinha;
  final Color tickAzul;
  final void Function(Mensagem)? onResponder;
  final void Function(Mensagem)? onEncaminhar;
  final void Function(Mensagem)? onExcluir;

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
    // Fundos das duas bolhas (verde-claro/branco no tema claro,
    // verde-escuro/cinza-escuro no tema escuro) sempre contrastam do mesmo
    // jeito com preto/branco — a cor do texto só depende do tema.
    final corTexto = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      onLongPress: () => _abrirMenuMensagem(context, mensagem),
      child: Align(
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
      ),
    );
  }

  void _abrirMenuMensagem(BuildContext context, Mensagem mensagem) {
    final ehOtimista = mensagem.id < 0;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onResponder != null && !ehOtimista)
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: const Text('Responder'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onResponder!(mensagem);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copiar mensagem'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await Clipboard.setData(
                  ClipboardData(text: mensagem.previewTexto),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mensagem copiada!'),
                      duration: Duration(milliseconds: 1500),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            if (onEncaminhar != null && !ehOtimista)
              ListTile(
                leading: const Icon(Icons.forward_rounded),
                title: const Text('Encaminhar'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onEncaminhar!(mensagem);
                },
              ),
            if (onExcluir != null && !ehOtimista)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: const Text('Excluir',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onExcluir!(mensagem);
                },
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
        return Icon(
          Icons.schedule_rounded,
          size: 14,
          color: Colors.black.withValues(alpha: 0.4),
        );
      case 'sent':
        return Icon(
          Icons.done_rounded,
          size: 15,
          color: Colors.black.withValues(alpha: 0.45),
        );
      case 'delivered':
        return Icon(
          Icons.done_all_rounded,
          size: 15,
          color: Colors.black.withValues(alpha: 0.45),
        );
      case 'read':
      case 'played':
        return Icon(Icons.done_all_rounded, size: 15, color: azul);
      case 'failed':
      case 'error':
        return const Icon(
          Icons.error_outline_rounded,
          size: 14,
          color: Colors.red,
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permita o acesso ao microfone para gravar áudio.'),
          ),
        );
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
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.fiber_manual_record_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tempo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Mensagem',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
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
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  )
                : GestureDetector(
                    onLongPressStart: (_) => _comecarGravacao(),
                    onLongPressEnd: (_) => _pararGravacao(enviar: true),
                    onLongPressCancel: () => _pararGravacao(enviar: false),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Segure o microfone para gravar o áudio.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _gravando ? 56 : 46,
                      height: _gravando ? 56 : 46,
                      decoration: BoxDecoration(
                        color: _gravando ? Colors.red : const Color(0xFF25D366),
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
