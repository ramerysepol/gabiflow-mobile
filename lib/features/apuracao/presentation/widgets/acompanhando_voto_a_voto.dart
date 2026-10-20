import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/friendly_error.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/apuracao_seguir_model.dart';
import '../ameacas.dart';
import '../apuracao_format.dart';
import '../providers/apuracao_providers.dart';
import 'eyebrow_action_header.dart';
import 'projecao_badge.dart';

const _corAmeaca = Color(0xFFDC2626);
const _corFolego = Color(0xFF16A34A);
const _corEmpate = Color(0xFFD97706);

/// Ações disponíveis no menu "⋯" de cada candidato acompanhado.
enum _AcaoSeguido { tornarPrincipal, abrirDetalhes, pararDeAcompanhar }

/// Card "Acompanhando voto a voto" da tela principal da apuração: lista os
/// candidatos não-principais acompanhados (com a diferença de votos para o
/// principal quando disputam o mesmo cargo/UF) e permite acompanhar mais
/// alguém — por busca livre ou pelas sugestões de "quem está ameaçando a
/// vaga" do principal (colegas de partido perto da linha de corte e
/// concorrentes diretos).
class AcompanhandoVotoAVotoCard extends ConsumerStatefulWidget {
  const AcompanhandoVotoAVotoCard({
    super.key,
    required this.principal,
    required this.outros,
    required this.onAbrirDetalhe,
  });

  final ApuracaoSeguido principal;
  final List<ApuracaoSeguido> outros;
  final void Function(String sqcand) onAbrirDetalhe;

  @override
  ConsumerState<AcompanhandoVotoAVotoCard> createState() =>
      _AcompanhandoVotoAVotoCardState();
}

class _AcompanhandoVotoAVotoCardState
    extends ConsumerState<AcompanhandoVotoAVotoCard> {
  bool _expandido = false;
  bool _processando = false;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onBuscaChanged(String texto) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = texto.trim());
    });
  }

  void _fecharBusca() {
    setState(() {
      _expandido = false;
      _query = '';
      _searchCtrl.clear();
    });
  }

  Future<void> _acompanhar(String sqcand, String nomeUrna) async {
    setState(() => _processando = true);
    try {
      await ref.read(apuracaoSeguidosProvider.notifier).seguir(sqcand);
      // Sucesso: fecha o painel de busca e volta pra lista, onde o novo
      // acompanhado já aparece — sem isso o usuário não via o resultado da
      // própria ação sem fechar a busca manualmente.
      if (mounted) {
        setState(() {
          _expandido = false;
          _query = '';
          _searchCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nomeUrna agora está sendo acompanhado')),
        );
      }
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _deixarDeSeguir(String sqcand) async {
    setState(() => _processando = true);
    try {
      await ref.read(apuracaoSeguidosProvider.notifier).deixarDeSeguir(sqcand);
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _tornarPrincipal(String sqcand) async {
    setState(() => _processando = true);
    try {
      await ref.read(apuracaoSeguidosProvider.notifier).tornarPrincipal(sqcand);
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _mostrarErro(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagemAmigavel(e))));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EyebrowActionHeader(
          label: 'ACOMPANHANDO VOTO A VOTO',
          action: !_expandido
              ? TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => setState(() => _expandido = true),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Acompanhar outro'),
                )
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Fechar busca',
                  visualDensity: VisualDensity.compact,
                  onPressed: _fecharBusca,
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A lista de quem já é acompanhado sempre aparece acima do
              // painel de busca — assim, ao abrir o painel pra acompanhar
              // mais alguém, quem já está sendo acompanhado continua visível.
              if (widget.outros.isNotEmpty) ...[
                Column(
                  children: widget.outros
                      .map(
                        (o) => _LinhaSeguido(
                          seguido: o,
                          principal: widget.principal,
                          processando: _processando,
                          onTornarPrincipal: () => _tornarPrincipal(o.sqcand),
                          onDeixarDeSeguir: () => _deixarDeSeguir(o.sqcand),
                          onAbrirDetalhe: () => widget.onAbrirDetalhe(o.sqcand),
                        ),
                      )
                      .toList(),
                ),
                if (_expandido) const SizedBox(height: AppSpacing.md),
              ] else if (!_expandido)
                Text(
                  'Acompanhe os colegas de partido que disputam a mesma vaga, '
                  'os concorrentes diretos e os candidatos da sua torcida. '
                  'Cada um ganha alertas e aparece aqui com a diferença de '
                  'votos para ${widget.principal.nomeUrna}.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              if (_expandido) ...[
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: _onBuscaChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou número...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _query.isEmpty
                    ? _AmeacasPreview(
                        principal: widget.principal,
                        outros: widget.outros,
                        processando: _processando,
                        onAcompanhar: _acompanhar,
                      )
                    : _ResultadosBusca(
                        query: _query,
                        uf: widget.principal.uf,
                        processando: _processando,
                        onAcompanhar: _acompanhar,
                      ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Candidatos já acompanhados ───────────────────────────────────────────

class _LinhaSeguido extends StatelessWidget {
  const _LinhaSeguido({
    required this.seguido,
    required this.principal,
    required this.processando,
    required this.onTornarPrincipal,
    required this.onDeixarDeSeguir,
    required this.onAbrirDetalhe,
  });

  final ApuracaoSeguido seguido;
  final ApuracaoSeguido principal;
  final bool processando;
  final VoidCallback onTornarPrincipal;
  final VoidCallback onDeixarDeSeguir;
  final VoidCallback onAbrirDetalhe;

  /// Diferença de votos para o principal, já com a cor semântica — ou
  /// `null` quando não disputam o mesmo cargo/UF (sem comparação possível).
  (String texto, Color cor)? _diferenca(ColorScheme cs) {
    if (seguido.cargo == null || seguido.cargo != principal.cargo) {
      return null;
    }
    if ((seguido.uf ?? '').toLowerCase() !=
        (principal.uf ?? '').toLowerCase()) {
      return null;
    }
    final diff = seguido.votos - principal.votos;
    if (diff == 0) {
      if (seguido.votos == 0 && principal.votos == 0) {
        return ('aguardando votos', cs.onSurfaceVariant);
      }
      return ('empatado', _corEmpate);
    }
    if (diff > 0) {
      return ('${formatarVotosApuracao(diff)} à frente', _corAmeaca);
    }
    return ('${formatarVotosApuracao(diff.abs())} atrás', _corFolego);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final diferenca = _diferenca(cs);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAbrirDetalhe,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Linha 1: estrela + nome + número + menu "⋯" ---
              // Nada aqui pode ser cortado: o nome usa ellipsis, mas o
              // número e o menu sempre ficam inteiros e visíveis.
              Row(
                children: [
                  Icon(
                    Icons.star_outline_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      seguido.nomeUrna,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (seguido.numero != null) ...[
                    const SizedBox(width: 6),
                    _ChipTexto(
                      texto: seguido.numero!,
                      cor: cs.primary,
                      negrito: true,
                    ),
                  ],
                  const SizedBox(width: 2),
                  PopupMenuButton<_AcaoSeguido>(
                    enabled: !processando,
                    tooltip: 'Mais ações',
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    splashRadius: 18,
                    position: PopupMenuPosition.under,
                    onSelected: (acao) {
                      switch (acao) {
                        case _AcaoSeguido.tornarPrincipal:
                          onTornarPrincipal();
                        case _AcaoSeguido.abrirDetalhes:
                          onAbrirDetalhe();
                        case _AcaoSeguido.pararDeAcompanhar:
                          onDeixarDeSeguir();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _AcaoSeguido.tornarPrincipal,
                        child: _ItemMenuSeguido(
                          icone: Icons.star_outline_rounded,
                          texto: 'Tornar principal',
                        ),
                      ),
                      PopupMenuItem(
                        value: _AcaoSeguido.abrirDetalhes,
                        child: _ItemMenuSeguido(
                          icone: Icons.open_in_new_rounded,
                          texto: 'Abrir detalhes',
                        ),
                      ),
                      PopupMenuItem(
                        value: _AcaoSeguido.pararDeAcompanhar,
                        child: _ItemMenuSeguido(
                          icone: Icons.close_rounded,
                          texto: 'Parar de acompanhar',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // --- Linha 2: estatísticas compactas, rolam na horizontal se
              // não couberem — nada fica escondido, só precisa arrastar. ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${formatarVotosApuracao(seguido.votos)} votos',
                        maxLines: 1,
                        style: tt.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (seguido.pct != null) ...[
                      const SizedBox(width: 8),
                      _ChipTexto(
                        texto: '${formatarPctApuracao(seguido.pct)} válidos',
                        cor: cs.onSurfaceVariant,
                      ),
                    ],
                    if (seguido.posicao != null) ...[
                      const SizedBox(width: 6),
                      _ChipTexto(
                        texto: '${seguido.posicao}º lugar',
                        cor: cs.onSurfaceVariant,
                      ),
                    ],
                    if (diferenca != null) ...[
                      const SizedBox(width: 6),
                      _ChipTexto(
                        texto: diferenca.$1,
                        cor: diferenca.$2,
                        negrito: true,
                        preenchido: true,
                      ),
                    ],
                    const SizedBox(width: 6),
                    ProjecaoBadge(
                      projecao: seguido.projecao,
                      projecaoVia: seguido.projecaoVia,
                      pctSecoes: seguido.pctSecoes,
                      compacto: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip de texto compacto usado na linha de estatísticas de cada
/// candidato acompanhado (% válidos, posição, diferença vs. principal...).
class _ChipTexto extends StatelessWidget {
  const _ChipTexto({
    required this.texto,
    required this.cor,
    this.negrito = false,
    this.preenchido = false,
  });

  final String texto;
  final Color cor;
  final bool negrito;

  /// Quando `true`, usa fundo tingido da cor (destaque tipo "badge").
  final bool preenchido;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final conteudo = Text(
      texto,
      maxLines: 1,
      style: tt.labelSmall?.copyWith(
        color: cor,
        fontWeight: negrito ? FontWeight.w700 : FontWeight.w500,
      ),
    );
    if (!preenchido) {
      return FittedBox(fit: BoxFit.scaleDown, child: conteudo);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: FittedBox(fit: BoxFit.scaleDown, child: conteudo),
    );
  }
}

/// Item padrão (ícone + texto) do menu "⋯" de um candidato acompanhado.
class _ItemMenuSeguido extends StatelessWidget {
  const _ItemMenuSeguido({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icone, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(texto),
      ],
    );
  }
}

// ─── "Quem está ameaçando a vaga de..." ───────────────────────────────────

class _AmeacasPreview extends ConsumerWidget {
  const _AmeacasPreview({
    required this.principal,
    required this.outros,
    required this.processando,
    required this.onAcompanhar,
  });

  final ApuracaoSeguido principal;
  final List<ApuracaoSeguido> outros;
  final bool processando;
  final void Function(String sqcand, String nomeUrna) onAcompanhar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(apuracaoCandidatoProvider(principal.sqcand));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Text(
        'Não foi possível carregar sugestões agora.',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      data: (dados) {
        final jaSeguidos = {principal.sqcand, ...outros.map((o) => o.sqcand)};
        final ameacas = calcularAmeacasApuracao(dados, jaSeguidos);
        if (ameacas.isEmpty) {
          return Text(
            'Nenhuma ameaça identificada por perto no momento.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quem está ameaçando a vaga de ${principal.nomeUrna}',
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...ameacas.map(
              (a) => _LinhaComAcompanhar(
                numero: a.numero,
                nomeUrna: a.nomeUrna,
                subtitulo: a.motivo,
                processando: processando,
                onAcompanhar: () => onAcompanhar(a.sqcand, a.nomeUrna),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Busca livre ───────────────────────────────────────────────────────────

class _ResultadosBusca extends ConsumerWidget {
  const _ResultadosBusca({
    required this.query,
    required this.uf,
    required this.processando,
    required this.onAcompanhar,
  });

  final String query;
  final String? uf;
  final bool processando;
  final void Function(String sqcand, String nomeUrna) onAcompanhar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(
      apuracaoBuscaProvider(ApuracaoBuscaParams(q: query, uf: uf, limit: 10)),
    );

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        mensagemAmigavel(e),
        style: tt.bodySmall?.copyWith(color: cs.error),
      ),
      data: (busca) {
        final itens = busca.itens.where((i) => !i.seguido).toList();
        if (itens.isEmpty) {
          return Text(
            'Nenhum candidato encontrado.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          );
        }
        return Column(
          children: itens
              .map(
                (item) => _LinhaComAcompanhar(
                  numero: item.numero,
                  nomeUrna: item.nomeUrna,
                  subtitulo: [
                    if (item.cargoNome != null) item.cargoNome,
                    if (item.partido != null) item.partido,
                  ].join(' · '),
                  processando: processando,
                  onAcompanhar: () => onAcompanhar(item.sqcand, item.nomeUrna),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _LinhaComAcompanhar extends StatelessWidget {
  const _LinhaComAcompanhar({
    required this.numero,
    required this.nomeUrna,
    required this.subtitulo,
    required this.processando,
    required this.onAcompanhar,
  });

  final String? numero;
  final String nomeUrna;
  final String subtitulo;
  final bool processando;
  final VoidCallback onAcompanhar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          if (numero != null) ...[
            Text(
              numero!,
              style: tt.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeUrna,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitulo.isNotEmpty)
                  Text(
                    subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: processando ? null : onAcompanhar,
            child: const Text('Acompanhar'),
          ),
        ],
      ),
    );
  }
}
