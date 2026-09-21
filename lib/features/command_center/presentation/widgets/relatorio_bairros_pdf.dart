import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/network/friendly_error.dart';
import '../providers/command_center_providers.dart';

/// Parâmetros do relatório por bairro. Espelham o objeto `export` que as
/// tools de bairro do Command Center devolvem (backend: bairro-tools.ts).
class RelatorioBairrosParams {
  const RelatorioBairrosParams({
    required this.tipo,
    required this.sequencial,
    required this.ano,
    required this.uf,
    this.municipio,
    this.cargoAlvo,
    this.anoAlvo,
    this.bairro,
    this.cargo,
  });

  /// votos | fracos | evolucao | gabinete | ranking
  final String tipo;
  final String sequencial;
  final String ano;
  final String uf;

  /// Código IBGE ou nome do município (opcional para vereador/prefeito).
  final String? municipio;
  final String? cargoAlvo;
  final String? anoAlvo;

  /// Só para tipo 'ranking': bairro (TSE) e cargo do ranking.
  final String? bairro;
  final String? cargo;

  static RelatorioBairrosParams? fromExport(dynamic raw) {
    if (raw is! Map) return null;
    final m = raw.cast<String, dynamic>();
    final tipo = m['tipo']?.toString() ?? '';
    final sequencial = m['sequencial']?.toString() ?? '';
    if (tipo.isEmpty || sequencial.isEmpty) return null;
    return RelatorioBairrosParams(
      tipo: tipo,
      sequencial: sequencial,
      ano: m['ano']?.toString() ?? '',
      uf: m['uf']?.toString() ?? 'BA',
      municipio: m['municipio']?.toString(),
      cargoAlvo: m['cargo_alvo']?.toString(),
      anoAlvo: m['ano_alvo']?.toString(),
      bairro: m['bairro']?.toString(),
      cargo: m['cargo']?.toString(),
    );
  }

  String get nomeArquivo {
    final partes = [
      'bairros',
      tipo,
      if (bairro != null && bairro!.isNotEmpty)
        bairro!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      if (municipio != null && municipio!.isNotEmpty)
        municipio!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      ano,
    ];
    return '${partes.join('-')}.pdf';
  }
}

/// Baixa o relatório por bairro do servidor e abre a caixa de impressão
/// (que no Android e no iOS também permite salvar como PDF) ou a folha de
/// compartilhamento, quando [compartilhar] é true.
Future<void> abrirRelatorioBairrosPdf(
  BuildContext context,
  WidgetRef ref,
  RelatorioBairrosParams params, {
  bool compartilhar = false,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(const SnackBar(
    content: Text('Gerando PDF por bairros...'),
    duration: Duration(seconds: 30),
  ));
  try {
    final bytes = await ref.read(iaDatasourceProvider).baixarRelatorioBairrosPdf(
          tipo: params.tipo,
          sequencial: params.sequencial,
          ano: params.ano,
          uf: params.uf,
          municipio: params.municipio,
          cargoAlvo: params.cargoAlvo,
          anoAlvo: params.anoAlvo,
          bairro: params.bairro,
          cargo: params.cargo,
        );
    messenger?.hideCurrentSnackBar();
    final dados = Uint8List.fromList(bytes);
    if (compartilhar) {
      await Printing.sharePdf(bytes: dados, filename: params.nomeArquivo);
    } else {
      await Printing.layoutPdf(
        onLayout: (_) async => dados,
        name: params.nomeArquivo,
      );
    }
  } catch (e) {
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(
      content: Text('Não foi possível gerar o PDF: ${mensagemAmigavel(e)}'),
    ));
  }
}
