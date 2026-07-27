import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/eleitoral_providers.dart';

/// Barra horizontal com chips scrolláveis para Ano, Cargo e UF.
class FiltrosBar extends ConsumerWidget {
  const FiltrosBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtros = ref.watch(filtrosSelecionadosProvider);
    final filtrosAsync = ref.watch(filtrosProvider);

    return filtrosAsync.when(
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Ano
              _ChipDropdown<int>(
                label: '${filtros.ano}',
                icon: Icons.calendar_today_outlined,
                items: data.anos.map((a) => DropdownMenuItem(value: a, child: Text('$a'))).toList(),
                value: filtros.ano,
                onChanged: (v) {
                  if (v != null) ref.read(filtrosSelecionadosProvider.notifier).setAno(v);
                },
              ),
              const SizedBox(width: 8),
              // UF
              _ChipDropdown<String>(
                label: filtros.estado,
                icon: Icons.map_outlined,
                items: data.ufs.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                value: filtros.estado,
                onChanged: (v) {
                  if (v != null) ref.read(filtrosSelecionadosProvider.notifier).setEstado(v);
                },
              ),
              const SizedBox(width: 8),
              // Cargo
              _ChipDropdown<String>(
                label: filtros.cargo.isEmpty ? 'Todos os cargos' : filtros.cargo,
                icon: Icons.badge_outlined,
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todos')),
                  ...data.cargos.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                ],
                value: filtros.cargo,
                onChanged: (v) {
                  if (v != null) ref.read(filtrosSelecionadosProvider.notifier).setCargo(v);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChipDropdown<T> extends StatelessWidget {
  const _ChipDropdown({
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final T value;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(12),
          selectedItemBuilder: (ctx) => items.map((item) {
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: cs.onSecondaryContainer),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 18, color: cs.onSecondaryContainer),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
