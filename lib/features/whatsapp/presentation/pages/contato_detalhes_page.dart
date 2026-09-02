import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/central_models.dart';
import '../providers/central_providers.dart';
import '../widgets/central_visuals.dart';
import '../widgets/tags_editor_sheet.dart';
import '../../../../core/network/friendly_error.dart';

/// Painel de Informacoes do contato/conversa (paridade com ContactDetails.tsx):
/// status, prioridade, departamento, etiquetas, notas internas, janela 24h,
/// constituinte e historico de protocolos.
class ContatoDetalhesPage extends ConsumerStatefulWidget {
  const ContatoDetalhesPage({
    super.key,
    required this.conversationId,
    this.base,
  });

  final int conversationId;

  /// Dados basicos que ja vieram da lista — usados como fallback quando o
  /// GET /conversations/{id} retorna 404 (conversas do app/webchat nao
  /// visiveis via getConversation por filtro de visibilidade).
  final ConversaResumo? base;

  @override
  ConsumerState<ContatoDetalhesPage> createState() =>
      _ContatoDetalhesPageState();
}

class _ContatoDetalhesPageState extends ConsumerState<ContatoDetalhesPage> {
  final _notasCtrl = TextEditingController();
  ConversaDetalhe? _detalhe;
  bool _carregando = true;
  bool _salvandoNotas = false;
  String? _erro;

  static const _statusOpc = [
    ('waiting', 'Aguardando'),
    ('active', 'Em atendimento'),
    ('closed', 'Encerrada'),
  ];
  static const _prioridadeOpc = [
    ('high', 'Alta'),
    ('medium', 'Média'),
    ('normal', 'Normal'),
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final d = await ref
          .read(centralDataSourceProvider)
          .detalheConversa(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _detalhe = d;
        _notasCtrl.text = d.internalNotes ?? '';
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Fallback: monta o detalhe com o que ja temos da lista (o GET /{id}
      // pode 404 por visibilidade em conversas do app/webchat).
      final b = widget.base;
      if (b != null) {
        setState(() {
          _detalhe = ConversaDetalhe(
            id: b.id,
            contactName: b.contactName,
            whatsappPhone: b.whatsappPhone,
            profilePictureUrl: b.profilePictureUrl,
            status: b.status,
            priority: 'normal',
            department: b.department,
            channel: b.channel,
            channelAccountId: b.channelAccountId,
            internalNotes: null,
            tags: b.tags,
            withinWindow: b.withinWindow,
            windowExpiresAt: b.windowExpiresAt,
            assignedTo: b.assignedTo,
            assignedToName: b.assignedToName,
            isPrivate: b.isPrivate,
            isPaused: false,
          );
          _notasCtrl.text = '';
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = e.toString();
          _carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _patch({
    String? status,
    String? prioridade,
    String? departamento,
  }) async {
    try {
      await ref.read(centralDataSourceProvider).atualizarConversa(
            widget.conversationId,
            status: status,
            prioridade: prioridade,
            departamento: departamento,
          );
      ref.read(conversasProvider.notifier).carregar(silencioso: true);
      await _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao atualizar. ${mensagemAmigavel(e)}')));
      }
    }
  }

  Future<void> _togglePausa(bool pausar) async {
    try {
      await ref
          .read(centralDataSourceProvider)
          .pausarConversa(widget.conversationId, pausar);
      await _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha ao ${pausar ? 'pausar' : 'retomar'}. ${mensagemAmigavel(e)}')));
      }
    }
  }

  Future<void> _salvarNotas() async {
    setState(() => _salvandoNotas = true);
    try {
      await ref.read(centralDataSourceProvider).atualizarConversa(
            widget.conversationId,
            notasInternas: _notasCtrl.text,
          );
      if (!mounted) return;
      setState(() => _salvandoNotas = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Notas salvas.')));
    } catch (e) {
      if (mounted) {
        setState(() => _salvandoNotas = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao salvar notas. ${mensagemAmigavel(e)}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informações')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text('Erro: $_erro'))
              : _conteudo(_detalhe!),
    );
  }

  Widget _conteudo(ConversaDetalhe d) {
    final cores = ref.watch(catalogoCoresEtiquetasProvider);
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cabecalho do contato
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primaryContainer,
              foregroundImage: (d.profilePictureUrl != null &&
                      d.profilePictureUrl!.startsWith('http'))
                  ? NetworkImage(d.profilePictureUrl!)
                  : null,
              child: const Icon(Icons.person_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          d.contactName?.trim().isNotEmpty == true
                              ? d.contactName!
                              : d.whatsappPhone,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        tooltip: 'Copiar nome',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text: d.contactName ?? d.whatsappPhone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nome copiado!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  CanalBadge(d.canalEfetivo, size: 12, comLabel: true),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Pausar/retomar atendimento
        Card(
          margin: EdgeInsets.zero,
          child: SwitchListTile(
            value: d.isPaused,
            onChanged: _togglePausa,
            secondary: Icon(
              d.isPaused ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
              color: d.isPaused ? Colors.orange : Colors.green,
            ),
            title: const Text('Pausar atendimento'),
            subtitle: Text(d.isPaused
                ? 'Conversa pausada'
                : 'Conversa em andamento'),
          ),
        ),
        const SizedBox(height: 16),

        // Status
        _secao('Status'),
        Wrap(
          spacing: 8,
          children: _statusOpc
              .map((o) => ChoiceChip(
                    label: Text(o.$2),
                    selected: d.status == o.$1,
                    onSelected: (_) => _patch(status: o.$1),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),

        // Prioridade
        _secao('Prioridade'),
        Wrap(
          spacing: 8,
          children: _prioridadeOpc
              .map((o) => ChoiceChip(
                    label: Text(o.$2),
                    selected: d.priority == o.$1,
                    onSelected: (_) => _patch(prioridade: o.$1),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),

        // Departamento
        _secao('Departamento'),
        _seletorDepartamento(d),
        const SizedBox(height: 16),

        // Etiquetas
        Row(
          children: [
            Expanded(child: _secao('Etiquetas')),
            TextButton.icon(
              onPressed: () async {
                final novas = await TagsEditorSheet.mostrar(
                    context, widget.conversationId);
                if (novas != null) {
                  ref.read(conversasProvider.notifier).carregar(silencioso: true);
                  await _carregar();
                }
              },
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Editar'),
            ),
          ],
        ),
        if (d.tags.isEmpty)
          Text('Sem etiquetas.', style: TextStyle(color: cs.outline))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: d.tags
                .map((t) => EtiquetaChip(resolverEtiqueta(t, cores)))
                .toList(),
          ),
        const SizedBox(height: 16),

        // Notas internas
        _secao('Notas internas'),
        TextField(
          controller: _notasCtrl,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Anotações visíveis só para a equipe…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _salvandoNotas ? null : _salvarNotas,
            icon: _salvandoNotas
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded, size: 18),
            label: const Text('Salvar notas'),
          ),
        ),
        const SizedBox(height: 16),

        // Janela 24h (WhatsApp)
        if (d.channel == 'whatsapp') ...[
          _secao('Janela de 24h'),
          Row(
            children: [
              Icon(
                d.withinWindow ? Icons.lock_open_rounded : Icons.lock_clock_rounded,
                color: d.withinWindow ? Colors.green : Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(d.withinWindow
                  ? 'Aberta${d.windowExpiresAt != null ? ' até ${DateFormat('dd/MM HH:mm').format(d.windowExpiresAt!.toLocal())}' : ''}'
                  : 'Expirada (exige template)'),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Constituinte vinculado
        if (d.constituentName != null) ...[
          _secao('Munícipe vinculado'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.badge_rounded),
            title: Text(d.constituentName!),
          ),
          const SizedBox(height: 16),
        ],

        // Historico de protocolos
        _secao('Histórico de atendimentos'),
        _historico(),
      ],
    );
  }

  Widget _seletorDepartamento(ConversaDetalhe d) {
    final deptos = ref.watch(departamentosProvider);
    return deptos.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Falha ao carregar departamentos.'),
      data: (listaBruta) {
        // Deduplica por id (ids repetidos quebram o DropdownButton).
        final vistos = <String>{};
        final lista = listaBruta
            .where((dep) => vistos.add(dep.id))
            .toList();
        final ids = lista.map((e) => e.id).toSet();
        final atual = ids.contains(d.department) ? d.department : null;
        return DropdownButtonFormField<String>(
          initialValue: atual,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          hint: const Text('Selecionar departamento'),
          items: lista
              .map((dep) => DropdownMenuItem(
                    value: dep.id,
                    child: Text(dep.nome),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) _patch(departamento: v);
          },
        );
      },
    );
  }

  Widget _historico() {
    return FutureBuilder<List<ProtocoloHistorico>>(
      future: ref
          .read(centralDataSourceProvider)
          .historicoProtocolos(widget.conversationId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final lista = snap.data ?? const [];
        if (lista.isEmpty) {
          return Text('Nenhum atendimento anterior.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline));
        }
        return Column(
          children: lista
              .map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long_rounded),
                    title: Text(p.protocolo ?? 'Protocolo #${p.id}'),
                    subtitle: Text([
                      if (p.criadoEm != null)
                        DateFormat('dd/MM/yy').format(p.criadoEm!.toLocal()),
                      if (p.status.isNotEmpty) p.status,
                      if (p.resumo != null) p.resumo!,
                    ].join(' · ')),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _secao(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      );
}
