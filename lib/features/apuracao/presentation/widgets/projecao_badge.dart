import 'package:flutter/material.dart';

/// Badge colorido com a projeção do candidato: Eleito (verde), Suplente
/// (âmbar), 2º turno (azul) ou Não eleito (vermelho).
///
/// Quando a projeção não vem direto do TSE (ex.: calculada por quociente
/// eleitoral/sobras) e a apuração ainda não terminou, mostra um "*" com
/// semântica de "projeção parcial" — ela pode mudar até o fim da contagem.
class ProjecaoBadge extends StatelessWidget {
  const ProjecaoBadge({
    super.key,
    required this.projecao,
    this.projecaoVia,
    this.pctSecoes,
    this.compacto = false,
  });

  final String? projecao;
  final String? projecaoVia;
  final num? pctSecoes;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    if (projecao == null || projecao!.isEmpty) return const SizedBox.shrink();

    final (cor, rotulo) = switch (projecao) {
      'eleito' => (const Color(0xFF16A34A), 'Eleito'),
      'suplente' => (const Color(0xFFD97706), 'Suplente'),
      'segundo_turno' => (const Color(0xFF0284C7), '2º turno'),
      'nao_eleito' => (const Color(0xFFDC2626), 'Não eleito'),
      _ => (Colors.grey, 'Em apuração'),
    };

    final parcial =
        projecaoVia != null && projecaoVia != 'tse' && (pctSecoes ?? 100) < 100;

    final texto = parcial ? '$rotulo *' : rotulo;

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 6 : 8,
        vertical: compacto ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor.withValues(alpha: 0.28)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: cor,
          fontSize: compacto ? 10 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (!parcial) return badge;

    return Tooltip(
      message: 'Projeção parcial: pode mudar até o fim da apuração',
      child: Semantics(label: 'Projeção parcial', child: badge),
    );
  }
}
