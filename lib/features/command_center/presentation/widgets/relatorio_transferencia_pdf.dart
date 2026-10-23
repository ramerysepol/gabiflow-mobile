import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/network/friendly_error.dart';
import '../providers/transferencia_providers.dart';

/// Baixa o relatório de transferência de votos e abre a visualização
/// (imprimir/salvar) ou o compartilhamento. [tipo]: simplificado | completo.
Future<void> abrirRelatorioTransferenciaPdf(
  BuildContext context,
  WidgetRef ref, {
  required String sequencial,
  required int ano,
  required String uf,
  required List<String> apoiadores,
  required String tipo,
  String? municipio,
  bool compartilhar = false,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(const SnackBar(
    content: Text('Gerando relatório de transferência...'),
    duration: Duration(seconds: 60),
  ));
  final nome = 'transferencia-votos-${ano - 2}-$ano-$tipo.pdf';
  try {
    final bytes =
        await ref.read(transferenciaDatasourceProvider).baixarRelatorioPdf(
              sequencial: sequencial,
              ano: ano,
              uf: uf,
              anoApoio: ano - 2,
              apoiadores: apoiadores,
              tipo: tipo,
              municipio: municipio,
            );
    messenger?.hideCurrentSnackBar();
    final dados = Uint8List.fromList(bytes);
    if (compartilhar) {
      await Printing.sharePdf(bytes: dados, filename: nome);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => dados, name: nome);
    }
  } catch (e) {
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(
      content: Text('Não foi possível gerar o PDF: ${mensagemAmigavel(e)}'),
    ));
  }
}
