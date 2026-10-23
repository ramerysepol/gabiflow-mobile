import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/demanda_model.dart';
import '../../data/models/demanda_vocab.dart';

/// Estado dos campos da seção Saúde (teal) do formulário.
class SaudeFormController {
  bool outraPessoa = false;
  final paciente = TextEditingController();
  final parentesco = TextEditingController();
  final especialidade = TextEditingController();
  final unidade = TextEditingController();
  final sus = TextEditingController();
  String tipoPedido = 'consulta';
  String urgencia = 'eletiva';

  void preencher(DemandaSaude s) {
    tipoPedido = DemandaVocab.tipoPedidoLista.contains(s.tipoPedido)
        ? s.tipoPedido
        : 'outro';
    urgencia = DemandaVocab.urgenciaLista.contains(s.urgenciaClinica)
        ? s.urgenciaClinica
        : 'eletiva';
    especialidade.text = s.especialidade ?? '';
    if ((s.pacienteNome ?? '').isNotEmpty) {
      outraPessoa = true;
      paciente.text = s.pacienteNome!;
    }
  }

  Map<String, dynamic> toJson() => {
    'tipoPedido': tipoPedido,
    'urgenciaClinica': urgencia,
    if (especialidade.text.trim().isNotEmpty)
      'especialidade': especialidade.text.trim(),
    if (unidade.text.trim().isNotEmpty) 'unidadeSaude': unidade.text.trim(),
    if (sus.text.trim().isNotEmpty) 'cartaoSus': sus.text.trim(),
    if (outraPessoa && paciente.text.trim().isNotEmpty)
      'pacienteNome': paciente.text.trim(),
    if (outraPessoa && parentesco.text.trim().isNotEmpty)
      'pacienteParentesco': parentesco.text.trim(),
  };

  void dispose() {
    paciente.dispose();
    parentesco.dispose();
    especialidade.dispose();
    unidade.dispose();
    sus.dispose();
  }
}

/// Selo "IA" para campos preenchidos pelo assistente.
class IaBadge extends StatelessWidget {
  const IaBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        'IA',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: cs.onTertiaryContainer,
        ),
      ),
    );
  }
}

class DemandaSaudeForm extends StatefulWidget {
  const DemandaSaudeForm({
    super.key,
    required this.controller,
    required this.especialidades,
    required this.nomeMunicipe,
    this.iaCampos = const {},
    this.aoAlterar,
  });

  final SaudeFormController controller;
  final List<String> especialidades;
  final String? nomeMunicipe;
  final Set<String> iaCampos;
  final VoidCallback? aoAlterar;

  @override
  State<DemandaSaudeForm> createState() => _DemandaSaudeFormState();
}

class _DemandaSaudeFormState extends State<DemandaSaudeForm> {
  SaudeFormController get c => widget.controller;
  final _foco = FocusNode();

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  void _mudou(VoidCallback f) {
    setState(f);
    widget.aoAlterar?.call();
  }

  Widget _rotulo(String t, {String? campo}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(t),
      if (campo != null && widget.iaCampos.contains(campo)) const IaBadge(),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final teal = DemandaVocab.corSaude(context);
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: teal.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: teal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Dados de saúde',
                style: tt.titleSmall?.copyWith(
                  color: teal,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              c.outraPessoa
                  ? 'O paciente é outra pessoa'
                  : 'Paciente: ${widget.nomeMunicipe ?? 'o próprio munícipe'}',
            ),
            subtitle: const Text('Ative se o pedido for para outra pessoa'),
            value: c.outraPessoa,
            onChanged: (v) => _mudou(() => c.outraPessoa = v),
          ),
          if (c.outraPessoa) ...[
            TextField(
              controller: c.paciente,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do paciente',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: c.parentesco,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Parentesco (ex.: mãe, filho)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
          ],
          DropdownButtonFormField<String>(
            key: ValueKey(c.tipoPedido),
            initialValue: c.tipoPedido,
            decoration: InputDecoration(
              label: _rotulo('Tipo de pedido', campo: 'tipoPedido'),
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final t in DemandaVocab.tipoPedidoLista)
                DropdownMenuItem(
                  value: t,
                  child: Text(DemandaVocab.tipoPedido(t)),
                ),
            ],
            onChanged: (v) => _mudou(() => c.tipoPedido = v ?? c.tipoPedido),
          ),
          const SizedBox(height: 10),
          RawAutocomplete<String>(
            textEditingController: c.especialidade,
            focusNode: _foco,
            optionsBuilder: (v) {
              final q = v.text.trim().toLowerCase();
              if (q.isEmpty) return widget.especialidades.take(8);
              return widget.especialidades
                  .where((e) => e.toLowerCase().contains(q))
                  .take(8);
            },
            fieldViewBuilder: (ctx, ctrl, foco, _) => TextField(
              controller: ctrl,
              focusNode: foco,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                label: _rotulo('Especialidade', campo: 'especialidade'),
                border: const OutlineInputBorder(),
              ),
            ),
            optionsViewBuilder: (ctx, onSel, opcoes) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 220,
                    maxWidth: 340,
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      for (final o in opcoes)
                        ListTile(
                          dense: true,
                          title: Text(o),
                          onTap: () => onSel(o),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: c.unidade,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Unidade de saúde',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Urgência clínica', style: tt.labelLarge),
              if (widget.iaCampos.contains('urgenciaClinica')) const IaBadge(),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final u in DemandaVocab.urgenciaLista)
                  ButtonSegment(
                    value: u,
                    label: Text(DemandaVocab.urgencia(u)),
                  ),
              ],
              selected: {c.urgencia},
              onSelectionChanged: (s) => _mudou(() => c.urgencia = s.first),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: c.sus,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cartão SUS',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
