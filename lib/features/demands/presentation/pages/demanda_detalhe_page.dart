import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissoes.dart';
import '../../../../core/network/friendly_error.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/demanda_model.dart';
import '../providers/demanda_providers.dart';
import '../widgets/demanda_anexos_section.dart';
import '../widgets/demanda_cabecalho.dart';
import '../widgets/demanda_encaminhamentos.dart';
import '../widgets/demanda_saude_card.dart';
import '../widgets/demanda_sheet_base.dart';
import '../widgets/demanda_sheet_gestao.dart';
import '../widgets/demanda_sheet_status.dart';
import '../widgets/demanda_timeline.dart';

/// Detalhe da demanda: cabeçalho, ações, saúde, encaminhamentos, anexos e timeline.
class DemandaDetalhePage extends ConsumerWidget {
  const DemandaDetalhePage({super.key, required this.id});

  final int id;

  Future<void> _excluir(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir demanda?'),
        content: const Text('Ela deixará de aparecer na Mesa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(demandaDataSourceProvider).excluir(id);
      ref.read(demandaListaProvider.notifier).recarregar(silencioso: true);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagemAmigavel(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(demandaDetalheProvider(id));
    final podeEditar = ref.watch(
      temPermissaoProvider(Permissoes.demandasEditar),
    );
    final podeExcluir = ref.watch(
      temPermissaoProvider(Permissoes.demandasExcluir),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(async.valueOrNull?.protocolo ?? 'Demanda'),
        actions: [
          if (async.hasValue && (podeEditar || podeExcluir))
            PopupMenuButton<String>(
              tooltip: 'Mais opções',
              onSelected: (v) {
                final d = async.requireValue;
                if (v == 'editar') {
                  abrirSheetDemanda<bool>(
                    context,
                    (_) => DemandaSheetEditar(demanda: d),
                  );
                } else {
                  _excluir(context, ref);
                }
              },
              itemBuilder: (_) => [
                if (podeEditar)
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                if (podeExcluir)
                  const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
              ],
            ),
        ],
      ),
      body: async.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            ShimmerSkeleton.card(height: 180),
            const SizedBox(height: AppSpacing.md),
            ShimmerSkeleton.card(height: 120),
          ],
        ),
        error: (e, _) => AppEmptyState(
          title: 'Não foi possível abrir a demanda',
          subtitle: mensagemAmigavel(e),
          actionLabel: 'Tentar de novo',
          onAction: () => ref.invalidate(demandaDetalheProvider(id)),
        ),
        data: (d) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(demandaDetalheProvider(id));
            await ref.read(demandaDetalheProvider(id).future);
          },
          child: _Corpo(demanda: d),
        ),
      ),
    );
  }
}

class _Corpo extends ConsumerWidget {
  const _Corpo({required this.demanda});
  final DemandaDetalhe demanda;

  Widget _secao(BuildContext context, String titulo, Widget filho) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: tt.titleSmall),
          const SizedBox(height: 8),
          filho,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = demanda;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final podeStatus = ref.watch(
      temPermissaoProvider(Permissoes.demandasStatus),
    );
    final podeEditar = ref.watch(
      temPermissaoProvider(Permissoes.demandasEditar),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        DemandaCabecalho(demanda: d),
        if (podeStatus || podeEditar) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (podeStatus)
                _Acao(
                  Icons.swap_horiz_rounded,
                  'Mudar status',
                  (c) => DemandaSheetStatus(demanda: d),
                  primaria: true,
                ),
              if (podeStatus)
                _Acao(
                  Icons.person_add_alt_1_outlined,
                  'Atribuir',
                  (c) => DemandaSheetAtribuir(demanda: d),
                ),
              if (podeStatus)
                _Acao(
                  Icons.send_rounded,
                  'Encaminhar',
                  (c) => DemandaSheetEncaminhar(demanda: d),
                ),
              if (podeStatus)
                _Acao(
                  Icons.reply_rounded,
                  'Retornar ao munícipe',
                  (c) => DemandaSheetRetorno(demanda: d),
                ),
              if (podeEditar)
                _Acao(
                  Icons.attach_file_rounded,
                  'Anexar',
                  (c) => DemandaSheetAnexar(demanda: d),
                ),
            ],
          ),
        ],
        if (d.ehSaude && d.saude != null) ...[
          const SizedBox(height: AppSpacing.lg),
          DemandaSaudeCard(demanda: d),
        ],
        _secao(
          context,
          'Pedido',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.descricao.isEmpty ? 'Sem descrição.' : d.descricao,
                style: tt.bodyMedium,
              ),
              if (d.orgao != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Órgão: ${d.orgao!.nome}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              if (d.observacoes != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Obs.: ${d.observacoes}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              if (d.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final t in d.tags)
                      Chip(
                        label: Text(t),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (d.encaminhamentos.isNotEmpty)
          _secao(
            context,
            'Encaminhamentos',
            DemandaEncaminhamentos(itens: d.encaminhamentos),
          ),
        if (d.vinculos.isNotEmpty)
          _secao(
            context,
            'Vínculos',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final v in d.vinculos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(v, style: tt.bodySmall),
                  ),
              ],
            ),
          ),
        _secao(
          context,
          'Anexos (${d.anexos.length})',
          DemandaAnexosSection(demanda: d),
        ),
        _secao(
          context,
          'Histórico',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (podeEditar) ...[
                DemandaCaixaComentario(demandaId: d.id),
                const SizedBox(height: 12),
              ],
              DemandaTimeline(eventos: d.eventos),
            ],
          ),
        ),
      ],
    );
  }
}

/// Botão de ação que abre um bottom sheet.
class _Acao extends StatelessWidget {
  const _Acao(this.icone, this.rotulo, this.sheet, {this.primaria = false});

  final IconData icone;
  final String rotulo;
  final Widget Function(BuildContext) sheet;
  final bool primaria;

  @override
  Widget build(BuildContext context) {
    void abrir() => abrirSheetDemanda<bool>(context, sheet);
    return primaria
        ? FilledButton.icon(
            onPressed: abrir,
            icon: Icon(icone, size: 18),
            label: Text(rotulo),
          )
        : OutlinedButton.icon(
            onPressed: abrir,
            icon: Icon(icone, size: 18),
            label: Text(rotulo),
          );
  }
}
