import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/network/friendly_error.dart';
import '../../../electoral_data/presentation/providers/eleitoral_providers.dart';
import '../../data/models/ia_chat_models.dart';
import '../providers/command_center_providers.dart';

/// Exporta [mensagens] (pergunta + resposta, ou a conversa toda) em PDF,
/// reproduzindo o que aparece no Command Center: texto, rankings e tabelas.
/// O PDF é montado no servidor; aqui só abrimos impressão ou compartilhamento.
Future<void> exportarConversaPdf(
  BuildContext context,
  WidgetRef ref,
  List<IaChatMessage> mensagens, {
  bool compartilhar = false,
}) async {
  final contexto = ref.read(iaContextoProvider);
  final filtros = ref.read(filtrosSelecionadosProvider);
  final validas = mensagens
      .where((m) => !m.isStreaming && m.error == null && m.text.isNotEmpty)
      .toList();
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (validas.isEmpty) {
    messenger?.showSnackBar(
        const SnackBar(content: Text('Nada para exportar ainda.')));
    return;
  }
  messenger?.showSnackBar(const SnackBar(
    content: Text('Gerando PDF da consulta...'),
    duration: Duration(seconds: 30),
  ));
  try {
    final bytes = await ref.read(iaDatasourceProvider).exportarConversaPdf(
      contexto: {
        'nome_candidato': contexto?.nomeCandidato,
        'partido': contexto?.siglaPartido,
        'cargo': contexto?.cargo,
        'ano': filtros.ano.toString(),
        'uf': filtros.estado,
        'votos_totais': contexto?.votosTotal,
      },
      mensagens: [for (final m in validas) m.toExportJson()],
    );
    messenger?.hideCurrentSnackBar();
    final dados = Uint8List.fromList(bytes);
    final nome = (contexto?.nomeCandidato ?? 'consulta')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final arquivo = 'command-center-$nome.pdf';
    if (compartilhar) {
      await Printing.sharePdf(bytes: dados, filename: arquivo);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => dados, name: arquivo);
    }
  } catch (e) {
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(
      content: Text('Não foi possível gerar o PDF: ${mensagemAmigavel(e)}'),
    ));
  }
}

/// Barra de ações exibida ao fim de uma resposta concluída.
class IaExportarRespostaBar extends ConsumerWidget {
  const IaExportarRespostaBar({
    super.key,
    required this.resposta,
    this.pergunta,
  });

  final IaChatMessage resposta;
  final IaChatMessage? pergunta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lote = [if (pergunta != null) pergunta!, resposta];
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
              foregroundColor: cs.primary,
              textStyle: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            onPressed: () => exportarConversaPdf(context, ref, lote),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
            label: const Text('Exportar PDF'),
          ),
          IconButton(
            tooltip: 'Compartilhar PDF',
            visualDensity: VisualDensity.compact,
            color: cs.primary,
            onPressed: () =>
                exportarConversaPdf(context, ref, lote, compartilhar: true),
            icon: const Icon(Icons.share_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}
