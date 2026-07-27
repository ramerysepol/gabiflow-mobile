import 'package:flutter/material.dart';

import '../../../../core/widgets/app_empty_state.dart';

/// Placeholder para o módulo WhatsApp (em desenvolvimento).
class WhatsAppPlaceholderPage extends StatelessWidget {
  const WhatsAppPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppEmptyState(
        title: 'Central em breve',
        subtitle:
            'O módulo de atendimento WhatsApp está sendo preparado.\n'
            'Em breve você poderá gerenciar todas as conversas aqui.',
        actionLabel: null,
      ),
    );
  }
}
