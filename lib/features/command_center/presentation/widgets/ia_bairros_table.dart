import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'relatorio_bairros_pdf.dart';

final _numFmt = NumberFormat.decimalPattern('pt_BR');

String _fmt(num? v) => _numFmt.format(v ?? 0);

num _asNum(dynamic v) =>
    v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

String _pct(dynamic v) =>
    '${_asNum(v).toStringAsFixed(1).replaceAll('.', ',')}%';

/// Visualização `bairros_table` das tools por bairro do Command Center
/// (votos_por_bairro, bairros_fracos, comparar_bairros_entre_eleicoes,
/// base_gabinete_por_bairro). Mostra os 10 primeiros e oferece o PDF
/// completo (imprimir ou compartilhar).
class IaBairrosTable extends ConsumerWidget {
  const IaBairrosTable({super.key, required this.data});

  final dynamic data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data is! Map) return const SizedBox.shrink();
    final d = (data as Map).cast<String, dynamic>();
    final bairros = (d['bairros'] as List? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    final export = RelatorioBairrosParams.fromExport(d['export']);
    final tipo = export?.tipo ?? 'votos';
    final municipio = d['municipio'] is Map
        ? (d['municipio'] as Map).cast<String, dynamic>()
        : null;

    if (bairros.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final titulo = switch (tipo) {
      'fracos' => 'Bairros para crescer',
      'evolucao' =>
        'Bairros: ${d['ano_base'] ?? ''} × ${d['cargo_alvo'] ?? ''} ${d['ano_alvo'] ?? ''}',
      'gabinete' => 'Base do gabinete × bairros',
      _ => 'Votos por bairro',
    };
    final subtitulo = municipio == null
        ? null
        : '${municipio['nome'] ?? ''}/${municipio['uf'] ?? ''}';

    final labelStyle = tt.labelSmall?.copyWith(
      fontSize: 10,
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final cellStyle = tt.labelSmall?.copyWith(fontSize: 10.5);
    final destaque = cellStyle?.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.primary,
    );

    // Colunas por tipo: (cabeçalho, valor, alinhamento à direita)
    final colunas = <({String cab, String Function(Map<String, dynamic>) val, bool dir, bool forte})>[
      switch (tipo) {
        'fracos' => (cab: 'Gap', val: (b) => _fmt(_asNum(b['gap'])), dir: true, forte: true),
        'evolucao' => (
            cab: 'Votos ${d['ano_base'] ?? ''}',
            val: (b) => _fmt(_asNum(b['votos_candidato'])),
            dir: true,
            forte: true
          ),
        _ => (cab: 'Votos', val: (b) => _fmt(_asNum(b['votos'])), dir: true, forte: true),
      },
      switch (tipo) {
        'fracos' => (cab: 'Votos', val: (b) => _fmt(_asNum(b['votos'])), dir: true, forte: false),
        'evolucao' => (
            cab: 'Cargo ${d['ano_alvo'] ?? ''}',
            val: (b) => _fmt(_asNum(b['votos_cargo_alvo'])),
            dir: true,
            forte: false
          ),
        'gabinete' => (cab: 'Cadastr.', val: (b) => _fmt(_asNum(b['cadastrados'])), dir: true, forte: false),
        _ => (cab: 'Eleitores', val: (b) => _fmt(_asNum(b['eleitores'])), dir: true, forte: false),
      },
      switch (tipo) {
        'evolucao' => (
            cab: 'Líder',
            val: (b) {
              final l = b['lider_cargo_alvo'];
              if (l is! Map) return '—';
              return (l['nome_urna'] ?? '').toString();
            },
            dir: false,
            forte: false
          ),
        'gabinete' => (
            cab: 'Ação',
            val: (b) => switch (b['prioridade']?.toString()) {
                  'cadastrar' => 'Cadastrar',
                  'fidelizar' => 'Fidelizar',
                  'sem_voto' => 'Sem voto',
                  _ => 'OK',
                },
            dir: false,
            forte: false
          ),
        _ => (cab: 'Penetr.', val: (b) => _pct(b['penetracao_pct']), dir: true, forte: false),
      },
    ];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 15, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitulo != null)
                      Text(
                        subtitulo,
                        style: tt.labelSmall?.copyWith(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'dados reais',
                  style: tt.labelSmall?.copyWith(
                    fontSize: 9,
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(18),
              1: FlexColumnWidth(2.2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1.1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  Text('#', style: labelStyle),
                  Text('Bairro', style: labelStyle),
                  for (final c in colunas)
                    Text(
                      c.cab,
                      style: labelStyle,
                      textAlign: c.dir ? TextAlign.right : TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              for (final (i, b) in bairros.take(10).indexed)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${b['posicao'] ?? i + 1}',
                        style: cellStyle?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5, right: 4),
                      child: Text(
                        (b['bairro'] ?? '').toString(),
                        style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (final c in colunas)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          c.val(b),
                          style: c.forte ? destaque : cellStyle,
                          textAlign: c.dir ? TextAlign.right : TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (bairros.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Mostrando 10 de ${bairros.length} bairros. O PDF traz a lista completa.',
                style: tt.labelSmall?.copyWith(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          if (export != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () =>
                        abrirRelatorioBairrosPdf(context, ref, export),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('PDF completo'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Compartilhar PDF',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => abrirRelatorioBairrosPdf(
                    context,
                    ref,
                    export,
                    compartilhar: true,
                  ),
                  icon: const Icon(Icons.share_outlined, size: 18),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
