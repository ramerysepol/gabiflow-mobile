import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/friendly_error.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../electoral_data/presentation/widgets/erro_inline.dart';
import '../../data/models/apuracao_territorio_model.dart';
import '../apuracao_format.dart';
import '../providers/apuracao_providers.dart';
import 'barra_progresso.dart';

enum _AbaTerritorio { ondeFalta, altas, quedas }

const _corVerde = Color(0xFF16A34A);
const _corVermelho = Color(0xFFDC2626);

/// Seção "Onde está o voto que falta" da ficha do candidato: projeção final
/// (central + faixa min/max) e os municípios que mais pesam no resultado —
/// onde ainda falta apurar, onde a votação mais subiu e onde mais caiu em
/// relação a 2022. Usa seu próprio provider ([apuracaoTerritorioProvider]),
/// mais pesado que o resto da ficha — ver poll de 60s na página.
class OndeFaltaOVotoSection extends ConsumerStatefulWidget {
  const OndeFaltaOVotoSection({super.key, required this.sqcand});

  final String sqcand;

  @override
  ConsumerState<OndeFaltaOVotoSection> createState() =>
      _OndeFaltaOVotoSectionState();
}

class _OndeFaltaOVotoSectionState extends ConsumerState<OndeFaltaOVotoSection> {
  _AbaTerritorio _aba = _AbaTerritorio.ondeFalta;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(apuracaoTerritorioProvider(widget.sqcand));

    return async.when(
      skipLoadingOnRefresh: true,
      loading: () => ShimmerSkeleton.card(height: 220),
      error: (e, _) => ErroInline(
        mensagem: mensagemAmigavel(e),
        onRetry: () =>
            ref.invalidate(apuracaoTerritorioProvider(widget.sqcand)),
      ),
      data: (territorio) => _OndeFaltaConteudo(
        territorio: territorio,
        aba: _aba,
        onAbaChanged: (a) => setState(() => _aba = a),
      ),
    );
  }
}

class _OndeFaltaConteudo extends StatelessWidget {
  const _OndeFaltaConteudo({
    required this.territorio,
    required this.aba,
    required this.onAbaChanged,
  });

  final ApuracaoTerritorioModel territorio;
  final _AbaTerritorio aba;
  final void Function(_AbaTerritorio aba) onAbaChanged;

  String _headerBase2022() {
    final b = territorio.base2022;
    if (!b.encontrado) {
      return 'Sem candidato correspondente em 2022 — estimativa baseada só '
          'no ritmo da apuração atual.';
    }
    final partes = <String>[
      if (b.nomeUrna != null) b.nomeUrna! else if (b.nome != null) b.nome!,
      if (b.partido != null) b.partido!,
    ];
    final quem = partes.join(' · ');
    final votos = b.totalVotos != null
        ? '${formatarVotosApuracao(b.totalVotos)} votos'
        : null;
    final municipios = b.municipiosComVoto != null
        ? 'em ${b.municipiosComVoto} município'
              '${b.municipiosComVoto == 1 ? '' : 's'}'
        : null;
    final resto = [votos, municipios].whereType<String>().join(' ');
    return 'Com base no resultado de 2022: $quem'
        '${resto.isNotEmpty ? ' · $resto' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final resumo = territorio.resumo;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _headerBase2022(),
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (territorio.projecao != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ProjecaoFinalLinha(territorio: territorio),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MiniKpi(
                  label: 'Sem apurar',
                  value: '${resumo.semApurar}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniKpi(label: 'Parciais', value: '${resumo.parciais}'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniKpi(
                  label: 'Potencial restante',
                  value: formatarVotosApuracao(resumo.potencialRestante),
                  destaque: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _AbaChip(
                label: 'Onde falta apurar',
                selecionado: aba == _AbaTerritorio.ondeFalta,
                onTap: () => onAbaChanged(_AbaTerritorio.ondeFalta),
              ),
              _AbaChip(
                label: 'Maiores altas vs 2022',
                selecionado: aba == _AbaTerritorio.altas,
                onTap: () => onAbaChanged(_AbaTerritorio.altas),
              ),
              _AbaChip(
                label: 'Maiores quedas vs 2022',
                selecionado: aba == _AbaTerritorio.quedas,
                onTap: () => onAbaChanged(_AbaTerritorio.quedas),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ConteudoAba(aba: aba, territorio: territorio),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Estimativa com base no resultado de 2022 ajustado pelo ritmo da '
            'apuração atual (ou só pelo ritmo, sem correspondência em 2022); '
            'pode mudar até o fim da contagem.',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Projeção final ───────────────────────────────────────────────────────

class ProjecaoFinalLinha extends StatelessWidget {
  const ProjecaoFinalLinha({super.key, required this.territorio});

  final ApuracaoTerritorioModel territorio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p = territorio.projecao!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.insights_rounded, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              children: [
                const TextSpan(text: 'Projeção final: '),
                TextSpan(
                  text:
                      '${formatarVotosApuracao(p.central)} votos '
                      '(${formatarVotosApuracao(p.min)} a '
                      '${formatarVotosApuracao(p.max)})',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: p.baseEm2022
                      ? territorio.razaoVs2022 != null
                            ? ' · com base em 2022 '
                                  '(${formatarRazaoVs2022Apuracao(territorio.razaoVs2022!)})'
                            : ' · com base em 2022'
                      : ' · com base no ritmo da apuração',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Mini KPIs ────────────────────────────────────────────────────────────

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({
    required this.label,
    required this.value,
    this.destaque = false,
  });

  final String label;
  final String value;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: destaque ? cs.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Abas (chip row) ──────────────────────────────────────────────────────

class _AbaChip extends StatelessWidget {
  const _AbaChip({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selecionado,
      onSelected: (_) => onTap(),
      selectedColor: cs.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selecionado ? cs.primary : cs.onSurfaceVariant,
        fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }
}

// ─── Conteúdo por aba ─────────────────────────────────────────────────────

class _ConteudoAba extends StatelessWidget {
  const _ConteudoAba({required this.aba, required this.territorio});

  final _AbaTerritorio aba;
  final ApuracaoTerritorioModel territorio;

  @override
  Widget build(BuildContext context) {
    switch (aba) {
      case _AbaTerritorio.ondeFalta:
        if (territorio.ondeFalta.isEmpty) {
          return const _EstadoVazioAba(mensagem: 'Nada a estimar ainda…');
        }
        return Column(
          children: territorio.ondeFalta
              .map((l) => _LinhaOndeFalta(linha: l))
              .toList(),
        );
      case _AbaTerritorio.altas:
        if (territorio.maioresAltas.isEmpty) {
          return const _EstadoVazioAba(
            mensagem:
                'Comparação disponível quando um município passar de 50% '
                'apurado.',
          );
        }
        return Column(
          children: territorio.maioresAltas
              .map((l) => _LinhaVariacao(linha: l, alta: true))
              .toList(),
        );
      case _AbaTerritorio.quedas:
        if (territorio.maioresQuedas.isEmpty) {
          return const _EstadoVazioAba(mensagem: 'Nenhuma queda…');
        }
        return Column(
          children: territorio.maioresQuedas
              .map((l) => _LinhaVariacao(linha: l, alta: false))
              .toList(),
        );
    }
  }
}

class _EstadoVazioAba extends StatelessWidget {
  const _EstadoVazioAba({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        mensagem,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _LinhaOndeFalta extends StatelessWidget {
  const _LinhaOndeFalta({required this.linha});

  final ApuracaoTerritorioLinha linha;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = linha;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (l.capital)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        l.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${formatarVotosApuracao(l.votos2022)} em 2022 · '
                  '${formatarVotosApuracao(l.votos)} até agora · '
                  '${l.municipes} munícipe${l.municipes == 1 ? '' : 's'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                BarraProgresso(pct: l.pctSecoes ?? 0, height: 4),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (l.potencialRestante != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '+${formatarVotosApuracao(l.potencialRestante)} esperados',
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinhaVariacao extends StatelessWidget {
  const _LinhaVariacao({required this.linha, required this.alta});

  final ApuracaoTerritorioLinha linha;
  final bool alta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = linha;
    final cor = alta ? _corVerde : _corVermelho;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            alta ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 16,
            color: cor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${formatarVotosApuracao(l.votos)} votos agora',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${formatarSinalVotosApuracao(l.variacaoVotos)} '
                '(${formatarSinalPctApuracao(l.variacaoPct)})',
                maxLines: 1,
                textAlign: TextAlign.right,
                style: tt.labelMedium?.copyWith(
                  color: cor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
