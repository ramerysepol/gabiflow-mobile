import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/eleitoral_providers.dart';

/// Legenda colapsável das mesorregiões da UF ativa + escala de intensidade.
/// Posicionada bottom-right sobre o mapa.
class MapaLegenda extends ConsumerStatefulWidget {
  const MapaLegenda({super.key, this.modoCalor = false});

  /// No modo calor a lista de mesorregiões some — só a escala de intensidade.
  final bool modoCalor;

  @override
  ConsumerState<MapaLegenda> createState() => _MapaLegendaState();
}

class _MapaLegendaState extends ConsumerState<MapaLegenda>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(ufConfigProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão toggle
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Legenda',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // Conteúdo expansível
          SizeTransition(
            sizeFactor: _anim,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 8, thickness: 0.5),
                  // Mesorregiões (ocultas no modo calor)
                  if (!widget.modoCalor)
                  ...cfg.nomes.entries.map((e) {
                    final color = cfg.cores[e.key] ??
                        const Color(0xFF388E3C);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (!widget.modoCalor)
                    const Divider(height: 10, thickness: 0.5),
                  // Escala de intensidade
                  Text(
                    'Intensidade de votos',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.4,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Baixo',
                        style: TextStyle(fontSize: 8, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 80,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [
                              (isDark
                                      ? const Color(0xFF1565C0)
                                      : const Color(0xFF1976D2))
                                  .withValues(alpha: 0.1),
                              isDark
                                  ? const Color(0xFF1565C0)
                                  : const Color(0xFF1976D2),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Alto',
                        style: TextStyle(fontSize: 8, color: cs.onSurfaceVariant),
                      ),
                    ],
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
