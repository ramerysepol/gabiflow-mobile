import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/comparativo_bairro_model.dart';

/// Gera o relatório de seções (A×B) em .xlsx e abre o share sheet.
class SecoesXlsxService {
  const SecoesXlsxService._();

  static Future<void> compartilhar({
    required SecoesComparativoModel m,
    required String municipio,
    required String bairro,
    required int ano,
    required String estado,
  }) async {
    final excel = Excel.createExcel();
    final negrito = CellStyle(bold: true);

    final resumo = excel['Resumo'];
    final linhasResumo = <List<Object>>[
      ['Município', municipio],
      ['Bairro', bairro],
      ['Eleição', '$ano · $estado'],
      ['Candidato A', m.a.nomeUrna],
      ['Candidato B', m.b.nomeUrna],
      ['Votos A', m.totalVotosA],
      ['Votos B', m.totalVotosB],
      ['Seções', m.totalSecoes],
      ['Seções com ambos', m.secoesComAmbos],
      ['Seções só A', m.secoesSoA],
      ['Seções só B', m.secoesSoB],
      ['Seções sem nenhum', m.secoesSemNenhum],
    ];
    for (var r = 0; r < linhasResumo.length; r++) {
      final c0 = resumo.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r));
      c0.value = TextCellValue(linhasResumo[r][0] as String);
      c0.cellStyle = negrito;
      final v = linhasResumo[r][1];
      resumo.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value =
          v is int ? IntCellValue(v) : TextCellValue(v as String);
    }
    resumo.setColumnWidth(0, 22);
    resumo.setColumnWidth(1, 40);

    final aba = excel['Seções'];
    final cab = [
      'Zona',
      'Seção',
      'Local de votação',
      'Endereço',
      m.a.nomeUrna,
      m.b.nomeUrna,
      'Diferença',
    ];
    for (var c = 0; c < cab.length; c++) {
      final cell = aba.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(cab[c]);
      cell.cellStyle = negrito;
    }
    for (var i = 0; i < m.secoes.length; i++) {
      final s = m.secoes[i];
      final vals = <CellValue>[
        _num(s.zona),
        _num(s.secao),
        TextCellValue(s.local),
        TextCellValue(s.endereco),
        IntCellValue(s.votosA),
        IntCellValue(s.votosB),
        IntCellValue(s.diferenca),
      ];
      for (var c = 0; c < vals.length; c++) {
        aba.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1)).value =
            vals[c];
      }
    }
    aba.setColumnWidth(2, 40);
    aba.setColumnWidth(3, 40);

    excel.delete('Sheet1');
    excel.setDefaultSheet('Resumo');

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Falha ao gerar o arquivo Excel');
    final dir = await getTemporaryDirectory();
    final seguro = bairro.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final file = File('${dir.path}/secoes_${seguro}_$ano.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [
        XFile(file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      ],
      subject: 'Seções — $bairro ($municipio)',
    );
  }

  static CellValue _num(String s) {
    final n = int.tryParse(s);
    return n != null ? IntCellValue(n) : TextCellValue(s);
  }
}
