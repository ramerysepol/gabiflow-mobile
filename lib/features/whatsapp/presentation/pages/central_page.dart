import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/central_models.dart';
import '../providers/central_providers.dart';

/// Central de Atendimento — lista de conversas no padrao WhatsApp:
/// avatar, nome, previa da ultima mensagem, hora e badge de nao lidas.
class CentralPage extends ConsumerStatefulWidget {
  const CentralPage({super.key});

  @override
  ConsumerState<CentralPage> createState() => _CentralPageState();
}

class _CentralPageState extends ConsumerState<CentralPage> {
  final _buscaController = TextEditingController();

  static const _filtros = [
    ('waiting,active', 'Abertas'),
    ('waiting', 'Aguardando'),
    ('active', 'Atendendo'),
    ('closed', 'Encerradas'),
  ];

  @override
  void dispose() {
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
    return Column(
      children: [
        // Busca
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
    return ListView.separated(
      itemCount: estado.conversas.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, indent: 80, color: cs.outlineVariant),
      itemBuilder: (context, i) => _ConversaTile(estado.conversas[i]),
    );
  }
}

class _ConversaTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final temNaoLidas = conversa.unreadCount > 0;

    return ListTile(
      onTap: () => context.push(Uri(
        path: '/home/atendimento/chat/${conversa.id}',
        queryParameters: {
          'nome': conversa.displayName,
          'tel': conversa.whatsappPhone,
          if (conversa.profilePictureUrl != null)
            'foto': conversa.profilePictureUrl!,
        },
      ).toString()),
      leading: _Avatar(conversa: conversa),
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
      subtitle: Row(
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
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
