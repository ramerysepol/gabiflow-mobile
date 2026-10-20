import 'package:flutter/material.dart';

import '../data/models/apuracao_ranking_model.dart';

/// Cores do duelo — regra POR PARTIDO, igual à web (MapaBrasilUF.tsx).
abstract final class CoresDuelo {
  static const vermelho = Color(0xFFDC2626);
  static const azul = Color(0xFF1D4ED8);
  static const neutro = Color(0xFF6B7280);

  /// Estado ainda sem boletins (cinza; escolhe tom por tema).
  static Color semDados({required bool escuro}) =>
      escuro ? const Color(0xFF2A3344) : const Color(0xFFD5DAE3);

  static const _porPartido = <String, Color>{'PT': vermelho, 'PL': azul};

  /// Cor fixa do candidato [sqcand]: pelo partido (PT vermelho, PL azul); sem
  /// partido mapeado, cai no número de urna (menor = vermelho, maior = azul).
  /// Nunca muda durante a noite, mesmo trocando a liderança.
  static Color doCandidato(String sqcand, List<ApuracaoCandVoto> itens) {
    ApuracaoCandVoto? cand;
    for (final c in itens) {
      if (c.sqcand == sqcand) cand = c;
    }
    final porPartido = _porPartido[(cand?.partido ?? '').toUpperCase()];
    if (porPartido != null) return porPartido;
    final ordenados = [...itens]
      ..sort(
        (a, b) => (int.tryParse(a.numero ?? '') ?? 0).compareTo(
          int.tryParse(b.numero ?? '') ?? 0,
        ),
      );
    final idx = ordenados.indexWhere((c) => c.sqcand == sqcand);
    if (idx == 0) return vermelho;
    if (idx == 1) return azul;
    return neutro;
  }

  /// Intensidade pela vantagem do líder: empate técnico claro, vitória larga
  /// saturada (0.45 a 1.0).
  static double opacidadeVantagem(num pctLider) =>
      0.45 + 0.55 * ((pctLider - 50) / 25).clamp(0.0, 1.0);
}

/// Iniciais para o "avatar" do candidato (sem foto na API).
String iniciaisCandidato(String nome) {
  final partes = nome
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first[0].toUpperCase();
  return (partes.first[0] + partes.last[0]).toUpperCase();
}
