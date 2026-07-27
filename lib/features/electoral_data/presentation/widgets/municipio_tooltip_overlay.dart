import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ibge_municipio_model.dart';
import '../../data/models/municipio_voto_model.dart';
import '../../data/services/mesorregiao_colors.dart';
import '../providers/eleitoral_providers.dart';
import 'numero_formatado.dart';

// ─── Constantes de setor econômico ───────────────────────────────────────────

class _SetorInfo {
  final String label;
  final String short;
  final IconData icon;
  final Color color;
  final String hint;

  const _SetorInfo({
    required this.label,
    required this.short,
    required this.icon,
    required this.color,
    required this.hint,
  });
}

const _setorMeta = <String, _SetorInfo>{
  'Agropecuária': _SetorInfo(
    label: 'Agropecuária',
    short: 'Agro',
    icon: Icons.agriculture,
    color: Color(0xFF16A34A),
    hint: 'Projetos rurais, crédito agrícola, irrigação, assistência técnica',
  ),
  'Indústria': _SetorInfo(
    label: 'Indústria',
    short: 'Indústria',
    icon: Icons.factory,
    color: Color(0xFF0891B2),
    hint: 'Incentivos fiscais, infraestrutura, qualificação industrial',
  ),
  'Serviços': _SetorInfo(
    label: 'Serviços',
    short: 'Serviços',
    icon: Icons.store,
    color: Color(0xFF7C3AED),
    hint: 'Comércio, turismo, educação profissional, empreendedorismo',
  ),
  'Adm. Pública': _SetorInfo(
    label: 'Administração Pública',
    short: 'Adm. Pública',
    icon: Icons.account_balance,
    color: Color(0xFFD97706),
    hint:
        'Economia depende do setor público — priorizar geração de emprego privado',
  ),
};

// ─── Overlay controller ───────────────────────────────────────────────────────

/// Tooltip flutuante que aparece acima do dedo ao segurar um município.
/// Usa [OverlayEntry] para posicionamento livre sem ser bloqueado pelo layout.
class MunicipioTooltipOverlay {
  OverlayEntry? _entry;

  void show({
    required BuildContext context,
    required Offset position,
    required MunicipioVotoModel municipio,
    // ibge pode ser null — o widget buscará via provider
    IbgeMunicipioModel? ibge,
  }) {
    HapticFeedback.lightImpact();
    hide();
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (_) => _TooltipWidget(
        position: position,
        municipio: municipio,
        ibgePreloaded: ibge,
      ),
    );
    overlay.insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }

  bool get isVisible => _entry != null;
}

// ─── Widget principal ─────────────────────────────────────────────────────────

class _TooltipWidget extends ConsumerStatefulWidget {
  const _TooltipWidget({
    required this.position,
    required this.municipio,
    this.ibgePreloaded,
  });

  final Offset position;
  final MunicipioVotoModel municipio;
  final IbgeMunicipioModel? ibgePreloaded;

  @override
  ConsumerState<_TooltipWidget> createState() => _TooltipWidgetState();
}

class _TooltipWidgetState extends ConsumerState<_TooltipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  final GlobalKey _cardKey = GlobalKey();
  double? _measuredHeight;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    // Mede no primeiro frame e só então faz fade-in (evita flash em pos errada).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _remeasure();
      if (mounted) _ctrl.forward();
    });
  }

  void _remeasure() {
    if (!mounted) return;
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    final h = box?.size.height;
    if (h != null && (_measuredHeight == null || (h - _measuredHeight!).abs() > 0.5)) {
      setState(() => _measuredHeight = h);
    }
  }

  @override
  void didUpdateWidget(covariant _TooltipWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // IBGE chega via Riverpod e não dispara didUpdateWidget. Remede sempre
    // que dependências mudam (inclui quando o provider reatualiza).
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cardWidth = 280.0;
    final screen = MediaQuery.sizeOf(context);
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom + 90; // bottom nav
    final safeTop = MediaQuery.viewPaddingOf(context).top + 80; // app bar
    final maxCardHeight = screen.height - safeTop - safeBottom - 8;

    // Enquanto não mediu, o card fica invisível (opacity 0 via _ctrl que
    // ainda não fez forward). Assume altura máxima pra posicionar no pior caso.
    final cardHeight =
        math.min(_measuredHeight ?? maxCardHeight, maxCardHeight);

    double left = widget.position.dx - cardWidth / 2;
    left = left.clamp(12.0, screen.width - cardWidth - 12);

    // Espaço disponível acima e abaixo do dedo.
    const gap = 16.0;
    final espacoAcima = widget.position.dy - safeTop - gap;
    final espacoAbaixo =
        screen.height - safeBottom - widget.position.dy - gap;

    // Escolhe o lado que tem MAIS espaço — garante melhor aproveitamento.
    final preferirAcima = espacoAcima > espacoAbaixo;

    double top;
    if (preferirAcima) {
      // Ancora a base do card logo acima do dedo
      top = widget.position.dy - cardHeight - gap;
    } else {
      // Ancora o topo do card logo abaixo do dedo
      top = widget.position.dy + gap;
    }
    // Clamp absoluto: card NUNCA sai da área útil da tela.
    final minTop = safeTop;
    final maxTop = screen.height - safeBottom - cardHeight;
    top = top.clamp(minTop, math.max(minTop, maxTop));

    final mesoColor = MesorregiaoColors.getCor(widget.municipio.idMunicipio);
    final mesoNome = MesorregiaoColors.getNome(widget.municipio.idMunicipio);

    // Usa dado pré-carregado ou assiste o provider
    final ibgeAsync = ref.watch(ibgeMunicipioProvider(widget.municipio.idMunicipio));
    final ibge = widget.ibgePreloaded ?? ibgeAsync.valueOrNull;
    final ibgeLoading = ibgeAsync.isLoading && widget.ibgePreloaded == null;

    return Positioned(
      left: left,
      top: top,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxCardHeight,
              maxWidth: cardWidth,
            ),
            child: Container(
              key: _cardKey,
              width: cardWidth,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: mesoColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.26),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // ── 1. Header: mesorregião · microrregião ──────────────────
                _HeaderMeso(
                  mesoNome: mesoNome,
                  mesoColor: mesoColor,
                  microrregiao: ibge?.microrregiao,
                ),
                const SizedBox(height: 5),

                // ── 2. Nome do município ───────────────────────────────────
                Text(
                  widget.municipio.nomeMunicipio,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // ── 3. Votos grandes ──────────────────────────────────────
                _VotosBlock(
                  municipio: widget.municipio,
                  mesoColor: mesoColor,
                ),
                const Divider(height: 14, thickness: 0.5),

                // ── 4. Dados IBGE ─────────────────────────────────────────
                _IbgeBlock(
                  ibge: ibge,
                  loading: ibgeLoading,
                  votos: widget.municipio.votosMunicipio,
                  mesoColor: mesoColor,
                ),

                // ── 5. Composição econômica ────────────────────────────────
                if (ibge?.composicao != null) ...[
                  const Divider(height: 14, thickness: 0.5),
                  _ComposicaoBlock(composicao: ibge!.composicao!),
                ],

                // ── 6. Rodapé hint ────────────────────────────────────────
                const SizedBox(height: 6),
                    Text(
                      'Toque para ver detalhes completos →',
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header mesorregião ───────────────────────────────────────────────────────

class _HeaderMeso extends StatelessWidget {
  const _HeaderMeso({
    required this.mesoNome,
    required this.mesoColor,
    this.microrregiao,
  });

  final String mesoNome;
  final Color mesoColor;
  final String? microrregiao;

  @override
  Widget build(BuildContext context) {
    final hasMicro =
        microrregiao != null && microrregiao!.isNotEmpty && microrregiao != mesoNome;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: mesoColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            mesoNome.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: mesoColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (hasMicro) ...[
          Text(
            '·',
            style: TextStyle(
              fontSize: 9,
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          Text(
            microrregiao!,
            style: TextStyle(
              fontSize: 9,
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Bloco de votos ───────────────────────────────────────────────────────────

class _VotosBlock extends StatelessWidget {
  const _VotosBlock({
    required this.municipio,
    required this.mesoColor,
  });

  final MunicipioVotoModel municipio;
  final Color mesoColor;

  @override
  Widget build(BuildContext context) {
    if (municipio.votosMunicipio == 0) {
      return Text(
        'Sem votos',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formatarNumero(municipio.votosMunicipio),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: mesoColor,
                height: 1,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'votos',
              style: TextStyle(
                fontSize: 12,
                color: mesoColor.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${formatarDecimal(municipio.percentualMunicipio, casas: 2)}% do total do candidato',
          style: TextStyle(
            fontSize: 11,
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

// ─── Bloco IBGE ───────────────────────────────────────────────────────────────

class _IbgeBlock extends StatelessWidget {
  const _IbgeBlock({
    required this.ibge,
    required this.loading,
    required this.votos,
    required this.mesoColor,
  });

  final IbgeMunicipioModel? ibge;
  final bool loading;
  final int votos;
  final Color mesoColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.layers_outlined, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'DADOS DO IBGE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (loading && ibge == null)
          // Loading inline
          Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Carregando...',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          )
        else if (ibge != null)
          _IbgeGrid(ibge: ibge!, votos: votos, mesoColor: mesoColor)
        else
          Text(
            'Sem dados IBGE.',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),

        // Código IBGE em monospace
        if (ibge != null && ibge!.id.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Código IBGE ${ibge!.id}',
            style: TextStyle(
              fontSize: 9,
              fontFamily: 'monospace',
              color: cs.onSurfaceVariant.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Grid 2×2 IBGE ────────────────────────────────────────────────────────────

class _IbgeGrid extends StatelessWidget {
  const _IbgeGrid({
    required this.ibge,
    required this.votos,
    required this.mesoColor,
  });

  final IbgeMunicipioModel ibge;
  final int votos;
  final Color mesoColor;

  @override
  Widget build(BuildContext context) {
    final votosPorMil =
        ibge.populacao > 0 ? (votos / ibge.populacao * 1000) : null;
    final cs = Theme.of(context).colorScheme;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 2.6,
      children: [
        _IbgeStat(
          icon: Icons.people_outline,
          label: 'Pop.',
          value: formatarNumero(ibge.populacao),
          suffix: 'hab.',
        ),
        _IbgeStat(
          icon: Icons.trending_up,
          label: 'PIB/cap',
          value: formatarMoeda(ibge.pibPerCapita),
        ),
        if (votosPorMil != null)
          _IbgeStat(
            icon: Icons.bar_chart,
            label: 'Votos/1.000 hab.',
            value: formatarDecimal(votosPorMil, casas: 2),
            highlight: mesoColor,
          )
        else
          const SizedBox.shrink(),
        _IbgeStat(
          icon: Icons.explore_outlined,
          label: 'Mesorregião',
          value: ibge.mesorregiao,
          small: true,
          cs: cs,
        ),
      ],
    );
  }
}

// ─── Stat card individual ─────────────────────────────────────────────────────

class _IbgeStat extends StatelessWidget {
  const _IbgeStat({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
    this.small = false,
    this.highlight,
    this.cs,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? suffix;
  final bool small;
  final Color? highlight;
  final ColorScheme? cs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = cs ?? Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 9, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 0.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: small ? 9 : 10,
                    fontWeight: FontWeight.w700,
                    color: highlight,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (suffix != null)
                Text(
                  ' $suffix',
                  style: TextStyle(
                    fontSize: 8,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bloco composição econômica ───────────────────────────────────────────────

class _ComposicaoBlock extends StatelessWidget {
  const _ComposicaoBlock({required this.composicao});

  final ComposicaoEconomica composicao;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Segmentos na mesma ordem do desktop
    final segmentos = [
      (key: 'Agropecuária', valor: composicao.agropecuaria),
      (key: 'Indústria', valor: composicao.industria),
      (key: 'Serviços', valor: composicao.servicos),
      (key: 'Adm. Pública', valor: composicao.admPublica),
    ];
    final total =
        segmentos.fold(0.0, (acc, s) => acc + s.valor);

    final dominante = composicao.setorDominante;
    final domMeta = _setorMeta[dominante];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header "Economia"
        Row(
          children: [
            Icon(Icons.work_outline, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'ECONOMIA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Barra horizontal empilhada
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (final s in segmentos)
                  if (s.valor > 0.5 && total > 0)
                    Flexible(
                      flex: ((s.valor / total) * 100).round().clamp(1, 100),
                      child: Container(
                        color: _setorMeta[s.key]?.color ?? cs.outlineVariant,
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Grid 2×2 de percentuais
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
          childAspectRatio: 2.8,
          children: segmentos.map((s) {
            final meta = _setorMeta[s.key];
            final isDom = dominante == s.key;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: isDom
                    ? (meta?.color ?? cs.primary).withValues(alpha: 0.1)
                    : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isDom
                      ? (meta?.color ?? cs.primary).withValues(alpha: 0.6)
                      : cs.outlineVariant,
                  width: isDom ? 1.0 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    meta?.icon ?? Icons.circle,
                    size: 9,
                    color: meta?.color ?? cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      meta?.short ?? s.key,
                      style: TextStyle(
                        fontSize: 8,
                        color: cs.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${formatarDecimal(s.valor, casas: 1)}%',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: meta?.color ?? cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),

        // Card vocação dominante
        if (domMeta != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: domMeta.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: domMeta.color.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(domMeta.icon, size: 11, color: domMeta.color),
                    const SizedBox(width: 4),
                    Text(
                      'Vocação: ${domMeta.label}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: domMeta.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  domMeta.hint,
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
