import 'package:flutter/material.dart';

import '../../data/models/ia_chat_models.dart';
import 'ia_visualization_view.dart';
import 'simple_markdown.dart';

/// Bolha de mensagem do chat (usuário ou assistente).
class IaChatBubble extends StatelessWidget {
  const IaChatBubble({super.key, required this.message});

  final IaChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.role == 'user') return _UserBubble(text: message.text);
    return _AssistantBubble(message: message);
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 48, top: 10, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onPrimary),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});

  final IaChatMessage message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 24, top: 10, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Atividade das tools ────────────────────────────────────────
          if (message.tools.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tool in message.tools)
                    IaToolChip(activity: tool),
                ],
              ),
            ),

          // ── Pensando... ────────────────────────────────────────────────
          if (message.thinkingLabel != null)
            _ThinkingIndicator(label: message.thinkingLabel!),

          // ── Texto (markdown) ───────────────────────────────────────────
          if (message.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: SimpleMarkdown(message.text),
            ),

          // ── Visualizações inline ───────────────────────────────────────
          for (final viz in message.visualizations)
            IaVisualizationView(viz: viz),

          // ── Erro ───────────────────────────────────────────────────────
          if (message.error != null)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 15, color: cs.error),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      message.error!,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Chip mostrando uma tool em execução ou concluída.
class IaToolChip extends StatelessWidget {
  const IaToolChip({super.key, required this.activity});

  final IaToolActivity activity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: activity.done
            ? cs.primaryContainer.withValues(alpha: 0.5)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: activity.done
              ? cs.primary.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activity.done)
            Icon(Icons.check_circle_rounded, size: 12, color: cs.primary)
          else
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: cs.primary,
              ),
            ),
          const SizedBox(width: 5),
          Text(
            activity.rowsCount != null
                ? '${activity.label} · ${activity.rowsCount}'
                : activity.label,
            style: tt.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: activity.done ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator({required this.label});

  final String label;

  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Row(
                children: List.generate(3, (i) {
                  final t = (_controller.value * 3 - i).clamp(0.0, 1.0);
                  final opacity =
                      t < 0.5 ? t * 2 : (1 - t) * 2; // pulso
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: cs.primary
                            .withValues(alpha: 0.3 + 0.7 * opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}
