import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Controles flutuantes do mapa: zoom in/out, reset, microrregião e busca.
class MapaControls extends StatelessWidget {
  const MapaControls({
    super.key,
    required this.mapController,
    required this.center,
    required this.defaultZoom,
    required this.onMicrorregiaoTap,
    required this.onBuscaTap,
  });

  final MapController mapController;
  final LatLng center;
  final double defaultZoom;
  final VoidCallback onMicrorregiaoTap;
  final VoidCallback onBuscaTap;

  void _zoomIn() {
    HapticFeedback.lightImpact();
    final current = mapController.camera.zoom;
    mapController.move(mapController.camera.center, current + 0.8);
  }

  void _zoomOut() {
    HapticFeedback.lightImpact();
    final current = mapController.camera.zoom;
    mapController.move(mapController.camera.center, current - 0.8);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    mapController.move(center, defaultZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlButton(
          icon: Icons.add,
          tooltip: 'Ampliar',
          onTap: _zoomIn,
        ),
        const SizedBox(height: 6),
        _ControlButton(
          icon: Icons.remove,
          tooltip: 'Reduzir',
          onTap: _zoomOut,
        ),
        const SizedBox(height: 6),
        _ControlButton(
          icon: Icons.center_focus_strong,
          tooltip: 'Resetar mapa',
          onTap: _reset,
        ),
        const SizedBox(height: 12),
        _ControlButton(
          icon: Icons.layers_outlined,
          tooltip: 'Microrregião',
          onTap: () {
            HapticFeedback.lightImpact();
            onMicrorregiaoTap();
          },
        ),
        const SizedBox(height: 6),
        _ControlButton(
          icon: Icons.search,
          tooltip: 'Buscar município',
          onTap: () {
            HapticFeedback.lightImpact();
            onBuscaTap();
          },
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: tooltip,
      button: true,
      child: Material(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(22),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Tooltip(
            message: tooltip,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 18,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
