/// Sheet de seleção de template Meta aprovado, usado para reabrir uma
/// conversa fora da janela de 24h (paridade com o "Selecionar Template" do
/// ChatInput.tsx da central web).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/whatsapp_models.dart';
import '../providers/whatsapp_providers.dart';

/// Template escolhido com as variáveis já preenchidas pelo atendente,
/// prontas para o payload `templateVariables` (chaves "1", "2"…).
class TemplateEscolhido {
  const TemplateEscolhido({
    required this.templateName,
    required this.language,
    required this.templateVariables,
  });

  final String templateName;
  final String language;
  final Map<String, String> templateVariables;
}

class TemplatePickerSheet extends ConsumerStatefulWidget {
  const TemplatePickerSheet({super.key});

  static Future<TemplateEscolhido?> show(BuildContext context) =>
      showModalBottomSheet<TemplateEscolhido>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const TemplatePickerSheet(),
      );

  @override
  ConsumerState<TemplatePickerSheet> createState() =>
      _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends ConsumerState<TemplatePickerSheet> {
  MetaTemplate? _selecionado;
  final Map<String, TextEditingController> _valores = {};

  @override
  void dispose() {
    for (final c in _valores.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _selecionar(MetaTemplate t) {
    setState(() {
      _selecionado = t;
      for (final c in _valores.values) {
        c.dispose();
      }
      _valores.clear();
      for (final v in t.variaveis) {
        _valores[v] = TextEditingController();
      }
    });
  }

  bool get _pronto {
    final t = _selecionado;
    if (t == null) return false;
    return t.variaveis.every(
      (v) => (_valores[v]?.text.trim() ?? '').isNotEmpty,
    );
  }

  void _confirmar() {
    final t = _selecionado;
    if (t == null || !_pronto) return;
    Navigator.of(context).pop(
      TemplateEscolhido(
        templateName: t.templateName,
        language: t.language,
        templateVariables: {
          for (final v in t.variaveis) v: _valores[v]!.text.trim(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(whatsappTemplatesProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scroll) => templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Falha ao carregar templates.\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (templates) => _conteudo(context, scroll, templates.meta),
      ),
    );
  }

  Widget _conteudo(
    BuildContext context,
    ScrollController scroll,
    List<MetaTemplate> lista,
  ) {
    return ListView(
      controller: scroll,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
      ),
      children: [
        Text(
          'Selecionar template',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'A janela de 24h expirou. Envie um template aprovado pela Meta '
          'para reabrir a conversa.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (lista.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'Nenhum template Meta aprovado disponível. Crie e aprove '
              'templates no gabinete (desktop).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ...lista.map(
          (t) => _TemplateOpcao(
            template: t,
            selecionado: _selecionado?.templateName == t.templateName,
            onTap: !t.midiaSuportadaNoApp ? null : () => _selecionar(t),
          ),
        ),
        if (_selecionado != null && _selecionado!.variaveis.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('VARIÁVEIS', style: AppTextStyles.eyebrow(context)),
          const SizedBox(height: AppSpacing.sm),
          ..._selecionado!.variaveis.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TextField(
                controller: _valores[v],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: '{{$v}}'),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: _pronto ? _confirmar : null,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Enviar template'),
        ),
      ],
    );
  }
}

class _TemplateOpcao extends StatelessWidget {
  const _TemplateOpcao({
    required this.template,
    required this.selecionado,
    required this.onTap,
  });

  final MetaTemplate template;
  final bool selecionado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: selecionado
              ? BorderSide(color: cs.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        template.nome,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (selecionado)
                      Icon(
                        Icons.check_circle_rounded,
                        color: cs.primary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  template.texto,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!template.midiaSuportadaNoApp)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Requer mídia no cabeçalho — envie pelo desktop',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.warningDark
                            : AppColors.warningLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
