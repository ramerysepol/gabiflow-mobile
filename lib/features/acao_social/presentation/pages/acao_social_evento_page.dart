import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissoes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/acao_social_models.dart';
import '../providers/acao_social_providers.dart';
import '../widgets/acao_social_widgets.dart';
import '../widgets/atendimento_acoes.dart';

/// Central do evento: resumo + abas Cadastrados / Vagas / Atendimentos.
/// Espelha a tela principal do painel (/dashboard/expresso-saude).
class AcaoSocialEventoPage extends ConsumerStatefulWidget {
  const AcaoSocialEventoPage({super.key, required this.eventoId});

  final String eventoId;

  @override
  ConsumerState<AcaoSocialEventoPage> createState() =>
      _AcaoSocialEventoPageState();
}

class _AcaoSocialEventoPageState extends ConsumerState<AcaoSocialEventoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _recarregarTudo() {
    ref.invalidate(eventoAcaoSocialProvider(widget.eventoId));
    ref.invalidate(especialidadesEventoProvider(widget.eventoId));
    ref.invalidate(atendimentosEventoProvider(widget.eventoId));
  }

  Future<void> _cadastrar(EventoAcaoSocial evento) async {
    HapticFeedback.lightImpact();
    final r = await context.push<CadastroPresencialResult>(
        '/home/acao-social/evento/${evento.id}/cadastro');
    if (r == null || !mounted) return;
    ref.invalidate(cadastradosProvider(evento.tag));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r.isUpdate
          ? '${r.nome} já estava cadastrado(a) e recebeu a tag do evento.'
          : '${r.nome} cadastrado(a) com sucesso.'),
    ));
    // "Cadastrar e atender": mesmo fluxo do painel
    await atenderPaciente(context, ref,
        evento: evento, eleitorId: r.id, nome: r.nome);
  }

  @override
  Widget build(BuildContext context) {
    final eventoAsync = ref.watch(eventoAcaoSocialProvider(widget.eventoId));
    final evento = eventoAsync.valueOrNull;
    // Com o teclado aberto (busca), cabecalho e FAB saem de cena: sobra
    // espaco para a lista e evita o overflow do Column no espaco restante.
    final tecladoAberto = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(evento?.nome ?? 'Ação Social',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _recarregarTudo,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: evento != null &&
              evento.ativo &&
              _tabs.index == 0 &&
              !tecladoAberto
          ? SePodeVer(
              permissao: Permissoes.acaoSocialEditar,
              child: FloatingActionButton.extended(
                heroTag: 'fab_acao_social_cadastro',
                onPressed: () => _cadastrar(evento),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Cadastrar'),
              ),
            )
          : null,
      body: eventoAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            ShimmerSkeleton.card(height: 120),
            const SizedBox(height: AppSpacing.sm),
            ShimmerSkeleton.card(height: 88),
            const SizedBox(height: AppSpacing.sm),
            ShimmerSkeleton.card(height: 88),
          ],
        ),
        error: (e, _) => AppEmptyState(
          title: 'Não foi possível carregar o evento',
          subtitle: mensagemErroAcaoSocial(e),
          actionLabel: 'Tentar novamente',
          onAction: _recarregarTudo,
        ),
        data: (evento) => Column(
          children: [
            if (!tecladoAberto) _CabecalhoEvento(evento: evento),
            TabBar(
              controller: _tabs,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(text: 'Cadastrados'),
                Tab(text: 'Vagas'),
                Tab(text: 'Atendimentos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _CadastradosTab(evento: evento),
                  _VagasTab(eventoId: evento.id),
                  _AtendimentosTab(evento: evento),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fluxo "Atender": seletor de especialidades + reserva de vagas ───────────

/// Abre o seletor de especialidades e cria os atendimentos. Se ao menos uma
/// vaga foi reservada, abre a ficha do paciente. Reutilizado pela aba
/// Cadastrados e pelo pos-cadastro.
Future<void> atenderPaciente(
  BuildContext context,
  WidgetRef ref, {
  required EventoAcaoSocial evento,
  required int eleitorId,
  required String nome,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  List<EspecialidadeEvento> especialidades;
  List<Atendimento> existentes;
  try {
    final r = await Future.wait([
      ref.read(especialidadesEventoProvider(evento.id).future),
      ref.read(acaoSocialDataSourceProvider)
          .listarAtendimentos(evento.id, eleitorId: eleitorId),
    ]);
    especialidades = (r[0] as List<EspecialidadeEvento>)
        .where((e) => e.ativo && e.totalVagas > 0)
        .toList(growable: false);
    existentes = r[1] as List<Atendimento>;
  } catch (e) {
    messenger.showSnackBar(
        SnackBar(content: Text(mensagemErroAcaoSocial(e))));
    return;
  }
  if (!context.mounted) return;
  if (especialidades.isEmpty) {
    messenger.showSnackBar(const SnackBar(
        content: Text('Este evento não tem especialidades com vagas.')));
    return;
  }

  final jaAtendidas = existentes
      .where((a) => !a.cancelado)
      .map((a) => a.especialidadeId)
      .toSet();

  final escolhidas = await EspecialidadeSelectorSheet.mostrar(
    context,
    especialidades: especialidades,
    pacienteNome: nome,
    jaAtendidas: jaAtendidas,
  );
  if (escolhidas == null || escolhidas.isEmpty || !context.mounted) return;

  final resultado = await ref.read(acaoSocialAcoesProvider.notifier).reservarVagas(
        eventoId: evento.id,
        eleitorId: eleitorId,
        especialidades: escolhidas,
      );
  if (!context.mounted) return;

  if (resultado.falhas.isNotEmpty) {
    final detalhes = resultado.falhas.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
    messenger.showSnackBar(SnackBar(
      content: Text(resultado.algumSucesso
          ? 'Reservado ${resultado.criados.length} de ${escolhidas.length}.\n$detalhes'
          : detalhes),
      duration: const Duration(seconds: 6),
    ));
  } else {
    HapticFeedback.mediumImpact();
    messenger.showSnackBar(SnackBar(
      content: Text(
          '${resultado.criados.length} ${resultado.criados.length == 1 ? 'vaga reservada' : 'vagas reservadas'} para $nome.'),
    ));
  }

  if (resultado.algumSucesso || jaAtendidas.isNotEmpty) {
    context.push('/home/acao-social/evento/${evento.id}/ficha/$eleitorId');
  }
}

// ── Cabecalho ───────────────────────────────────────────────────────────────

/// Resumo do evento. Tres numeros DIFERENTES que o usuario confundia:
/// cadastrados (municipes com a tag), pacientes atendidos (distintos, sem
/// cancelados) e vagas usadas/total (soma das especialidades).
class _CabecalhoEvento extends ConsumerWidget {
  const _CabecalhoEvento({required this.evento});

  final EventoAcaoSocial evento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progresso = evento.totalVagas > 0
        ? (evento.totalUtilizadas / evento.totalVagas).clamp(0.0, 1.0)
        : 0.0;

    // Contagens vindas das mesmas fontes das abas (ja carregadas por elas).
    final cadastrados = ref.watch(cadastradosProvider(evento.tag));
    final atendimentos = ref.watch(atendimentosEventoProvider(evento.id));
    // totalGeral ignora a busca: digitar na aba nao muda o numero do evento
    final totalCadastrados = cadastrados.totalGeral;
    final pacientes = atendimentos.valueOrNull
        ?.where((a) => !a.cancelado)
        .map((a) => a.eleitorId)
        .toSet()
        .length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            corAcaoSocial.withValues(alpha: 0.10),
            corAcaoSocialClara.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(
                  rotulo: rotuloStatusEvento(evento.status),
                  cor: corStatusEvento(evento.status)),
              _info(Icons.event_rounded, formatarData(evento.dataEvento), cs, tt),
              if (evento.localEvento != null)
                _info(Icons.place_rounded, evento.localEvento!, cs, tt),
              _info(Icons.sell_rounded, evento.tag, cs, tt),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Indicador(
                valor: totalCadastrados?.toString() ?? '…',
                rotulo: 'cadastrados',
                icone: Icons.people_rounded,
              ),
              _Indicador(
                valor: pacientes?.toString() ?? '…',
                rotulo: 'atendidos',
                icone: Icons.medical_services_rounded,
              ),
              _Indicador(
                valor: '${evento.totalUtilizadas}/${evento.totalVagas}',
                rotulo: 'vagas',
                icone: Icons.event_seat_rounded,
                cor: corNivelVagas(evento.nivel, cs),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: corNivelVagas(evento.nivel, cs),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ocupação das vagas',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(IconData i, String t, ColorScheme cs, TextTheme tt) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(t, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      );
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.valor,
    required this.rotulo,
    required this.icone,
    this.cor,
  });

  final String valor;
  final String rotulo;
  final IconData icone;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final c = cor ?? cs.onSurface;
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: cor ?? cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$valor ',
                    style: tt.titleSmall?.copyWith(
                        color: c, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: rotulo,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
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

// ── Aba Cadastrados ─────────────────────────────────────────────────────────

class _CadastradosTab extends ConsumerStatefulWidget {
  const _CadastradosTab({required this.evento});

  final EventoAcaoSocial evento;

  @override
  ConsumerState<_CadastradosTab> createState() => _CadastradosTabState();
}

class _CadastradosTabState extends ConsumerState<_CadastradosTab>
    with AutomaticKeepAliveClientMixin {
  final _busca = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tag = widget.evento.tag;
    final state = ref.watch(cadastradosProvider(tag));
    final notifier = ref.read(cadastradosProvider(tag).notifier);
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: TextField(
            controller: _busca,
            onChanged: notifier.buscar,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou telefone',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              suffixIcon: _busca.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _busca.clear();
                        notifier.buscar('');
                        setState(() {});
                      },
                    ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control)),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refresh,
            child: _lista(state, notifier, cs),
          ),
        ),
      ],
    );
  }

  Widget _lista(
      CadastradosState state, CadastradosNotifier notifier, ColorScheme cs) {
    if (state.isLoading && state.items.isEmpty) {
      // Indicador explicito (o shimmer se confunde com o fundo e a aba
      // parecia vazia durante o carregamento).
      return ListView(children: [
        const SizedBox(height: 64),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 12),
        Center(
          child: Text('Carregando cadastrados...',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      ]);
    }
    if (state.error != null && state.items.isEmpty) {
      return ListView(children: [
        AppEmptyState(
          title: 'Não foi possível carregar',
          subtitle: state.error!,
          actionLabel: 'Tentar novamente',
          onAction: notifier.refresh,
        ),
      ]);
    }
    if (state.items.isEmpty) {
      return ListView(children: [
        AppEmptyState(
          title: state.busca.isEmpty
              ? 'Nenhum munícipe cadastrado'
              : 'Nenhum resultado para "${state.busca}"',
          subtitle: state.busca.isEmpty
              ? 'Cadastre presencialmente ou compartilhe o QR Code do evento.'
              : 'Confira o nome ou o telefone.',
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, 96),
      itemCount: state.items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Text(
              '${state.items.length} '
              '${state.items.length == 1 ? 'cadastrado' : 'cadastrados'}'
              '${state.busca.isNotEmpty ? ' para "${state.busca}"' : ''}',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          );
        }
        final c = state.items[i - 1];
        final sub = [
          formatarTelefone(c.telefone),
          c.localizacao,
        ].where((s) => s.isNotEmpty).join(' · ');
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: corAcaoSocial.withValues(alpha: 0.12),
              foregroundColor: corAcaoSocial,
              child: Text(iniciais(c.nome),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            title: Text(c.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: sub.isEmpty ? null : Text(sub),
            trailing: widget.evento.ativo
                ? SePodeVer(
                    permissao: Permissoes.acaoSocialAtender,
                    child: FilledButton.tonal(
                      onPressed: () => atenderPaciente(context, ref,
                          evento: widget.evento,
                          eleitorId: c.id,
                          nome: c.nome),
                      // O tema da aos botoes largura minima INFINITA
                      // (largura total). No trailing de um ListTile isso
                      // consome o tile inteiro e aborta o layout da lista
                      // (aba em branco). Largura minima zero aqui.
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Atender'),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

// ── Aba Vagas ───────────────────────────────────────────────────────────────

class _VagasTab extends ConsumerWidget {
  const _VagasTab({required this.eventoId});

  final String eventoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(especialidadesEventoProvider(eventoId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final larguraTela = MediaQuery.sizeOf(context).width;
    final colunas = larguraTela > 900 ? 4 : (larguraTela > 600 ? 3 : 2);

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(especialidadesEventoProvider(eventoId)),
      child: async.when(
        loading: () => GridView.count(
          crossAxisCount: colunas,
          padding: const EdgeInsets.all(AppSpacing.md),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.6,
          children: List.generate(6, (_) => ShimmerSkeleton.card(height: 90)),
        ),
        error: (e, _) => ListView(children: [
          AppEmptyState(
            title: 'Não foi possível carregar as vagas',
            subtitle: mensagemErroAcaoSocial(e),
            actionLabel: 'Tentar novamente',
            onAction: () =>
                ref.invalidate(especialidadesEventoProvider(eventoId)),
          ),
        ]),
        data: (lista) {
          final itens = lista
              .where((e) => e.ativo && e.totalVagas > 0)
              .toList(growable: false);
          if (itens.isEmpty) {
            return ListView(children: const [
              AppEmptyState(
                title: 'Sem especialidades',
                subtitle: 'Configure as vagas do evento no painel web.',
              ),
            ]);
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: colunas,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.6,
            ),
            itemCount: itens.length,
            itemBuilder: (_, i) {
              final e = itens[i];
              final cor = corNivelVagas(e.nivel, cs);
              final progresso = (e.vagasUtilizadas / e.totalVagas).clamp(0.0, 1.0);
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          e.nome,
                          style: tt.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: progresso,
                          minHeight: 5,
                          backgroundColor: cs.surfaceContainerHighest,
                          color: cor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${e.vagasDisponiveis} livres',
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                          SlotStatusBadge(
                              total: e.totalVagas,
                              utilizadas: e.vagasUtilizadas,
                              compacto: true),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Aba Atendimentos ────────────────────────────────────────────────────────

class _AtendimentosTab extends ConsumerWidget {
  const _AtendimentosTab({required this.evento});

  final EventoAcaoSocial evento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(atendimentosEventoProvider(evento.id));
    final acoes = ref.watch(acaoSocialAcoesProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(atendimentosEventoProvider(evento.id)),
      child: async.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, __) => ShimmerSkeleton.card(height: 120),
        ),
        error: (e, _) => ListView(children: [
          AppEmptyState(
            title: 'Não foi possível carregar os atendimentos',
            subtitle: mensagemErroAcaoSocial(e),
            actionLabel: 'Tentar novamente',
            onAction: () =>
                ref.invalidate(atendimentosEventoProvider(evento.id)),
          ),
        ]),
        data: (lista) {
          final pacientes = PacienteAtendimentos.agrupar(lista);
          if (pacientes.isEmpty) {
            return ListView(children: const [
              AppEmptyState(
                title: 'Nenhum atendimento ainda',
                subtitle:
                    'Na aba Cadastrados, toque em "Atender" para reservar vagas.',
              ),
            ]);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
            itemCount: pacientes.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final p = pacientes[i];
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                corAcaoSocial.withValues(alpha: 0.12),
                            foregroundColor: corAcaoSocial,
                            child: Text(iniciais(p.nome),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.nome,
                                    style: tt.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                  [
                                    formatarTelefone(p.telefone),
                                    formatarDataHora(p.primeiroAtendimento),
                                  ].where((s) => s.isNotEmpty && s != '—').join(' · '),
                                  style: tt.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          if (p.todosConcluidos)
                            const Icon(Icons.verified_rounded,
                                color: Color(0xFF2E7D32)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final a in p.atendimentos)
                            EspecialidadeChip(
                              atendimento: a,
                              // Toque abre o menu: reabrir / concluir /
                              // cancelar (ou orientacao se ja cancelado).
                              onTap: evento.ativo
                                  ? () => editarAtendimento(context, ref, a)
                                  : null,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.push(
                                  '/home/acao-social/evento/${evento.id}/ficha/${p.eleitorId}'),
                              icon: const Icon(Icons.assignment_rounded, size: 18),
                              label: const Text('Ficha'),
                            ),
                          ),
                          if (p.temPendente && evento.ativo) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: SePodeVer(
                                permissao: Permissoes.acaoSocialAtender,
                                child: FilledButton.icon(
                                  onPressed: acoes.isLoading
                                      ? null
                                      : () => _concluirTodos(context, ref, p),
                                  icon: const Icon(Icons.task_alt_rounded, size: 18),
                                  label: const Text('Concluir'),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _concluirTodos(
      BuildContext context, WidgetRef ref, PacienteAtendimentos p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Concluir atendimento'),
        content: Text(
            'Marcar como concluídos todos os atendimentos pendentes de ${p.nome}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Concluir')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final sucesso = await ref.read(acaoSocialAcoesProvider.notifier).concluirTodos(
          eventoId: evento.id,
          eleitorId: p.eleitorId,
          atendimentos: p.atendimentos,
        );
    if (!context.mounted) return;
    final erro = ref.read(acaoSocialAcoesProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sucesso
          ? 'Atendimentos de ${p.nome} concluídos.'
          : (erro ?? 'Não foi possível concluir.')),
    ));
  }

}
