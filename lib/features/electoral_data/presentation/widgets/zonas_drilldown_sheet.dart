import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/hierarquia_nivel_model.dart';
import '../../data/models/municipio_voto_model.dart';
import '../providers/eleitoral_providers.dart';
import 'numero_formatado.dart';

/// Bottom sheet expansível que exibe as zonas eleitorais de um município.
/// Double-tap no mapa abre este sheet.
/// Pode agrupar por **zona** (cada zona expansível lista as seções) ou por
/// **bairro** (seções de todas as zonas reagrupadas pelo bairro do local de
/// votação — dado que a API já devolve em cada seção).
class ZonasDrilldownSheet extends ConsumerStatefulWidget {
  const ZonasDrilldownSheet({
    super.key,
    required this.sequencial,
    required this.municipio,
  });

  final String sequencial;
  final MunicipioVotoModel municipio;

  @override
  ConsumerState<ZonasDrilldownSheet> createState() =>
      _ZonasDrilldownSheetState();
}

enum _Agrupamento { zona, bairro }

class _ZonasDrilldownSheetState extends ConsumerState<ZonasDrilldownSheet> {
  _Agrupamento _agrupamento = _Agrupamento.zona;

  String get sequencial => widget.sequencial;
  MunicipioVotoModel get municipio => widget.municipio;

  @override
  Widget build(BuildContext context) {
    final params = HierarquiaParams(
      sequencial: sequencial,
      nivel: HierarquiaNivel.zona,
      paiId: municipio.idMunicipio,
    );
    final zonasAsync = ref.watch(hierarquiaProvider(params));
    final cs = Theme.of(context).colorScheme;
    final porBairro = _agrupamento == _Agrupamento.bairro;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_city_outlined,
                                  size: 14, color: cs.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                'MUNICÍPIO',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontSize: 9,
                                      letterSpacing: 0.8,
                                      color: cs.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                          Text(
                            municipio.nomeMunicipio,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            porBairro ? 'Votos por bairro' : 'Zonas eleitorais',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              // Totais municipio
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    _KpiChip(
                      label: 'Total de votos',
                      value: formatarNumero(municipio.votosMunicipio),
                      icon: Icons.how_to_vote_outlined,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    zonasAsync.maybeWhen(
                      data: (data) => _KpiChip(
                        label: 'Zonas',
                        value: '${data.items.length}',
                        icon: Icons.layers_outlined,
                        color: cs.secondary,
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              // Seletor de agrupamento
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_Agrupamento>(
                    segments: const [
                      ButtonSegment(
                        value: _Agrupamento.zona,
                        icon: Icon(Icons.layers_outlined, size: 16),
                        label: Text('Zonas'),
                      ),
                      ButtonSegment(
                        value: _Agrupamento.bairro,
                        icon: Icon(Icons.location_on_outlined, size: 16),
                        label: Text('Bairros'),
                      ),
                    ],
                    selected: {_agrupamento},
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(
                        Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    onSelectionChanged: (sel) =>
                        setState(() => _agrupamento = sel.first),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Lista
              Expanded(
                child: porBairro
                    ? _BairrosList(
                        scrollController: scrollCtrl,
                        sequencial: sequencial,
                        idMunicipio: municipio.idMunicipio,
                        totalVotosMunicipio: municipio.votosMunicipio,
                      )
                    : zonasAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: cs.error,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Erro ao carregar zonas',
                                style: TextStyle(color: cs.error),
                              ),
                            ],
                          ),
                        ),
                        data: (data) => data.items.isEmpty
                            ? Center(
                                child: Text(
                                  'Nenhuma zona encontrada',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              )
                            : _ZonasList(
                                scrollController: scrollCtrl,
                                zonas: data.items,
                                sequencial: sequencial,
                                idMunicipio: municipio.idMunicipio,
                                totalVotosMunicipio: municipio.votosMunicipio,
                              ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Agrupamento por bairro ──────────────────────────────────────────────────

class _BairroGrupo {
  _BairroGrupo(this.nome);

  final String nome;
  int votos = 0;
  final List<HierarquiaItemModel> secoes = [];
  final Set<String> zonas = {};
}

const _kSemBairro = 'Sem bairro informado';

/// Reagrupa as seções do município pelo bairro do local de votação.
List<_BairroGrupo> _agruparPorBairro(List<HierarquiaItemModel> secoes) {
  final mapa = <String, _BairroGrupo>{};
  for (final s in secoes) {
    final nome = (s.bairro ?? '').trim().isEmpty ? _kSemBairro : s.bairro!.trim();
    final g = mapa.putIfAbsent(nome, () => _BairroGrupo(nome));
    g.votos += s.votosTotal;
    g.secoes.add(s);
    final zona = s.zona ?? s.id.split('-').first;
    if (zona.isNotEmpty) g.zonas.add(zona);
  }
  final lista = mapa.values.toList()
    ..sort((a, b) {
      final c = b.votos.compareTo(a.votos);
      return c != 0 ? c : a.nome.compareTo(b.nome);
    });
  for (final g in lista) {
    g.secoes.sort((a, b) => b.votosTotal.compareTo(a.votosTotal));
  }
  return lista;
}

class _BairrosList extends ConsumerStatefulWidget {
  const _BairrosList({
    required this.scrollController,
    required this.sequencial,
    required this.idMunicipio,
    required this.totalVotosMunicipio,
  });

  final ScrollController scrollController;
  final String sequencial;
  final String idMunicipio;
  final int totalVotosMunicipio;

  @override
  ConsumerState<_BairrosList> createState() => _BairrosListState();
}

class _BairrosListState extends ConsumerState<_BairrosList> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final params = HierarquiaParams(
      sequencial: widget.sequencial,
      nivel: HierarquiaNivel.secao,
      paiId: widget.idMunicipio,
    );
    final secoesAsync = ref.watch(hierarquiaProvider(params));
    final cs = Theme.of(context).colorScheme;

    return secoesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 40),
            const SizedBox(height: 8),
            Text('Erro ao carregar bairros', style: TextStyle(color: cs.error)),
          ],
        ),
      ),
      data: (data) {
        final grupos = _agruparPorBairro(data.items);
        if (grupos.isEmpty) {
          return Center(
            child: Text(
              'Nenhuma seção com votos',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          );
        }
        final totalBairros =
            grupos.where((g) => g.nome != _kSemBairro).length;

        return ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.only(bottom: 32),
          itemCount: grupos.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Text(
                  '$totalBairros bairro${totalBairros == 1 ? '' : 's'} · '
                  '${data.items.length} seç${data.items.length == 1 ? 'ão' : 'ões'}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              );
            }
            final g = grupos[i - 1];
            final isExpanded = _expanded.contains(g.nome);
            final pct = widget.totalVotosMunicipio > 0
                ? g.votos / widget.totalVotosMunicipio
                : 0.0;
            final zonasTxt = g.zonas.length == 1
                ? 'Zona ${g.zonas.first}'
                : '${g.zonas.length} zonas';

            return Column(
              children: [
                InkWell(
                  onTap: () => setState(() {
                    if (isExpanded) {
                      _expanded.remove(g.nome);
                    } else {
                      _expanded.add(g.nome);
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.nome,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${g.secoes.length} seç${g.secoes.length == 1 ? 'ão' : 'ões'} · $zonasTxt',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 10.5,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatarNumero(g.votos),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cs.primary,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${formatarDecimal(pct * 100)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Container(
                    color: cs.surfaceContainerLowest,
                    child: Column(
                      children: [
                        for (final s in g.secoes)
                          _SecaoRow(secao: s, mostrarZona: true),
                      ],
                    ),
                  ),
                const Divider(height: 1),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Agrupamento por zona (comportamento original) ───────────────────────────

class _ZonasList extends ConsumerStatefulWidget {
  const _ZonasList({
    required this.scrollController,
    required this.zonas,
    required this.sequencial,
    required this.idMunicipio,
    required this.totalVotosMunicipio,
  });

  final ScrollController scrollController;
  final List<HierarquiaItemModel> zonas;
  final String sequencial;
  final String idMunicipio;
  final int totalVotosMunicipio;

  @override
  ConsumerState<_ZonasList> createState() => _ZonasListState();
}

class _ZonasListState extends ConsumerState<_ZonasList> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: widget.zonas.length,
      itemBuilder: (ctx, i) {
        final zona = widget.zonas[i];
        final isExpanded = _expanded.contains(zona.id);
        final pct = widget.totalVotosMunicipio > 0
            ? zona.votosTotal / widget.totalVotosMunicipio
            : 0.0;

        return Column(
          children: [
            InkWell(
              onTap: () => setState(() {
                if (isExpanded) {
                  _expanded.remove(zona.id);
                } else {
                  _expanded.add(zona.id);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            zona.nome,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          formatarNumero(zona.votosTotal),
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${formatarDecimal(zona.percentual)}%',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              _SecoesExpanded(
                sequencial: sequencial,
                idMunicipio: idMunicipio,
                zona: zona,
              ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  String get sequencial => widget.sequencial;
  String get idMunicipio => widget.idMunicipio;
}

class _SecoesExpanded extends ConsumerWidget {
  const _SecoesExpanded({
    required this.sequencial,
    required this.idMunicipio,
    required this.zona,
  });

  final String sequencial;
  final String idMunicipio;
  final HierarquiaItemModel zona;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = HierarquiaParams(
      sequencial: sequencial,
      nivel: HierarquiaNivel.secao,
      paiId: idMunicipio,
    );
    final secoesAsync = ref.watch(hierarquiaProvider(params));
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surfaceContainerLowest,
      child: secoesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Erro ao carregar seções',
            style: TextStyle(color: cs.error, fontSize: 12),
          ),
        ),
        data: (data) {
          // Filtra seções da zona atual
          final secoesZona = data.items
              .where((s) => s.id.startsWith('${zona.id}-'))
              .toList();

          if (secoesZona.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Nenhuma seção com votos',
                style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            );
          }

          return Column(
            children: [
              for (final secao in secoesZona)
                _SecaoRow(secao: secao, mostrarZona: false),
            ],
          );
        },
      ),
    );
  }
}

/// Linha de seção (usada nos dois agrupamentos).
class _SecaoRow extends StatelessWidget {
  const _SecaoRow({required this.secao, required this.mostrarZona});

  final HierarquiaItemModel secao;
  final bool mostrarZona;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Legenda: local + (endereço ou bairro)
    final local = secao.localVotacao?.trim();
    final endereco = secao.endereco?.trim();
    final bairro = secao.bairro?.trim();
    final endBairro = [
      if (endereco != null && endereco.isNotEmpty) endereco,
      if (!mostrarZona &&
          bairro != null &&
          bairro.isNotEmpty &&
          endereco != bairro)
        bairro,
    ].join(' · ');
    final hasLocal = (local != null && local.isNotEmpty) || endBairro.isNotEmpty;
    final zonaTxt = secao.zona ?? secao.id.split('-').first;
    final titulo = mostrarZona && zonaTxt.isNotEmpty
        ? '${secao.nome} · Zona $zonaTxt'
        : secao.nome;

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'S',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (hasLocal) ...[
                  const SizedBox(height: 2),
                  if (local != null && local.isNotEmpty)
                    Text(
                      local,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (endBairro.isNotEmpty)
                    Text(
                      endBairro,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                            fontSize: 10,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatarNumero(secao.votosTotal),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                'votos',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 9,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
