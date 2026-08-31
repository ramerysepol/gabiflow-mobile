import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/central_models.dart';
import '../providers/central_providers.dart';
import '../widgets/central_visuals.dart';
import '../widgets/nova_conversa_sheet.dart';

/// Central de Atendimento — lista de conversas no padrao WhatsApp:
/// avatar, nome, previa da ultima mensagem, hora e badge de nao lidas.
class CentralPage extends ConsumerStatefulWidget {
  const CentralPage({super.key});

  @override
  ConsumerState<CentralPage> createState() => _CentralPageState();
}

class _CentralPageState extends ConsumerState<CentralPage> {
  final _buscaController = TextEditingController();
  final _scrollController = ScrollController();
  String? _canalFiltro; // null = todos os canais
  String? _tagFiltro; // null = todas as etiquetas

  static const _filtros = [
    ('waiting,active', 'Abertas'),
    ('waiting', 'Aguardando'),
    ('active', 'Atendendo'),
    ('closed', 'Encerradas'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_aoRolar);
  }

  void _aoRolar() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(conversasProvider.notifier).carregarMais();
    }
  }

  Future<void> _novaConversa() async {
    final id = await NovaConversaSheet.mostrar(context);
    if (id == null || !mounted) return;
    ref.read(conversasProvider.notifier).carregar(silencioso: true);
    context.push('/home/atendimento/chat/$id');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(conversasProvider);
    final notifier = ref.read(conversasProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    // Material proprio: o shell pinta um fundo colorido e, sem isto,
    // ListTile/TextField reclamam de "No Material widget found".
    return Material(
      type: MaterialType.transparency,
      child: _conteudoPagina(estado, notifier, cs),
    );
  }

  Widget _conteudoPagina(
      ConversasState estado, ConversasNotifier notifier, ColorScheme cs) {
    // Canais presentes na lista atual (para o filtro de canal, so aparece se >1).
    final canais = <String>{for (final c in estado.conversas) c.canalEfetivo};
    // Etiquetas presentes nas conversas (para o filtro por etiqueta).
    final tags = <String>{for (final c in estado.conversas) ...c.tags};
    final coresTags = ref.watch(catalogoCoresEtiquetasProvider);
    return Column(
      children: [
        // Metricas do topo (aguardando / atendimento / total / nao lidas)
        _StatsBar(conversas: estado.conversas, total: estado.total),
        // Busca + nova conversa
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buscaController,
                  onSubmitted: notifier.setBusca,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar nome ou telefone',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: estado.busca.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _buscaController.clear();
                              notifier.setBusca('');
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: 'Nova conversa',
                onPressed: _novaConversa,
                icon: const Icon(Icons.add_comment_rounded, size: 20),
              ),
            ],
          ),
        ),
        // Filtros por status
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _filtros.map((f) {
              final (valor, rotulo) = f;
              final ativo = estado.filtroStatus == valor;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: ChoiceChip(
                  label: Text(rotulo),
                  selected: ativo,
                  onSelected: (_) => notifier.setFiltro(valor),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
        // Filtro por canal (so quando ha mais de um canal na lista)
        if (canais.length > 1)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: ChoiceChip(
                    label: const Text('Todos'),
                    selected: _canalFiltro == null,
                    onSelected: (_) => setState(() => _canalFiltro = null),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ...canais.map((c) {
                  final v = canalVisual(c);
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: ChoiceChip(
                      avatar: Icon(v.icone, size: 15, color: v.cor),
                      label: Text(v.label),
                      selected: _canalFiltro == c,
                      onSelected: (_) => setState(
                          () => _canalFiltro = _canalFiltro == c ? null : c),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
              ],
            ),
          ),
        // Filtro por etiqueta (so quando ha etiquetas nas conversas)
        if (tags.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: ChoiceChip(
                    label: const Text('Todas'),
                    selected: _tagFiltro == null,
                    onSelected: (_) => setState(() => _tagFiltro = null),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ...tags.map((t) {
                  final e = resolverEtiqueta(t, coresTags);
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: ChoiceChip(
                      avatar: CircleAvatar(radius: 6, backgroundColor: e.cor),
                      label: Text(e.nome),
                      selected: _tagFiltro == t,
                      onSelected: (_) => setState(
                          () => _tagFiltro = _tagFiltro == t ? null : t),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
              ],
            ),
          ),
        // Lista
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => notifier.carregar(),
            child: _corpo(estado, cs),
          ),
        ),
      ],
    );
  }

  Widget _corpo(ConversasState estado, ColorScheme cs) {
    if (estado.carregando && estado.conversas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (estado.erro != null && estado.conversas.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.wifi_off_rounded, size: 40, color: cs.outline),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Não foi possível carregar as conversas.\nPuxe para tentar de novo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.outline),
            ),
          ),
        ],
      );
    }
    if (estado.conversas.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.chat_bubble_outline_rounded, size: 40, color: cs.outline),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Nenhuma conversa por aqui.',
              style: TextStyle(color: cs.outline),
            ),
          ),
        ],
      );
    }
    var lista = estado.conversas;
    if (_canalFiltro != null) {
      lista = lista.where((c) => c.canalEfetivo == _canalFiltro).toList();
    }
    if (_tagFiltro != null) {
      lista = lista.where((c) => c.tags.contains(_tagFiltro)).toList();
    }
    if (lista.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 80),
        Center(
          child: Text('Nenhuma conversa neste canal.',
              style: TextStyle(color: cs.outline)),
        ),
      ]);
    }
    return ListView.separated(
      controller: _scrollController,
      itemCount: lista.length + (estado.hasMore ? 1 : 0),
      separatorBuilder: (_, __) =>
          Divider(height: 1, indent: 80, color: cs.outlineVariant),
      itemBuilder: (context, i) {
        if (i >= lista.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _ConversaTile(lista[i]);
      },
    );
  }
}

/// Barra de metricas do topo da central. Calculada no cliente a partir das
/// conversas carregadas (o `stats` do endpoint e' de janela 24h, nao de
/// contadores): aguardando/atendimento por status, total da API e nao-lidas
/// somando o unreadCount.
class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.conversas, required this.total});

  final List<ConversaResumo> conversas;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (conversas.isEmpty && total == 0) return const SizedBox.shrink();
    final aguardando = conversas.where((c) => c.status == 'waiting').length;
    final atendimento = conversas.where((c) => c.status == 'active').length;
    final naoLidas =
        conversas.fold<int>(0, (soma, c) => soma + c.unreadCount);
    final itens = [
      ('Aguardando', aguardando, const Color(0xFFF59E0B)),
      ('Atendimento', atendimento, const Color(0xFF25D366)),
      ('Total', total, const Color(0xFF6366F1)),
      ('Não lidas', naoLidas, const Color(0xFFEF4444)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: itens.map((it) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: it.$3.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('${it.$2}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: it.$3)),
                  Text(it.$1,
                      style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.outline)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ConversaTile extends ConsumerWidget {
  const _ConversaTile(this.conversa);

  final ConversaResumo conversa;

  String _hora(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dia = DateTime(local.year, local.month, local.day);
    if (dia == hoje) return DateFormat('HH:mm').format(local);
    if (dia == hoje.subtract(const Duration(days: 1))) return 'Ontem';
    return DateFormat('dd/MM/yy').format(local);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final temNaoLidas = conversa.unreadCount > 0;
    final coresEtiquetas = ref.watch(catalogoCoresEtiquetasProvider);

    return ListTile(
      onTap: () => context.push(Uri(
        path: '/home/atendimento/chat/${conversa.id}',
        queryParameters: {
          'nome': conversa.displayName,
          'tel': conversa.whatsappPhone,
          if (conversa.profilePictureUrl != null)
            'foto': conversa.profilePictureUrl!,
          'canal': conversa.channel,
          if (conversa.channelAccountId != null)
            'conta': conversa.channelAccountId!,
        },
      ).toString()),
      leading: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _Avatar(conversa: conversa),
            Positioned(
              right: -2,
              bottom: -2,
              child: CanalBadge(conversa.canalEfetivo, size: 11),
            ),
          ],
        ),
      ),
      isThreeLine: conversa.tags.isNotEmpty,
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversa.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: temNaoLidas ? FontWeight.w700 : FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            _hora(conversa.lastMessageAt),
            style: TextStyle(
              fontSize: 12,
              fontWeight: temNaoLidas ? FontWeight.w700 : FontWeight.w400,
              color: temNaoLidas ? const Color(0xFF25D366) : cs.outline,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (conversa.status == 'waiting') ...[
                Icon(Icons.hourglass_top_rounded,
                    size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  conversa.lastMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: temNaoLidas ? cs.onSurface : cs.outline,
                    fontWeight: temNaoLidas ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              if (temNaoLidas)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${conversa.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (conversa.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: conversa.tags
                    .take(3)
                    .map((t) => EtiquetaChip(
                          resolverEtiqueta(t, coresEtiquetas),
                          compacto: true,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.conversa});

  final ConversaResumo conversa;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // characters.first evita cortar emoji/unicode decorado no meio
    // (nomes como "𝕴𝖗𝖊𝖒𝖆𝖗" quebravam com "string is not well-formed UTF-16").
    final iniciais = conversa.displayName
        .split(' ')
        .where((p) => p.trim().isNotEmpty)
        .take(2)
        .map((p) => p.characters.first.toUpperCase())
        .join();

    final fallback = CircleAvatar(
      radius: 24,
      backgroundColor: cs.primaryContainer,
      child: Text(
        iniciais.isEmpty ? '?' : iniciais,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final url = conversa.profilePictureUrl;
    if (url == null || !url.startsWith('http')) return fallback;
    return CircleAvatar(
      radius: 24,
      backgroundColor: cs.primaryContainer,
      foregroundImage: NetworkImage(url),
      onForegroundImageError: (_, __) {},
      child: fallback.child,
    );
  }
}
