import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../electoral_data/presentation/providers/eleitoral_providers.dart';
import '../../data/models/transferencia_models.dart';
import '../providers/command_center_providers.dart';
import '../providers/transferencia_providers.dart';
import '../widgets/bairro_search_card.dart' show cargoMunicipal;
import '../widgets/ia_candidato_picker.dart';
import '../widgets/relatorio_transferencia_pdf.dart';

/// Transferência de votos 2024 → 2026 (espelho do painel da aba IA web).
class TransferenciaPage extends ConsumerStatefulWidget {
  const TransferenciaPage({super.key});

  @override
  ConsumerState<TransferenciaPage> createState() => _TransferenciaPageState();
}

class _TransferenciaPageState extends ConsumerState<TransferenciaPage> {
  final _municipioCtrl = TextEditingController();
  final _termoCtrl = TextEditingController();

  @override
  void dispose() {
    _municipioCtrl.dispose();
    _termoCtrl.dispose();
    super.dispose();
  }

  bool get _precisaMunicipio =>
      !cargoMunicipal(ref.read(iaContextoProvider)?.cargo);

  bool _municipioOk(TransferenciaState s) =>
      !_precisaMunicipio || s.municipio.trim().isNotEmpty;

  static const _msgMunicipio =
      'Para deputado, senador ou governador, informe o município.';

  Future<void> _gerar(String tipo, TransferenciaState s) async {
    final n = ref.read(transferenciaProvider.notifier);
    if (!_municipioOk(s)) {
      n.setErro(_msgMunicipio);
      return;
    }
    final c = ref.read(iaContextoProvider);
    if (c == null || s.selecionados.isEmpty) return;
    final f = ref.read(filtrosSelecionadosProvider);
    FocusScope.of(context).unfocus();
    await abrirRelatorioTransferenciaPdf(
      context,
      ref,
      sequencial: c.sequencial,
      ano: f.ano,
      uf: f.estado,
      apoiadores: s.selecionados.map((a) => a.sequencial).toList(),
      tipo: tipo,
      municipio: s.municipio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final contexto = ref.watch(iaContextoProvider);
    final filtros = ref.watch(filtrosSelecionadosProvider);
    final s = ref.watch(transferenciaProvider);
    final n = ref.read(transferenciaProvider.notifier);
    final anoApoio = filtros.ano - 2;
    final rotuloCargos = anoApoio % 4 == 0
        ? 'vereador, prefeito ou vice'
        : 'deputado, senador ou governador';
    final cheio = s.selecionados.length >= maxApoiadores;
    final habilitado = contexto != null && _municipioOk(s);

    InputDecoration deco(String hint, IconData icon) => InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18),
          isDense: true,
          filled: true,
          fillColor: cs.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text('Transferência $anoApoio → ${filtros.ano}'),
      ),
      body: contexto == null
          ? Center(
              child: FilledButton(
                onPressed: () => showIaCandidatoPicker(context),
                child: const Text('Escolher candidato'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Escolha até $maxApoiadores candidatos de $anoApoio '
                  '($rotuloCargos) que apoiaram ${contexto.nomeCandidato}. '
                  'O relatório cruza os votos deles com os do candidato em '
                  '${filtros.ano}, por local de votação, bairro, zona e seção.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _municipioCtrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (v) {
                    _termoCtrl.clear();
                    n.setMunicipio(v);
                  },
                  decoration: deco(
                    _precisaMunicipio
                        ? 'Município (obrigatório)'
                        : 'Município (padrão: o da candidatura)',
                    Icons.location_city_outlined,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _termoCtrl,
                  enabled: habilitado && !cheio,
                  onChanged: n.setTermo,
                  decoration: deco(
                    'Buscar apoiador de $anoApoio por nome ou número',
                    Icons.search,
                  ),
                ),
                if (s.buscando)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (s.resultados.isNotEmpty)
                  _Caixa(
                    children: [
                      for (final a in s.resultados)
                        ListTile(
                          dense: true,
                          title: Text(a.nomeUrna),
                          subtitle: Text(_linha(a)),
                          onTap: () {
                            _termoCtrl.clear();
                            n.adicionar(a);
                          },
                        ),
                    ],
                  ),
                if (s.buscou && s.resultados.isEmpty && !s.buscando)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Nenhum apoiador de $anoApoio encontrado para essa busca.',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                if (s.selecionados.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final a in s.selecionados)
                        InputChip(
                          label: Text(
                              '${a.nomeUrna} (${a.cargo} · ${_fmt(a.votosTotal)})'),
                          onDeleted: () => n.remover(a.sequencial),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${s.selecionados.length}/$maxApoiadores',
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: s.sugerindo
                      ? null
                      : () {
                          if (!_municipioOk(s)) {
                            n.setErro(_msgMunicipio);
                            return;
                          }
                          n.sugerir();
                        },
                  icon: s.sugerindo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(s.sugerindo ? 'Analisando...' : 'Sugerir apoiadores'),
                ),
                if (s.sugestoes != null) _sugestoes(context, s, n, anoApoio),
                if (s.erro != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(s.erro!,
                        style: tt.bodySmall?.copyWith(color: cs.error)),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: s.selecionados.isEmpty
                            ? null
                            : () => _gerar('simplificado', s),
                        child: Text(
                            'Simplificado (${s.selecionados.length})'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: s.selecionados.isEmpty
                            ? null
                            : () => _gerar('completo', s),
                        child:
                            Text('Completo (${s.selecionados.length})'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Simplificado: locais e bairros. Completo: inclui zonas e seções.',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
    );
  }

  Widget _sugestoes(BuildContext context, TransferenciaState s,
      TransferenciaNotifier n, int anoApoio) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lista = s.sugestoes!;
    return _Caixa(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Candidatos de $anoApoio cuja geografia de votos mais coincide com o seu crescimento',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              if (lista.isNotEmpty)
                TextButton(
                    onPressed: n.aplicarSugestoes,
                    child: const Text('Usar todas')),
            ],
          ),
        ),
        if (lista.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Nenhuma sugestão encontrada.'),
          ),
        for (final x in lista)
          _sugestaoTile(context, x, s, n),
      ],
    );
  }

  Widget _sugestaoTile(BuildContext context, SugestaoApoiadorModel x,
      TransferenciaState s, TransferenciaNotifier n) {
    final cs = Theme.of(context).colorScheme;
    final incluido =
        s.selecionados.any((a) => a.sequencial == x.apoiador.sequencial);
    final cor = switch (x.afinidade) {
      'alta' => Colors.green,
      'media' => Colors.orange,
      _ => cs.outline,
    };
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('${x.afinidadeRotulo} · ${x.score.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: cor)),
      ),
      title: Text(x.apoiador.nomeUrna),
      subtitle: Text(_linha(x.apoiador)),
      trailing: TextButton(
        onPressed: incluido || s.selecionados.length >= maxApoiadores
            ? null
            : () => n.adicionar(x.apoiador),
        child: Text(incluido ? 'Incluído' : 'Incluir'),
      ),
    );
  }

  String _linha(ApoiadorModel a) =>
      '${a.cargo} · ${a.partido} ${a.numero} · ${_fmt(a.votosTotal)} votos'
      '${a.resultado.isNotEmpty ? ' · ${a.resultado}' : ''}';

  String _fmt(int v) => v.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}

class _Caixa extends StatelessWidget {
  const _Caixa({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(children: children),
    );
  }
}
