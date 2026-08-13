import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/permissoes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../whatsapp/presentation/widgets/whatsapp_send_sheet.dart';
import '../../data/models/constituent_model.dart';
import '../providers/constituent_provider.dart';

class ConstituentDetailPage extends ConsumerWidget {
  const ConstituentDetailPage({super.key, required this.id});

  final String id;

  String _initials(String nome) {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return nome.isNotEmpty ? nome[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(constituentDetailProvider(id));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: asyncData.when(
        loading: () => _LoadingSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: AppSpacing.md),
              const Text('Erro ao carregar munícipe'),
              TextButton(
                onPressed: () => ref.refresh(constituentDetailProvider(id)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (c) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              actions: [
                SePodeVer(
                  permissao: Permissoes.eleitoresEditar,
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Editar',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('/home/constituents/$id/edit');
                    },
                  ),
                ),
                // O menu inteiro some sem permissao de excluir, porque hoje
                // "excluir" e' o unico item dele.
                if (ref.watch(temPermissaoProvider(Permissoes.eleitoresExcluir)))
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'excluir') _confirmarExclusao(context, ref, c.nome);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir munícipe'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: cs.primaryContainer,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Hero(
                        tag: 'avatar_$id',
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: cs.primary,
                          child: Text(
                            _initials(c.nome),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        c.nome,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Botões de ação
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.chat_rounded,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () => _opcoesWhatsApp(context, c),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.phone_rounded,
                          label: 'Ligar',
                          color: cs.primary,
                          onTap: () => _abrirContato(
                            context,
                            c.telefone ?? c.whatsapp,
                            (clean) => Uri.parse('tel:+55$clean'),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: AppSpacing.lg),

                  // Dados pessoais
                  const _SectionTitle('Dados Pessoais'),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoCard(children: [
                    if (c.cpf != null && c.cpf!.isNotEmpty)
                      _InfoRow(Icons.badge_rounded, 'CPF', _formatCpf(c.cpf!)),
                    if (c.dataNascimento != null &&
                        c.dataNascimento!.isNotEmpty)
                      _InfoRow(Icons.cake_rounded, 'Nascimento',
                          _formatData(c.dataNascimento!)),
                    if (c.genero != null && c.genero!.isNotEmpty)
                      _InfoRow(Icons.wc_rounded, 'Gênero', c.genero!),
                    if (c.profissao != null && c.profissao!.isNotEmpty)
                      _InfoRow(Icons.work_outline_rounded, 'Profissão',
                          c.profissao!),
                    if (c.email != null && c.email!.isNotEmpty)
                      _InfoRow(Icons.email_rounded, 'E-mail', c.email!),
                    if (c.telefone != null && c.telefone!.isNotEmpty)
                      _InfoRow(Icons.phone_rounded, 'Telefone',
                          _formatFone(c.telefone!)),
                    if (c.whatsapp != null && c.whatsapp!.isNotEmpty)
                      _InfoRow(Icons.chat_rounded, 'WhatsApp',
                          _formatFone(c.whatsapp!)),
                  ]),

                  // Relacionamento (nível de apoio / voluntário)
                  if ((c.nivelApoio != null && c.nivelApoio!.isNotEmpty) ||
                      c.voluntario) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        if (c.nivelApoio != null && c.nivelApoio!.isNotEmpty)
                          _BadgeApoio(nivel: c.nivelApoio!),
                        if (c.voluntario) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const Chip(
                            avatar: Icon(Icons.volunteer_activism_rounded,
                                size: 16),
                            label: Text('Voluntário'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                  ],

                  if (c.endereco != null || c.cidade != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    const _SectionTitle('Endereço'),
                    const SizedBox(height: AppSpacing.sm),
                    _InfoCard(children: [
                      if (c.endereco != null && c.endereco!.isNotEmpty)
                        _InfoRow(
                          Icons.home_rounded,
                          'Endereço',
                          [
                            c.endereco,
                            if (c.numero != null && c.numero!.isNotEmpty)
                              'nº ${c.numero}',
                            if (c.complemento != null &&
                                c.complemento!.isNotEmpty)
                              c.complemento,
                          ].join(', '),
                        ),
                      if (c.bairro != null && c.bairro!.isNotEmpty)
                        _InfoRow(Icons.map_rounded, 'Bairro', c.bairro!),
                      if (c.cidade != null)
                        _InfoRow(
                          Icons.location_city_rounded,
                          'Cidade',
                          [c.cidade, if (c.estado != null) c.estado].join(' - '),
                        ),
                      if (c.cep != null && c.cep!.isNotEmpty)
                        _InfoRow(Icons.pin_drop_rounded, 'CEP', c.cep!),
                    ]),
                  ],

                  // ── Demandas deste munícipe ─────────────────────────────
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionTitle('Demandas'),
                      TextButton.icon(
                        onPressed: () =>
                            context.push('/home/demands/new'),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Nova',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  _DemandasDoMunicipe(constituentId: id),

                  // ── Histórico de interações ─────────────────────────────
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionTitle('Histórico de contatos'),
                      TextButton.icon(
                        onPressed: () =>
                            _registrarInteracao(context, ref, id),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Registrar',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  _InteracoesDoMunicipe(constituentId: id),

                  if (c.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    const _SectionTitle('Etiquetas'),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: c.tags
                          .map((t) => Chip(
                                label: Text(t),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],

                  if (c.notes != null && c.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    const _SectionTitle('Notas'),
                    const SizedBox(height: AppSpacing.sm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(c.notes!,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ),
                  ],

                  if (c.createdAt != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Text(
                        [
                          'Cadastrado em ${_formatData(c.createdAt!)}',
                          if (c.updatedAt != null &&
                              c.updatedAt != c.createdAt)
                            'atualizado em ${_formatData(c.updatedAt!)}',
                        ].join(' · '),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WhatsApp: enviar pelo gabinete ou abrir o aplicativo ───────────────────

Future<void> _opcoesWhatsApp(BuildContext context, ConstituentModel c) async {
  final phone = c.whatsapp ?? c.telefone;
  if (phone == null || phone.replaceAll(RegExp(r'\D'), '').isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Munícipe sem telefone cadastrado')),
    );
    return;
  }

  final escolha = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.forward_to_inbox_rounded,
                color: Color(0xFF128C7E)),
            title: const Text('Enviar pelo gabinete'),
            subtitle: const Text(
                'Mensagem livre ou template (Meta / Z-API), com registro'),
            onTap: () => Navigator.of(ctx).pop('gabinete'),
          ),
          ListTile(
            leading:
                const Icon(Icons.open_in_new_rounded, color: Color(0xFF25D366)),
            title: const Text('Abrir no WhatsApp'),
            subtitle: const Text('Conversa direta pelo seu aparelho'),
            onTap: () => Navigator.of(ctx).pop('abrir'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );

  if (escolha == null || !context.mounted) return;
  if (escolha == 'gabinete') {
    await WhatsAppSendSheet.show(context, c);
  } else {
    await _abrirContato(
      context,
      phone,
      (clean) => Uri.parse('https://wa.me/55$clean'),
      externo: true,
    );
  }
}

// ─── Abrir contato com guarda (sem telefone → aviso; falha → aviso) ─────────

Future<void> _abrirContato(
  BuildContext context,
  String? phone,
  Uri Function(String clean) montarUri, {
  bool externo = false,
}) async {
  if (phone == null || phone.replaceAll(RegExp(r'\D'), '').isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Munícipe sem telefone cadastrado')),
    );
    return;
  }
  final clean = phone.replaceAll(RegExp(r'\D'), '');
  try {
    final ok = await launchUrl(
      montarUri(clean),
      mode: externo ? LaunchMode.externalApplication : LaunchMode.platformDefault,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o aplicativo')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o aplicativo')),
      );
    }
  }
}

// ─── Helpers de formatação ───────────────────────────────────────────────────

String _formatCpf(String cpf) {
  final d = cpf.replaceAll(RegExp(r'\D'), '');
  if (d.length != 11) return cpf;
  return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
}

String _formatFone(String fone) {
  final d = fone.replaceAll(RegExp(r'\D'), '');
  if (d.length == 11) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
  }
  if (d.length == 10) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
  }
  return fone;
}

String _formatData(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ─── Exclusão com confirmação ────────────────────────────────────────────────

Future<void> _confirmarExclusao(
    BuildContext context, WidgetRef ref, String nome) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Excluir munícipe?'),
      content: Text(
          '$nome será removido da sua base. Essa ação pode ser desfeita apenas pelo suporte.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  if (confirmado != true || !context.mounted) return;

  // O id vem da rota — recupera do GoRouter state via contexto da página
  final id = GoRouterState.of(context).pathParameters['id'];
  if (id == null) return;

  final ok = await ref.read(constituentFormProvider.notifier).delete(id);
  if (!context.mounted) return;

  if (ok) {
    ref.invalidate(constituentListProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nome excluído'),
        backgroundColor: AppColors.successLight,
      ),
    );
    context.pop();
  } else {
    final err = ref.read(constituentFormProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Não foi possível excluir. Tente novamente.'),
        backgroundColor: AppColors.dangerLight,
      ),
    );
  }
}

// ─── Demandas do munícipe ────────────────────────────────────────────────────

class _DemandasDoMunicipe extends ConsumerWidget {
  const _DemandasDoMunicipe({required this.constituentId});

  final String constituentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(constituentDemandsProvider(constituentId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return async.when(
      loading: () => ShimmerSkeleton.card(height: 64),
      error: (_, __) => Card(
        child: ListTile(
          dense: true,
          leading: Icon(Icons.cloud_off_rounded, color: cs.error, size: 20),
          title: const Text('Não foi possível carregar as demandas'),
          trailing: TextButton(
            onPressed: () =>
                ref.invalidate(constituentDemandsProvider(constituentId)),
            child: const Text('Tentar'),
          ),
        ),
      ),
      data: (resp) {
        if (resp.items.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Nenhuma demanda registrada',
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }
        return Card(
          child: Column(
            children: [
              for (final (i, d) in resp.items.take(5).indexed) ...[
                ListTile(
                  dense: true,
                  leading: Icon(Icons.assignment_outlined,
                      size: 20, color: cs.primary),
                  title: Text(
                    d.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: d.createdAt != null
                      ? Text(_formatData(d.createdAt!),
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant))
                      : null,
                  trailing: _StatusChip(status: d.status),
                  onTap: () => context.push('/home/demands/${d.id}'),
                ),
                if (i < resp.items.take(5).length - 1)
                  const Divider(height: 1, indent: 48),
              ],
              if (resp.total > 5)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '+ ${resp.total - 5} demanda(s)',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final (cor, rotulo) = switch (s) {
      'nova' || 'pending' || 'aberta' => (Colors.blue, 'Nova'),
      'em_andamento' || 'in_progress' => (Colors.orange, 'Em andamento'),
      'concluída' || 'concluida' || 'completed' || 'resolvida' => (
          Colors.green,
          'Concluída'
        ),
      'cancelada' || 'cancelled' => (Colors.grey, 'Cancelada'),
      _ => (Colors.blueGrey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        rotulo,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: cor.shade700,
        ),
      ),
    );
  }
}

class _BadgeApoio extends StatelessWidget {
  const _BadgeApoio({required this.nivel});

  final String nivel;

  @override
  Widget build(BuildContext context) {
    final (cor, rotulo) = switch (nivel.toLowerCase()) {
      'alto' => (Colors.green, 'Apoio alto'),
      'medio' || 'médio' => (Colors.orange, 'Apoio médio'),
      'baixo' => (Colors.red, 'Apoio baixo'),
      _ => (Colors.blueGrey, 'Apoio: $nivel'),
    };
    return Chip(
      avatar: Icon(Icons.favorite_rounded, size: 16, color: cor.shade700),
      label: Text(rotulo),
      backgroundColor: cor.withValues(alpha: 0.12),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: cor.withValues(alpha: 0.3)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Column(
        children: children
            .asMap()
            .entries
            .map((e) => Column(
                  children: [
                    e.value,
                    if (e.key < children.length - 1)
                      const Divider(height: 1, indent: 48),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: cs.primary),
      title: Text(label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.onSurfaceVariant)),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerSkeleton.card(height: 220),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ShimmerSkeleton.card(height: 60),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Histórico de interações ─────────────────────────────────────────────────

const _tiposInteracao = [
  ('ligacao', 'Ligação', Icons.phone_rounded),
  ('whatsapp', 'WhatsApp', Icons.chat_rounded),
  ('email', 'E-mail', Icons.email_rounded),
  ('visita', 'Visita', Icons.home_rounded),
  ('reuniao', 'Reunião', Icons.groups_rounded),
  ('evento', 'Evento', Icons.event_rounded),
  ('outro', 'Outro', Icons.more_horiz_rounded),
];

IconData _iconeInteracao(String tipo) {
  return _tiposInteracao
      .firstWhere((t) => t.$1 == tipo, orElse: () => _tiposInteracao.last)
      .$3;
}

String _rotuloInteracao(String tipo) {
  return _tiposInteracao
      .firstWhere((t) => t.$1 == tipo, orElse: () => _tiposInteracao.last)
      .$2;
}

class _InteracoesDoMunicipe extends ConsumerWidget {
  const _InteracoesDoMunicipe({required this.constituentId});

  final String constituentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(constituentInteracoesProvider(constituentId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return async.when(
      loading: () => ShimmerSkeleton.card(height: 64),
      error: (_, __) => Card(
        child: ListTile(
          dense: true,
          leading: Icon(Icons.cloud_off_rounded, color: cs.error, size: 20),
          title: const Text('Não foi possível carregar o histórico'),
          trailing: TextButton(
            onPressed: () => ref
                .invalidate(constituentInteracoesProvider(constituentId)),
            child: const Text('Tentar'),
          ),
        ),
      ),
      data: (interacoes) {
        if (interacoes.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.history_rounded,
                      size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Nenhum contato registrado ainda. Registre ligações, visitas e conversas para acompanhar o relacionamento.',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Card(
          child: Column(
            children: [
              for (final (i, it) in interacoes.take(8).indexed) ...[
                ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor:
                        cs.primaryContainer.withValues(alpha: 0.6),
                    child: Icon(_iconeInteracao(it.tipo),
                        size: 15, color: cs.onPrimaryContainer),
                  ),
                  title: Text(
                    it.descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall,
                  ),
                  subtitle: Text(
                    [
                      _rotuloInteracao(it.tipo),
                      if (it.dataInteracao != null)
                        _formatData(it.dataInteracao!),
                      if (it.responsavelNome != null) it.responsavelNome,
                    ].join(' · '),
                    style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant, fontSize: 10),
                  ),
                ),
                if (i < interacoes.take(8).length - 1)
                  const Divider(height: 1, indent: 56),
              ],
              if (interacoes.length > 8)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '+ ${interacoes.length - 8} registro(s)',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Registrar interação (bottom sheet) ──────────────────────────────────────

Future<void> _registrarInteracao(
    BuildContext context, WidgetRef ref, String constituentId) async {
  final salvou = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _NovaInteracaoSheet(constituentId: constituentId),
  );
  if (salvou == true) {
    ref.invalidate(constituentInteracoesProvider(constituentId));
  }
}

class _NovaInteracaoSheet extends ConsumerStatefulWidget {
  const _NovaInteracaoSheet({required this.constituentId});

  final String constituentId;

  @override
  ConsumerState<_NovaInteracaoSheet> createState() =>
      _NovaInteracaoSheetState();
}

class _NovaInteracaoSheetState extends ConsumerState<_NovaInteracaoSheet> {
  String _tipo = 'ligacao';
  final _descricaoCtrl = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final descricao = _descricaoCtrl.text.trim();
    if (descricao.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descreva o contato antes de salvar')),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      await ref.read(constituentDataSourceProvider).createInteracao(
        widget.constituentId,
        {'tipo': _tipo, 'descricao': descricao},
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Não foi possível registrar. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Registrar contato',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _tiposInteracao)
                ChoiceChip(
                  avatar: Icon(t.$3, size: 15),
                  label: Text(t.$2, style: const TextStyle(fontSize: 12)),
                  selected: _tipo == t.$1,
                  onSelected: (_) => setState(() => _tipo = t.$1),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descricaoCtrl,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'O que foi conversado? *',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Salvar registro'),
            ),
          ),
        ],
      ),
    );
  }
}
