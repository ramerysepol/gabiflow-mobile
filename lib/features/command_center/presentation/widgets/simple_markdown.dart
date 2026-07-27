import 'package:flutter/material.dart';

/// Renderizador leve de markdown para as respostas da IA.
/// Suporta: ## títulos, **negrito**, *itálico*, `código`, listas (- e 1.)
/// e parágrafos. Sem dependências externas.
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown(this.data, {super.key});

  final String data;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final lines = data.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trimRight();

      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 8));
        continue;
      }

      // Títulos
      final headerMatch = RegExp(r'^(#{1,4})\s+(.*)$').firstMatch(trimmed);
      if (headerMatch != null) {
        final level = headerMatch.group(1)!.length;
        final text = headerMatch.group(2)!;
        children.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text.rich(
            _inline(text, tt.bodyMedium!, cs),
            style: (level <= 2 ? tt.titleSmall : tt.labelLarge)
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ));
        continue;
      }

      // Bullets
      final bulletMatch = RegExp(r'^\s*[-*•]\s+(.*)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        children.add(_listItem(context, '•', bulletMatch.group(1)!, tt, cs));
        continue;
      }

      // Lista numerada
      final numMatch = RegExp(r'^\s*(\d+)[.)]\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        children.add(_listItem(
            context, '${numMatch.group(1)}.', numMatch.group(2)!, tt, cs));
        continue;
      }

      // Parágrafo
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text.rich(
          _inline(trimmed, tt.bodyMedium!, cs),
          style: tt.bodyMedium?.copyWith(height: 1.45),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _listItem(BuildContext context, String marker, String text,
      TextTheme tt, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(marker,
                style: tt.bodyMedium?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text.rich(
              _inline(text, tt.bodyMedium!, cs),
              style: tt.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Parser inline: **negrito**, *itálico*, `código`.
  TextSpan _inline(String text, TextStyle base, ColorScheme cs) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)');
    var last = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      final token = match.group(0)!;
      if (token.startsWith('**')) {
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
      } else if (token.startsWith('`')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: cs.surfaceContainerHighest,
            fontSize: (base.fontSize ?? 14) - 1,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }
      last = match.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return TextSpan(children: spans);
  }
}
