import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/central_models.dart';
import '../providers/central_providers.dart';

/// Resultado da folha de transferencia: destino (atendente OU departamento)
/// + motivo + notas.
class ResultadoTransferencia {
  final int? paraUsuario;
  final String? paraDepartamento;
  final String? nomeDestino;
  final String motivo;
  final String? notas;

  const ResultadoTransferencia({
    this.paraUsuario,
    this.paraDepartamento,
    this.nomeDestino,
    required this.motivo,
    this.notas,
  });
}

/// Folha de transferencia com paridade com o web: escolhe atendente ou
/// departamento e exige um MOTIVO (registrado como mensagem de sistema + nota
/// interna pelo backend).
class TransferSheet extends ConsumerStatefulWidget {
  const TransferSheet({super.key});

  static Future<ResultadoTransferencia?> mostrar(BuildContext context) {
    return showModalBottomSheet<ResultadoTransferencia>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const TransferSheet(),
    );
  }

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final _motivoCtrl = TextEditingController();
  bool _paraDepartamento = false; // false = atendente
  int? _usuarioSel;
  String? _deptoSel;
  String? _nomeDestinoSel;
  bool _tentouEnviar = false;
  late final Future<List<AtendenteResumo>> _atendentesFut;

  @override
  void initState() {
    super.initState();
    _atendentesFut = ref.read(centralDataSourceProvider).listarAtendentes();
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    setState(() => _tentouEnviar = true);
    final motivo = _motivoCtrl.text.trim();
    final temDestino = _paraDepartamento ? _deptoSel != null : _usuarioSel != null;
    if (!temDestino || motivo.isEmpty) return;
    Navigator.of(context).pop(ResultadoTransferencia(
      paraUsuario: _paraDepartamento ? null : _usuarioSel,
      paraDepartamento: _paraDepartamento ? _deptoSel : null,
      nomeDestino: _nomeDestinoSel,
      motivo: motivo,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meuId = ref.watch(authProvider).user?.id;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('Transferir conversa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            // Alternador Atendente / Departamento
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: false,
                      icon: Icon(Icons.person_rounded),
                      label: Text('Atendente')),
                  ButtonSegment(
                      value: true,
                      icon: Icon(Icons.groups_rounded),
                      label: Text('Departamento')),
                ],
                selected: {_paraDepartamento},
                onSelectionChanged: (s) => setState(() {
                  _paraDepartamento = s.first;
                  _usuarioSel = null;
                  _deptoSel = null;
                  _nomeDestinoSel = null;
                }),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _paraDepartamento
                  ? _listaDepartamentos()
                  : _listaAtendentes(meuId),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _motivoCtrl,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      labelText: 'Motivo da transferência *',
                      hintText: 'Ex.: assunto financeiro, encaminhar ao setor…',
                      border: const OutlineInputBorder(),
                      errorText: _tentouEnviar && _motivoCtrl.text.trim().isEmpty
                          ? 'Informe o motivo'
                          : null,
                    ),
                    onChanged: (_) {
                      if (_tentouEnviar) setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _confirmar,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Transferir'),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaAtendentes(int? meuId) {
    return FutureBuilder<List<AtendenteResumo>>(
      future: _atendentesFut,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return _erro('Falha ao carregar atendentes.');
        }
        final opcoes =
            (snap.data ?? const []).where((a) => a.id != meuId).toList();
        if (opcoes.isEmpty) {
          return _erro('Nenhum outro atendente disponível.');
        }
        return ListView(
          shrinkWrap: true,
          children: opcoes
              .map((a) => RadioListTile<int>(
                    value: a.id,
                    groupValue: _usuarioSel,
                    onChanged: (v) => setState(() {
                      _usuarioSel = v;
                      _nomeDestinoSel = a.nome;
                    }),
                    title: Text(a.nome),
                    secondary: const CircleAvatar(
                        child: Icon(Icons.person_rounded, size: 20)),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _listaDepartamentos() {
    final deptos = ref.watch(departamentosProvider);
    return deptos.when(
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (_, __) => _erro('Falha ao carregar departamentos.'),
      data: (lista) {
        if (lista.isEmpty) return _erro('Nenhum departamento cadastrado.');
        return ListView(
          shrinkWrap: true,
          children: lista
              .map((d) => RadioListTile<String>(
                    value: d.id,
                    groupValue: _deptoSel,
                    onChanged: (v) => setState(() {
                      _deptoSel = v;
                      _nomeDestinoSel = d.nome;
                    }),
                    title: Text(d.nome),
                    secondary: Icon(Icons.groups_rounded,
                        color: d.ehIA ? Colors.deepPurple : null),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _erro(String msg) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
            child: Text(msg,
                style: TextStyle(color: Theme.of(context).colorScheme.outline))),
      );
}
