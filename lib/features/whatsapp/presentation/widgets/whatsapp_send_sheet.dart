import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/friendly_error.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../constituents/data/models/constituent_extras.dart';
import '../../../constituents/data/models/constituent_model.dart';
import '../../data/models/whatsapp_models.dart';
import '../providers/whatsapp_providers.dart';

/// Sheet de envio de WhatsApp — paridade com o modal do desktop:
/// mensagem livre, templates Meta ({{1}}) e templates Z-API ({{nome}}),
/// individual (munícipe) ou em massa (filtros ativos da lista).
class WhatsAppSendSheet extends ConsumerStatefulWidget {
  const WhatsAppSendSheet._({
    this.destinatario,
    this.filtros,
    this.search,
    this.totalEstimado,
  });

  /// Envio individual para um munícipe.
  final ConstituentModel? destinatario;

  /// Envio em massa: filtros ativos da lista.
  final ConstituentFilters? filtros;
  final String? search;
  final int? totalEstimado;

  bool get emMassa => destinatario == null;

  static Future<void> show(BuildContext context, ConstituentModel c) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => WhatsAppSendSheet._(destinatario: c),
      );

  static Future<void> showBulk(
    BuildContext context, {
    required ConstituentFilters filtros,
    String? search,
    int? totalEstimado,
  }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => WhatsAppSendSheet._(
          filtros: filtros,
          search: search,
          totalEstimado: totalEstimado,
        ),
      );

  @override
  ConsumerState<WhatsAppSendSheet> createState() => _WhatsAppSendSheetState();
}

/// Canal/tipo de envio escolhido na primeira etapa.
enum _Canal { texto, meta, local }

class _WhatsAppSendSheetState extends ConsumerState<WhatsAppSendSheet> {
  _Canal? _canal;
  MetaTemplate? _templateMeta;
  final Set<int> _templatesLocais = {}; // >1 = rotação anti-bloqueio (massa)
  LocalTemplate? _templateLocalIndividual;

  final _textoLivreController = TextEditingController();

  /// Individual: valores resolvidos e editáveis por variável.
  final Map<String, TextEditingController> _valoresVariaveis = {};

  /// Massa: mapeamento variável → campo do munícipe ou texto fixo.
  final Map<String, String> _mapCampo = {};
  final Map<String, TextEditingController> _mapFixo = {};

  int _intervaloSegundos = 3;
  bool _enviando = false;

  /// URL pública da mídia do header (template Meta com imagem).
  String? _headerMediaUrl;
  bool _uploadingMedia = false;

  @override
  void dispose() {
    _textoLivreController.dispose();
    for (final c in _valoresVariaveis.values) {
      c.dispose();
    }
    for (final c in _mapFixo.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Resolução de variáveis (mesmos defaults do desktop) ──────────────────

  String _campoDefault(String variavel) {
    final v = variavel.toLowerCase();
    if (v == '1' || v == 'nome' || v == 'primeiro_nome') return 'primeiro_nome';
    const diretos = [
      'nome_completo',
      'telefone',
      'email',
      'cidade',
      'estado',
      'bairro',
    ];
    if (diretos.contains(v)) return v;
    if (v == 'data' || v == 'data_hoje') return 'data_hoje';
    return 'nome_completo';
  }

  String _valorDoCampo(String campo, ConstituentModel c) {
    final agora = DateTime.now();
    switch (campo) {
      case 'primeiro_nome':
        return c.nome.trim().split(RegExp(r'\s+')).first;
      case 'nome_completo':
        return c.nome.trim();
      case 'telefone':
        return c.telefone ?? c.whatsapp ?? '';
      case 'email':
        return c.email ?? '';
      case 'cidade':
        return c.cidade ?? '';
      case 'estado':
        return c.estado ?? '';
      case 'bairro':
        return c.bairro ?? '';
      case 'data_hoje':
        return '${agora.day.toString().padLeft(2, '0')}/'
            '${agora.month.toString().padLeft(2, '0')}/${agora.year}';
      case 'dia':
        return agora.day.toString().padLeft(2, '0');
      case 'mes':
        return agora.month.toString().padLeft(2, '0');
      case 'ano':
        return agora.year.toString();
      default:
        return '';
    }
  }

  List<String> get _variaveisAtivas {
    if (_canal == _Canal.meta) return _templateMeta?.variaveis ?? const [];
    if (_canal == _Canal.local) {
      if (!widget.emMassa) return _templateLocalIndividual?.variaveis ?? const [];
      final templates = ref
              .read(whatsappTemplatesProvider)
              .valueOrNull
              ?.local
              .where((t) => _templatesLocais.contains(t.id)) ??
          const Iterable<LocalTemplate>.empty();
      final uniao = <String>{};
      for (final t in templates) {
        uniao.addAll(t.variaveis);
      }
      final lista = uniao.toList()..sort();
      return lista;
    }
    return const [];
  }

  void _prepararVariaveis() {
    final vars = _variaveisAtivas;
    if (widget.emMassa) {
      for (final v in vars) {
        _mapCampo.putIfAbsent(v, () => _campoDefault(v));
        _mapFixo.putIfAbsent(v, () => TextEditingController());
      }
    } else {
      for (final v in vars) {
        _valoresVariaveis.putIfAbsent(
          v,
          () => TextEditingController(
            text: _valorDoCampo(_campoDefault(v), widget.destinatario!),
          ),
        );
      }
    }
  }

  String _preview(String texto) {
    var out = texto;
    for (final v in _variaveisAtivas) {
      String valor;
      if (widget.emMassa) {
        final campo = _mapCampo[v] ?? _campoDefault(v);
        valor = campo == '_fixo'
            ? (_mapFixo[v]?.text ?? '')
            : '‹${_rotuloCampo(campo)}›';
      } else {
        valor = _valoresVariaveis[v]?.text ?? '';
      }
      out = out.replaceAll(RegExp('\\{\\{\\s*$v\\s*\\}\\}'), valor);
    }
    return out;
  }

  String _rotuloCampo(String campo) {
    for (final (key, label) in camposVariavel) {
      if (key == campo) return label;
    }
    return campo;
  }

  Future<void> _escolherImagem() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (picked == null) return;
      setState(() => _uploadingMedia = true);
      final url = await ref
          .read(whatsappDataSourceProvider)
          .uploadMedia(picked.path);
      if (!mounted) return;
      setState(() => _headerMediaUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Falha ao enviar imagem. ${mensagemAmigavel(e)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  // ── Envio ────────────────────────────────────────────────────────────────

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final ds = ref.read(whatsappDataSourceProvider);
    try {
      if (!widget.emMassa) {
        final c = widget.destinatario!;
        final phone = c.whatsapp ?? c.telefone ?? '';
        final variables = {
          for (final v in _variaveisAtivas) v: _valoresVariaveis[v]?.text ?? '',
        };
        switch (_canal!) {
          case _Canal.texto:
            await ds.sendIndividual(
              tipo: 'texto',
              phone: phone,
              message: _textoLivreController.text.trim(),
            );
          case _Canal.meta:
            await ds.sendIndividual(
              tipo: 'meta',
              phone: phone,
              templateName: _templateMeta!.templateName,
              language: _templateMeta!.language,
              variables: variables,
              headerType: _headerTypeParaEnvio,
              headerUrl: _headerTypeParaEnvio != null ? _headerMediaUrl : null,
            );
          case _Canal.local:
            await ds.sendIndividual(
              tipo: 'local',
              phone: phone,
              templateId: _templateLocalIndividual!.id,
              variables: variables,
            );
        }
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mensagem enviada para ${c.nome}')),
        );
      } else {
        final mapeamento = <String, MapeamentoVariavel>{
          for (final v in _variaveisAtivas)
            v: (_mapCampo[v] ?? _campoDefault(v)) == '_fixo'
                ? MapeamentoVariavel.fixo(_mapFixo[v]?.text ?? '')
                : MapeamentoVariavel.campo(_mapCampo[v] ?? _campoDefault(v)),
        };
        final campaignId = await ds.sendBulk(
          tipo: _canal == _Canal.meta ? 'meta' : 'local',
          templateName: _templateMeta?.templateName,
          language: _templateMeta?.language,
          templateIds:
              _canal == _Canal.local ? _templatesLocais.toList() : null,
          mapeamento: mapeamento,
          filtros: widget.filtros ?? ConstituentFilters.vazios,
          search: widget.search,
          intervaloSegundos: _intervaloSegundos,
          headerType: _headerTypeParaEnvio,
          headerUrl: _headerTypeParaEnvio != null ? _headerMediaUrl : null,
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        context.push('/home/constituents/envio/$campaignId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemAmigavel(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  bool get _prontoParaEnviar {
    if (_canal == null) return false;
    switch (_canal!) {
      case _Canal.texto:
        return _textoLivreController.text.trim().isNotEmpty;
      case _Canal.meta:
        if (_templateMeta == null) return false;
        // Template com imagem no cabeçalho exige a imagem anexada
        if (_templateMeta!.headerFormat == 'IMAGE' &&
            _headerMediaUrl == null) {
          return false;
        }
        return true;
      case _Canal.local:
        return widget.emMassa
            ? _templatesLocais.isNotEmpty
            : _templateLocalIndividual != null;
    }
  }

  String? get _headerTypeParaEnvio =>
      _canal == _Canal.meta && _templateMeta?.headerFormat == 'IMAGE'
          ? 'image'
          : null;

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(whatsappConfigProvider);
    final templatesAsync = ref.watch(whatsappTemplatesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return configAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _MensagemCentral(
            icone: Icons.wifi_off_rounded,
            titulo: 'Não foi possível carregar',
            subtitulo: 'Verifique sua conexão e tente novamente.',
          ),
          data: (config) {
            if (!config.algumAtivo) {
              return const _MensagemCentral(
                icone: Icons.chat_outlined,
                titulo: 'WhatsApp não configurado',
                subtitulo:
                    'Configure a Meta API ou a Z-API nas configurações do '
                    'gabinete (desktop) para enviar mensagens.',
              );
            }
            return templatesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) {
                // 403 não é problema de rede: o perfil não tem a permissão
                // de templates — dizer a verdade evita parecer defeito.
                final semPermissao =
                    e is DioException && e.response?.statusCode == 403;
                if (semPermissao) {
                  return const _MensagemCentral(
                    icone: Icons.lock_outline_rounded,
                    titulo: 'Envio pelo gabinete indisponível',
                    subtitulo:
                        'Seu perfil não tem permissão para mensagens '
                        'oficiais. Use a opção "Abrir no WhatsApp" ou fale '
                        'com o administrador do gabinete.',
                  );
                }
                return const _MensagemCentral(
                  icone: Icons.wifi_off_rounded,
                  titulo: 'Não foi possível carregar os templates',
                  subtitulo: 'Verifique sua conexão e tente novamente.',
                );
              },
              data: (templates) => _conteudo(
                context,
                scrollController,
                config,
                templates,
              ),
            );
          },
        );
      },
    );
  }

  Widget _conteudo(
    BuildContext context,
    ScrollController scroll,
    WhatsAppConfig config,
    WhatsAppTemplates templates,
  ) {
    _prepararVariaveis();

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sm,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      children: [
        // Cabeçalho
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.chat_rounded,
                  color: Color(0xFF128C7E), size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.emMassa ? 'Envio em massa' : 'Enviar WhatsApp',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    widget.emMassa
                        ? _resumoFiltros()
                        : widget.destinatario!.nome,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Canal
        Text('COMO ENVIAR', style: AppTextStyles.eyebrow(context)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            if (!widget.emMassa)
              ChoiceChip(
                label: const Text('Mensagem livre'),
                selected: _canal == _Canal.texto,
                onSelected: (_) => setState(() => _canal = _Canal.texto),
              ),
            if (config.meta)
              ChoiceChip(
                label: const Text('Template Meta'),
                selected: _canal == _Canal.meta,
                onSelected: (_) => setState(() => _canal = _Canal.meta),
              ),
            if (config.zapi)
              ChoiceChip(
                label: const Text('Template Z-API'),
                selected: _canal == _Canal.local,
                onSelected: (_) => setState(() => _canal = _Canal.local),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Conteúdo por canal
        if (_canal == _Canal.texto) ...[
          Text('MENSAGEM', style: AppTextStyles.eyebrow(context)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _textoLivreController,
            maxLines: 5,
            maxLength: 4000,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Escreva a mensagem…',
            ),
          ),
        ],

        if (_canal == _Canal.meta) ...[
          Text('TEMPLATE APROVADO', style: AppTextStyles.eyebrow(context)),
          const SizedBox(height: AppSpacing.sm),
          if (templates.meta.isEmpty)
            const _AvisoInline(
                'Nenhum template Meta aprovado. Crie e aprove templates no desktop.'),
          ...templates.meta.map(
            (t) => _TemplateTile(
              titulo: t.nome,
              texto: t.texto,
              selecionado: _templateMeta?.templateName == t.templateName,
              desabilitado: !t.midiaSuportadaNoApp,
              rodape: !t.midiaSuportadaNoApp
                  ? 'Header de ${t.headerFormat == 'VIDEO' ? 'vídeo' : 'documento'} — envie pelo desktop'
                  : t.headerFormat == 'IMAGE'
                      ? '📷 Pede uma imagem no cabeçalho'
                      : null,
              onTap: !t.midiaSuportadaNoApp
                  ? null
                  : () => setState(() {
                        _templateMeta = t;
                        _headerMediaUrl = null;
                        _valoresVariaveis.clear();
                        _mapCampo.clear();
                      }),
            ),
          ),
        ],

        // Mídia do cabeçalho (template Meta com imagem)
        if (_canal == _Canal.meta &&
            _templateMeta?.headerFormat == 'IMAGE') ...[
          const SizedBox(height: AppSpacing.lg),
          Text('IMAGEM DO CABEÇALHO', style: AppTextStyles.eyebrow(context)),
          const SizedBox(height: AppSpacing.sm),
          if (_headerMediaUrl == null)
            OutlinedButton.icon(
              onPressed: _uploadingMedia ? null : _escolherImagem,
              icon: _uploadingMedia
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_rounded),
              label: Text(
                  _uploadingMedia ? 'Enviando imagem…' : 'Adicionar imagem'),
            )
          else
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.network(
                    _headerMediaUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      child: const Icon(Icons.image_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(child: Text('Imagem pronta para envio')),
                IconButton(
                  tooltip: 'Trocar imagem',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _uploadingMedia ? null : _escolherImagem,
                ),
                IconButton(
                  tooltip: 'Remover',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() => _headerMediaUrl = null),
                ),
              ],
            ),
        ],

        if (_canal == _Canal.local) ...[
          Text(
            widget.emMassa
                ? 'TEMPLATES (2+ = RODÍZIO ANTI-BLOQUEIO)'
                : 'TEMPLATE',
            style: AppTextStyles.eyebrow(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (templates.local.isEmpty)
            const _AvisoInline(
                'Nenhum template local ativo. Crie templates no desktop.'),
          ...templates.local.map(
            (t) => _TemplateTile(
              titulo: t.titulo,
              texto: t.texto,
              selecionado: widget.emMassa
                  ? _templatesLocais.contains(t.id)
                  : _templateLocalIndividual?.id == t.id,
              onTap: () => setState(() {
                if (widget.emMassa) {
                  _templatesLocais.contains(t.id)
                      ? _templatesLocais.remove(t.id)
                      : _templatesLocais.add(t.id);
                } else {
                  _templateLocalIndividual = t;
                }
                _valoresVariaveis.clear();
                _mapCampo.clear();
              }),
            ),
          ),
        ],

        // Variáveis
        if (_canal != null &&
            _canal != _Canal.texto &&
            _variaveisAtivas.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('VARIÁVEIS', style: AppTextStyles.eyebrow(context)),
          const SizedBox(height: AppSpacing.sm),
          ..._variaveisAtivas.map(
            (v) => widget.emMassa
                ? _variavelMassa(v)
                : Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: TextField(
                      controller: _valoresVariaveis[v],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(labelText: '{{$v}}'),
                    ),
                  ),
          ),
        ],

        // Pré-visualização
        if (_canal != null && _canal != _Canal.texto && _prontoParaEnviar) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('PRÉ-VISUALIZAÇÃO', style: AppTextStyles.eyebrow(context)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: const Color(0xFF25D366).withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              _preview(
                _canal == _Canal.meta
                    ? (_templateMeta?.texto ?? '')
                    : widget.emMassa
                        ? (ref
                                .read(whatsappTemplatesProvider)
                                .valueOrNull
                                ?.local
                                .where(
                                    (t) => _templatesLocais.contains(t.id))
                                .firstOrNull
                                ?.texto ??
                            '')
                        : (_templateLocalIndividual?.texto ?? ''),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],

        // Intervalo (massa, apenas Z-API — Meta envia direto como no desktop)
        if (widget.emMassa && _canal == _Canal.local) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('INTERVALO ENTRE ENVIOS', style: AppTextStyles.eyebrow(context)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [1, 2, 3, 5, 10]
                .map(
                  (s) => ChoiceChip(
                    label: Text('${s}s'),
                    selected: _intervaloSegundos == s,
                    onSelected: (_) =>
                        setState(() => _intervaloSegundos = s),
                  ),
                )
                .toList(),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: widget.emMassa
              ? 'Enviar para ${widget.totalEstimado ?? '…'} munícipe(s)'
              : 'Enviar mensagem',
          icon: Icons.send_rounded,
          isLoading: _enviando,
          onPressed: _prontoParaEnviar && !_enviando ? _enviar : null,
        ),
        if (widget.emMassa)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'O envio acontece no servidor, um a um, respeitando o intervalo. '
              'Você acompanha o progresso em tempo real.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        // Espaço para o teclado
        SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
      ],
    );
  }

  Widget _variavelMassa(String v) {
    final campo = _mapCampo[v] ?? _campoDefault(v);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: campo,
            decoration: InputDecoration(labelText: '{{$v}}'),
            items: [
              ...camposVariavel.map(
                (c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)),
              ),
              const DropdownMenuItem(
                  value: '_fixo', child: Text('Texto fixo…')),
            ],
            onChanged: (valor) =>
                setState(() => _mapCampo[v] = valor ?? campo),
          ),
          if (campo == '_fixo')
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: TextField(
                controller: _mapFixo[v],
                onChanged: (_) => setState(() {}),
                decoration:
                    const InputDecoration(hintText: 'Texto para todos'),
              ),
            ),
        ],
      ),
    );
  }

  String _resumoFiltros() {
    final f = widget.filtros ?? ConstituentFilters.vazios;
    final partes = <String>[
      if (f.aniversariantes == 'hoje') 'Aniversariantes de hoje',
      if (f.aniversariantes == 'mes') 'Aniversariantes do mês',
      if (f.tag != null) 'Etiqueta: ${f.tag}',
      if (f.cidade != null) f.cidade!,
      if (f.nivelApoio != null) 'Apoio ${f.nivelApoio}',
      if ((widget.search ?? '').isNotEmpty) 'Busca: "${widget.search}"',
    ];
    if (partes.isEmpty) return 'Todos os munícipes com telefone';
    return partes.join(' · ');
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.titulo,
    required this.texto,
    required this.selecionado,
    this.desabilitado = false,
    this.rodape,
    this.onTap,
  });

  final String titulo;
  final String texto;
  final bool selecionado;
  final bool desabilitado;
  final String? rodape;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: desabilitado ? 0.5 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: selecionado
              ? BorderSide(color: cs.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (selecionado)
                      Icon(Icons.check_circle_rounded,
                          color: cs.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (rodape != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    rodape!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? AppColors.warningDark
                              : AppColors.warningLight,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvisoInline extends StatelessWidget {
  const _AvisoInline(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.warningContainerDark
            : AppColors.warningContainerLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Text(texto, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _MensagemCentral extends StatelessWidget {
  const _MensagemCentral({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
  });

  final IconData icone;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitulo,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
