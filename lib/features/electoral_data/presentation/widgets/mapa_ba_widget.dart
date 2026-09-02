import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/municipio_voto_model.dart';
import '../../data/services/geo_service.dart';
import '../../data/services/mesorregiao_colors.dart';
import '../providers/eleitoral_providers.dart';
import 'municipio_bottom_sheet.dart';
import 'municipio_tooltip_overlay.dart';
import 'seletor_municipio_sheet.dart';
import 'zonas_drilldown_sheet.dart';
import 'mapa_controls.dart';
import 'mapa_legenda.dart';
import '../../../../core/network/friendly_error.dart';

class MapaBaWidget extends ConsumerStatefulWidget {
  const MapaBaWidget({
    super.key,
    required this.municipios,
    required this.maxVotos,
    this.sequencial,
    this.microrregiaoIds,
    this.fullScreen = false,
    this.onMicrorregiaoTap,
    this.onBuscaTap,
    this.modoInicialCalor = false,
  });

  /// Abre o mapa já no modo mapa de calor (aba Mapa do sub-app Eleitoral).
  final bool modoInicialCalor;

  final List<MunicipioVotoModel> municipios;
  final int maxVotos;
  final String? sequencial;

  /// Se non-null, apenas estes municípios ficam coloridos; os demais ficam cinza.
  final Set<String>? microrregiaoIds;
  final bool fullScreen;
  final VoidCallback? onMicrorregiaoTap;
  final VoidCallback? onBuscaTap;

  @override
  ConsumerState<MapaBaWidget> createState() => _MapaBaWidgetState();
}

class _MapaBaWidgetState extends ConsumerState<MapaBaWidget>
    with SingleTickerProviderStateMixin {
  // Centro aproximado da Bahia
  static const _center = LatLng(-13.0, -41.5);
  static const _defaultZoom = 5.5;
  // Zoom a partir do qual os labels dos top municípios aparecem
  static const _labelZoomThreshold = 6.5;

  late final MapController _mapController;
  final _tooltipOverlay = MunicipioTooltipOverlay();

  String? _municipioTocado;
  // Cache do último tap para detectar double-tap manual
  String? _lastTapId;
  DateTime? _lastTapTime;

  /// Modo de cores: false = mesorregiões (padrão), true = mapa de calor
  bool _modoHeatmap = false;
  bool _showLabels = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _modoHeatmap = widget.modoInicialCalor;
  }

  @override
  void dispose() {
    _tooltipOverlay.hide();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final geoAsync = ref.watch(geoFeaturesProvider);

    return geoAsync.when(
      loading: () => const _MapaSkeleton(),
      error: (e, _) => _MapaError(
        message: 'Erro ao carregar o mapa. ${mensagemAmigavel(e)}',
        onRetry: () => ref.invalidate(geoFeaturesProvider),
      ),
      data: (features) => _buildMap(features),
    );
  }

  Widget _buildMap(List<MunicipioFeature> features) {
    // Monta lookup id → votos
    final votosMap = <String, MunicipioVotoModel>{};
    for (final m in widget.municipios) {
      votosMap[m.idMunicipio] = m;
    }

    final polygons = <Polygon>[];
    for (final feat in features) {
      if (feat.rings.isEmpty) continue;
      final dado = votosMap[feat.id];
      final inMicro = widget.microrregiaoIds == null ||
          widget.microrregiaoIds!.contains(feat.id);

      Color cor;

      if (!inMicro) {
        cor = Colors.grey.shade400.withValues(alpha: 0.3);
      } else if (_modoHeatmap) {
        // Modo heatmap: cor única, opacidade log-escalada (paridade desktop)
        final heatBase = Theme.of(context).colorScheme.primary;
        if (dado != null) {
          final opacity =
              _heatmapOpacity(dado.votosMunicipio, widget.maxVotos);
          cor = heatBase.withValues(alpha: opacity);
        } else {
          cor = heatBase.withValues(alpha: 0.05);
        }
      } else if (dado != null) {
        final baseCor = MesorregiaoColors.getCor(feat.id);
        final opacity =
            GeoService.calcOpacity(dado.votosMunicipio, widget.maxVotos);
        cor = baseCor.withValues(alpha: opacity);
      } else {
        cor = MesorregiaoColors.getCor(feat.id).withValues(alpha: 0.12);
      }

      final isSelected = _municipioTocado == feat.id;
      final inMicroHighlight = widget.microrregiaoIds != null &&
          widget.microrregiaoIds!.contains(feat.id);

      Color borderColor;
      double borderWidth;

      if (isSelected) {
        // Borda vermelha para município selecionado
        borderColor = Colors.red.shade600;
        borderWidth = 2.5;
      } else if (inMicroHighlight) {
        // Borda azul para municípios dentro da microrregião selecionada
        borderColor = Colors.blue.shade600;
        borderWidth = 1.5;
      } else {
        borderColor = Colors.white54;
        borderWidth = 0.5;
      }

      for (final ring in feat.rings) {
        polygons.add(
          Polygon(
            points: ring,
            color: cor,
            borderColor: borderColor,
            borderStrokeWidth: borderWidth,
          ),
        );
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: _defaultZoom,
            minZoom: 4.5,
            maxZoom: 13.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom |
                  InteractiveFlag.drag,
            ),
            onPositionChanged: (camera, _) {
              final show = camera.zoom >= _labelZoomThreshold;
              if (show != _showLabels) {
                setState(() => _showLabels = show);
              }
            },
            onTap: (tapPos, point) =>
                _handleMapTap(point, features, tapPos),
            onLongPress: (tapPos, point) =>
                _handleLongPress(point, features, tapPos),
          ),
          children: [
            // Fundo neutro
            ColoredBox(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerLowest),
            PolygonLayer(polygons: polygons),
            // Labels dos top municípios (aparecem com zoom)
            if (_showLabels)
              MarkerLayer(markers: _buildTopLabels(features)),
          ],
        ),

        // Toggle de modo de cores (top-left)
        Positioned(
          top: 12,
          left: 12,
          child: _ModoToggle(
            heatmap: _modoHeatmap,
            onChanged: (v) => setState(() => _modoHeatmap = v),
          ),
        ),

        // Resumo (fullscreen): municípios com voto + total de votos
        if (widget.fullScreen)
          Positioned(
            top: 12,
            right: 12,
            child: _ResumoBar(municipios: widget.municipios),
          ),

        // Controles bottom-right
        Positioned(
          bottom: 16,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapaControls(
                mapController: _mapController,
                center: _center,
                defaultZoom: _defaultZoom,
                onMicrorregiaoTap:
                    widget.onMicrorregiaoTap ?? _noop,
                onBuscaTap: widget.onBuscaTap ?? _abrirSeletorMunicipio,
              ),
              const SizedBox(height: 8),
              MapaLegenda(modoCalor: _modoHeatmap),
            ],
          ),
        ),
      ],
    );
  }

  void _noop() {}

  /// Opacidade do modo heatmap (paridade com o desktop):
  /// 0.15 + log(votos+1)/log(max+1) * 0.85
  double _heatmapOpacity(int votos, int maxVotos) {
    if (votos <= 0) return 0.05;
    final ratio = GeoService.logRatio(votos, maxVotos);
    return (0.15 + ratio * 0.85).clamp(0.05, 1.0);
  }

  /// Labels dos 10 municípios com mais votos, posicionados no centroide.
  List<Marker> _buildTopLabels(List<MunicipioFeature> features) {
    final top = [...widget.municipios]
      ..sort((a, b) => b.votosMunicipio.compareTo(a.votosMunicipio));
    final featById = {for (final f in features) f.id: f};
    final markers = <Marker>[];

    for (final m in top.take(10)) {
      final feat = featById[m.idMunicipio];
      if (feat == null || feat.rings.isEmpty) continue;
      final centroid = GeoService.centroid(feat.rings.first);
      markers.add(
        Marker(
          point: centroid,
          width: 110,
          height: 26,
          child: IgnorePointer(
            child: Center(
              child: Text(
                m.nomeMunicipio,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.75),
                  shadows: const [
                    Shadow(color: Colors.white, blurRadius: 3),
                    Shadow(color: Colors.white, blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  void _handleMapTap(
      LatLng point, List<MunicipioFeature> features, TapPosition tapPos) {
    // Esconde tooltip se estava visível (long-press)
    if (_tooltipOverlay.isVisible) {
      _tooltipOverlay.hide();
      return;
    }

    for (final feat in features) {
      for (final ring in feat.rings) {
        if (_pointInPolygon(point, ring)) {
          final now = DateTime.now();
          final isDoubleTap = _lastTapId == feat.id &&
              _lastTapTime != null &&
              now.difference(_lastTapTime!).inMilliseconds < 500;

          if (isDoubleTap) {
            // Double-tap → drill down zonas
            _lastTapId = null;
            _lastTapTime = null;
            HapticFeedback.mediumImpact();
            _showZonasDrilldown(feat.id, feat.nome);
          } else {
            // Single tap → bottom sheet IBGE
            _lastTapId = feat.id;
            _lastTapTime = now;
            setState(() => _municipioTocado = feat.id);
            _showMunicipioSheet(feat.id, feat.nome);
          }
          return;
        }
      }
    }
  }

  void _handleLongPress(
      LatLng point, List<MunicipioFeature> features, TapPosition tapPos) {
    for (final feat in features) {
      for (final ring in feat.rings) {
        if (_pointInPolygon(point, ring)) {
          HapticFeedback.mediumImpact();
          final dado = widget.municipios.firstWhere(
            (m) => m.idMunicipio == feat.id,
            orElse: () => MunicipioVotoModel(
              idMunicipio: feat.id,
              nomeMunicipio: feat.nome,
              votosMunicipio: 0,
              percentualMunicipio: 0,
              mesorregiao: MesorregiaoColors.getNome(feat.id),
            ),
          );

          // Posição do toque na tela
          final renderBox =
              context.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          final localPos =
              renderBox.globalToLocal(tapPos.global);

          // Busca dados IBGE se disponíveis (pré-carregado no watch)
          final ibgeAsync =
              ref.read(ibgeMunicipioProvider(feat.id));
          final ibge = ibgeAsync.valueOrNull;

          _tooltipOverlay.show(
            context: context,
            position: localPos,
            municipio: dado,
            ibge: ibge,
          );
          return;
        }
      }
    }
  }

  void _showMunicipioSheet(String id, String nome) {
    final dado = widget.municipios.firstWhere(
      (m) => m.idMunicipio == id,
      orElse: () => MunicipioVotoModel(
        idMunicipio: id,
        nomeMunicipio: nome,
        votosMunicipio: 0,
        percentualMunicipio: 0,
        mesorregiao: MesorregiaoColors.getNome(id),
      ),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MunicipioBottomSheet(
        municipio: dado,
        mesorregiao: MesorregiaoColors.getNome(id),
        sequencial: widget.sequencial,
      ),
    ).then((_) {
      if (mounted) setState(() => _municipioTocado = null);
    });
  }

  void _showZonasDrilldown(String id, String nome) {
    if (widget.sequencial == null) return;

    final dado = widget.municipios.firstWhere(
      (m) => m.idMunicipio == id,
      orElse: () => MunicipioVotoModel(
        idMunicipio: id,
        nomeMunicipio: nome,
        votosMunicipio: 0,
        percentualMunicipio: 0,
        mesorregiao: MesorregiaoColors.getNome(id),
      ),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ZonasDrilldownSheet(
        sequencial: widget.sequencial!,
        municipio: dado,
      ),
    ).then((_) {
      if (mounted) setState(() => _municipioTocado = null);
    });
  }

  void _abrirSeletorMunicipio() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SeletorMunicipioSheet(
        onSelected: (id, nome) {
          setState(() => _municipioTocado = id);
          _centralizarNoMunicipio(id);
          _showMunicipioSheet(id, nome);
        },
      ),
    );
  }

  /// Move o mapa pro centroide do município e aumenta o zoom.
  /// Silencioso se o feature ainda não tiver sido carregado.
  void _centralizarNoMunicipio(String id) {
    final featuresAsync = ref.read(geoFeaturesProvider);
    final features = featuresAsync.asData?.value;
    if (features == null) return;
    final feat = features.firstWhere(
      (f) => f.id == id,
      orElse: () => features.first,
    );
    if (feat.id != id || feat.rings.isEmpty) return;
    final centroid = GeoService.centroid(feat.rings.first);
    _mapController.move(centroid, 8.5);
  }

  /// Algoritmo ray-casting para ponto em polígono.
  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    int crossings = 0;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final pi = polygon[i];
      final pj = polygon[j];
      if (((pi.latitude > point.latitude) !=
              (pj.latitude > point.latitude)) &&
          (point.longitude <
              (pj.longitude - pi.longitude) *
                      (point.latitude - pi.latitude) /
                      (pj.latitude - pi.latitude) +
                  pi.longitude)) {
        crossings++;
      }
    }
    return crossings.isOdd;
  }
}

// ─── Toggle de modo de cores ─────────────────────────────────────────────────

class _ModoToggle extends StatelessWidget {
  const _ModoToggle({required this.heatmap, required this.onChanged});

  final bool heatmap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Widget chip(String label, IconData icon, bool selected, bool value) {
      return GestureDetector(
        onTap: () {
          if (!selected) {
            HapticFeedback.selectionClick();
            onChanged(value);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip('Regiões', Icons.category_outlined, !heatmap, false),
          chip('Calor', Icons.local_fire_department_outlined, heatmap, true),
        ],
      ),
    );
  }
}

// ─── Barra de resumo (fullscreen) ────────────────────────────────────────────

class _ResumoBar extends StatelessWidget {
  const _ResumoBar({required this.municipios});

  final List<MunicipioVotoModel> municipios;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final totalVotos =
        municipios.fold<int>(0, (s, m) => s + m.votosMunicipio);

    Widget chip(IconData icon, String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: cs.primary),
            const SizedBox(width: 4),
            Text(
              text,
              style: tt.labelSmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.topRight,
      child: Wrap(
        spacing: 6,
        children: [
          chip(Icons.location_city_rounded, '${municipios.length} municípios'),
          chip(Icons.how_to_vote_outlined,
              '${_formatCompact(totalVotos)} votos'),
        ],
      ),
    );
  }

  String _formatCompact(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toString();
  }
}

// ─── Skeleton ────────────────────────────────────────────────────────────────

class _MapaSkeleton extends StatefulWidget {
  const _MapaSkeleton();

  @override
  State<_MapaSkeleton> createState() => _MapaSkeletonState();
}

class _MapaSkeletonState extends State<_MapaSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        color: cs.surfaceContainerLowest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 64,
                color: cs.onSurfaceVariant.withValues(alpha: _anim.value),
              ),
              const SizedBox(height: 12),
              Text(
                'Carregando mapa...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant
                          .withValues(alpha: _anim.value),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error state ─────────────────────────────────────────────────────────────

class _MapaError extends StatelessWidget {
  const _MapaError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLowest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.wifi_off_outlined,
                  size: 36,
                  color: cs.error,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
