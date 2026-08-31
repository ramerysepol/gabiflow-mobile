/// Texto de bolha de mensagem com CPF, CNPJ e e-mail copiáveis por toque
/// (paridade com `handleCopyableClick` de MessageList.tsx da central web).
library;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

// Mesmas regexes da central web (MessageList.tsx).
final RegExp _regexCpf = RegExp(r'\b(\d{3}\.?\d{3}\.?\d{3}-?\d{2})\b');
final RegExp _regexCnpj = RegExp(r'\b(\d{2}\.?\d{3}\.?\d{3}\/?\d{4}-?\d{2})\b');
final RegExp _regexEmail = RegExp(
  r'\b([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})\b',
);

enum _TipoCopiavel { cpf, cnpj, email }

class _Trecho {
  const _Trecho(this.texto, this.tipo);
  final String texto;
  final _TipoCopiavel? tipo; // null = texto comum
}

/// Divide o texto em trechos comuns e copiáveis, na ordem em que aparecem.
/// CPF é testado antes de CNPJ pois um CPF de 11 dígitos pode colidir com
/// o início de uma sequência maior — a checagem por índice evita sobreposição.
List<_Trecho> _dividir(String texto) {
  final matches = <(int, int, _TipoCopiavel)>[];
  for (final m in _regexCpf.allMatches(texto)) {
    matches.add((m.start, m.end, _TipoCopiavel.cpf));
  }
  for (final m in _regexCnpj.allMatches(texto)) {
    matches.add((m.start, m.end, _TipoCopiavel.cnpj));
  }
  for (final m in _regexEmail.allMatches(texto)) {
    matches.add((m.start, m.end, _TipoCopiavel.email));
  }
  matches.sort((a, b) => a.$1.compareTo(b.$1));

  final trechos = <_Trecho>[];
  var cursor = 0;
  for (final (inicio, fim, tipo) in matches) {
    if (inicio < cursor) continue; // sobreposto por um match anterior
    if (inicio > cursor) {
      trechos.add(_Trecho(texto.substring(cursor, inicio), null));
    }
    trechos.add(_Trecho(texto.substring(inicio, fim), tipo));
    cursor = fim;
  }
  if (cursor < texto.length) {
    trechos.add(_Trecho(texto.substring(cursor), null));
  }
  return trechos;
}

String _rotulo(_TipoCopiavel tipo) => switch (tipo) {
  _TipoCopiavel.cpf => 'CPF',
  _TipoCopiavel.cnpj => 'CNPJ',
  _TipoCopiavel.email => 'E-mail',
};

/// CPF/CNPJ copiam só os dígitos; e-mail copia como está (igual à web).
String _valorParaCopiar(String texto, _TipoCopiavel tipo) =>
    tipo == _TipoCopiavel.email ? texto : texto.replaceAll(RegExp(r'\D'), '');

/// Bolha de texto com CPF/CNPJ/e-mail sublinhados (tracejado) e copiáveis
/// ao toque. Guarda os `TapGestureRecognizer` para descartar no dispose —
/// sem isso o RichText vaza recognizers a cada rebuild.
class TextoComCopiaveis extends StatefulWidget {
  const TextoComCopiaveis({
    super.key,
    required this.texto,
    required this.corTexto,
    this.style,
  });

  final String texto;
  final Color corTexto;
  final TextStyle? style;

  @override
  State<TextoComCopiaveis> createState() => _TextoComCopiaveisState();
}

class _TextoComCopiaveisState extends State<TextoComCopiaveis> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _copiar(String valor, _TipoCopiavel tipo) async {
    await Clipboard.setData(ClipboardData(text: valor));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_rotulo(tipo)} copiado!'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final base = (widget.style ?? const TextStyle(fontSize: 15, height: 1.25))
        .copyWith(color: widget.corTexto);
    final trechos = _dividir(widget.texto);

    final spans = <InlineSpan>[];
    for (final t in trechos) {
      if (t.tipo == null) {
        spans.add(TextSpan(text: t.texto, style: base));
        continue;
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _copiar(_valorParaCopiar(t.texto, t.tipo!), t.tipo!);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: t.texto,
          style: base.copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dashed,
            decorationColor: widget.corTexto.withValues(alpha: 0.6),
          ),
          recognizer: recognizer,
        ),
      );
    }

    return RichText(
      text: TextSpan(style: base, children: spans),
    );
  }
}
