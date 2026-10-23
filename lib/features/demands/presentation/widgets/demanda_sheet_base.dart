import 'package:flutter/material.dart';

/// Abre um bottom sheet padrão das ações da demanda.
Future<T?> abrirSheetDemanda<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: builder,
  );
}

/// Corpo comum: título, rolagem e espaço para o teclado.
class DemandaSheetCorpo extends StatelessWidget {
  const DemandaSheetCorpo({
    super.key,
    required this.titulo,
    required this.children,
    this.subtitulo,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titulo, style: tt.titleMedium),
            if (subtitulo != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitulo!,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Botão de confirmação com estado de carregamento.
class DemandaBotaoSheet extends StatelessWidget {
  const DemandaBotaoSheet({
    super.key,
    required this.rotulo,
    required this.onPressed,
    this.carregando = false,
    this.icone = Icons.check_rounded,
  });

  final String rotulo;
  final VoidCallback? onPressed;
  final bool carregando;
  final IconData icone;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: carregando ? null : onPressed,
    icon: carregando
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icone),
    label: Text(rotulo),
  );
}
