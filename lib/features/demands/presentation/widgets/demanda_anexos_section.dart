import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/friendly_error.dart';
import '../../data/models/demanda_model.dart';
import '../providers/demanda_providers.dart';

/// Lista de anexos; tocar baixa (autenticado) e visualiza/compartilha.
class DemandaAnexosSection extends ConsumerWidget {
  const DemandaAnexosSection({super.key, required this.demanda});
  final DemandaDetalhe demanda;

  String _tamanho(int? b) {
    if (b == null) return '';
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _abrir(
    BuildContext context,
    WidgetRef ref,
    DemandaAnexo a,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Baixando arquivo...'),
        duration: Duration(seconds: 20),
      ),
    );
    try {
      final bytes = await ref
          .read(demandaDataSourceProvider)
          .baixarAnexo(demanda.id, a.id);
      messenger.hideCurrentSnackBar();
      if (!context.mounted) return;
      final dados = Uint8List.fromList(bytes);
      if (a.ehImagem) {
        await showDialog<void>(
          context: context,
          builder: (_) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    child: Image.memory(dados, fit: BoxFit.contain),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip: 'Fechar',
                      color: Colors.white,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final nome = a.nomeOriginal.replaceAll(RegExp(r'[^\w.\- ]'), '_');
        final f = await File('${dir.path}/$nome').writeAsBytes(dados);
        await Share.shareXFiles([XFile(f.path)], subject: a.nomeOriginal);
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(mensagemAmigavel(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (demanda.anexos.isEmpty) {
      return Text(
        'Nenhum anexo.',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      );
    }
    return Column(
      children: [
        for (final a in demanda.anexos)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              a.ehImagem
                  ? Icons.image_outlined
                  : Icons.insert_drive_file_outlined,
              color: cs.primary,
            ),
            title: Text(
              a.nomeOriginal,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                a.tipo,
                _tamanho(a.tamanho),
              ].where((s) => s.isNotEmpty).join(' · '),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _abrir(context, ref, a),
          ),
      ],
    );
  }
}
