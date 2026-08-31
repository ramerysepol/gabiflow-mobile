import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/central_providers.dart';

/// Inicia uma nova conversa por telefone (WhatsApp). Retorna o id da conversa
/// criada/reaberta, ou null se cancelou.
class NovaConversaSheet extends ConsumerStatefulWidget {
  const NovaConversaSheet({super.key});

  static Future<int?> mostrar(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const NovaConversaSheet(),
    );
  }

  @override
  ConsumerState<NovaConversaSheet> createState() => _NovaConversaSheetState();
}

class _NovaConversaSheetState extends ConsumerState<NovaConversaSheet> {
  final _telCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _telCtrl.dispose();
    _nomeCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    final tel = _telCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (tel.length < 10) {
      setState(() => _erro = 'Informe um telefone válido com DDD.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final id = await ref.read(centralDataSourceProvider).criarConversa(
            telefone: tel,
            nomeContato: _nomeCtrl.text.trim().isEmpty ? null : _nomeCtrl.text.trim(),
            mensagemInicial: _msgCtrl.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _erro = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const Text('Nova conversa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _telCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s()+-]'))
            ],
            decoration: const InputDecoration(
              labelText: 'Telefone (com DDD) *',
              hintText: 'ex.: (11) 91234-5678',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nomeCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome (opcional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _msgCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Mensagem inicial (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 8),
            Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _enviando ? null : _criar,
              icon: _enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: const Text('Iniciar conversa'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
