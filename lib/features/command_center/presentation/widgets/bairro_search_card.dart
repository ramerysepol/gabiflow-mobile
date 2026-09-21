import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../electoral_data/presentation/providers/eleitoral_providers.dart';
import '../providers/command_center_providers.dart';
import 'relatorio_bairros_pdf.dart';

/// Cargos municipais: o município de referência é o da candidatura.
bool cargoMunicipal(String? cargo) {
  final c = (cargo ?? '').toUpperCase();
  return c.contains('VEREADOR') || c.contains('PREFEITO');
}

/// Painel "Pesquisa por bairro" do Command Center: monta perguntas prontas
/// para o chat (que usa as tools por bairro) e gera o PDF por bairros.
class BairroSearchCard extends ConsumerStatefulWidget {
  const BairroSearchCard({super.key});

  @override
  ConsumerState<BairroSearchCard> createState() => _BairroSearchCardState();
}

class _BairroSearchCardState extends ConsumerState<BairroSearchCard> {
  final _municipioCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _municipioCtrl.dispose();
    _bairroCtrl.dispose();
    super.dispose();
  }

  bool get _precisaMunicipio =>
      !cargoMunicipal(ref.read(iaContextoProvider)?.cargo);

  String get _sufixoMunicipio {
    final m = _municipioCtrl.text.trim();
    return m.isEmpty ? '' : ' em $m';
  }

  bool _validar() {
    if (_precisaMunicipio && _municipioCtrl.text.trim().isEmpty) {
      setState(() => _erro =
          'Para deputado, senador ou governador, informe o município de referência.');
      return false;
    }
    setState(() => _erro = null);
    return true;
  }

  void _perguntar(String texto) {
    if (!_validar()) return;
    FocusScope.of(context).unfocus();
    context.push(
      Uri(
        path: '/home/eleitoral/ia/chat',
        queryParameters: {'q': texto},
      ).toString(),
    );
  }

  void _pesquisarBairro() {
    final bairro = _bairroCtrl.text.trim();
    if (bairro.isEmpty) return;
    _perguntar(
      'Como foi minha votação no bairro $bairro$_sufixoMunicipio? '
      'Quem foram os mais votados lá e em que posição fiquei?',
    );
  }

  Future<void> _pdf() async {
    if (!_validar()) return;
    final contexto = ref.read(iaContextoProvider);
    if (contexto == null) return;
    final filtros = ref.read(filtrosSelecionadosProvider);
    FocusScope.of(context).unfocus();
    await abrirRelatorioBairrosPdf(
      context,
      ref,
      RelatorioBairrosParams(
        tipo: 'votos',
        sequencial: contexto.sequencial,
        ano: filtros.ano.toString(),
        uf: filtros.estado,
        municipio: _municipioCtrl.text.trim().isEmpty
            ? null
            : _municipioCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final contexto = ref.watch(iaContextoProvider);
    final precisaMunicipio = !cargoMunicipal(contexto?.cargo);

    InputDecoration deco(String hint, IconData icon) => InputDecoration(
          hintText: hint,
          hintStyle: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          prefixIcon: Icon(icon, size: 18),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: cs.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
          ),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pesquisa por bairro',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Votos por seção cruzados com o local de votação (TSE).',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _municipioCtrl,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: deco(
              precisaMunicipio
                  ? 'Município de referência (obrigatório)'
                  : 'Município (opcional, padrão: o da candidatura)',
              Icons.location_city_outlined,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bairroCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _pesquisarBairro(),
                  decoration: deco('Bairro (ex.: Pernambués)', Icons.search),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onPressed: _pesquisarBairro,
                child: const Text('Pesquisar'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                icon: Icons.location_on_outlined,
                label: 'Meus bairros',
                onTap: () =>
                    _perguntar('Quais são meus melhores bairros$_sufixoMunicipio?'),
              ),
              _Chip(
                icon: Icons.trending_up_rounded,
                label: 'Onde crescer',
                onTap: () => _perguntar(
                    'Em quais bairros$_sufixoMunicipio eu posso crescer? Mostre os bairros fracos.'),
              ),
              _Chip(
                icon: Icons.compare_arrows_rounded,
                label: 'Comparar eleições',
                onTap: () => _perguntar(
                    'Compare minha votação por bairro$_sufixoMunicipio com a eleição mais recente carregada de outro ano. Onde minha base atual pesa mais e quem lidera cada bairro?'),
              ),
              _Chip(
                icon: Icons.people_outline_rounded,
                label: 'Base do gabinete',
                onTap: () => _perguntar(
                    'Cruze meus votos por bairro$_sufixoMunicipio com os munícipes cadastrados no gabinete. Onde tenho voto e não tenho base?'),
              ),
              _Chip(
                icon: Icons.picture_as_pdf_outlined,
                label: 'PDF por bairros',
                destaque: true,
                onTap: _pdf,
              ),
            ],
          ),
          if (_erro != null) ...[
            const SizedBox(height: 8),
            Text(
              _erro!,
              style: tt.labelSmall?.copyWith(color: cs.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destaque = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: destaque
              ? cs.primary.withValues(alpha: 0.12)
              : cs.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: destaque
              ? Border.all(color: cs.primary.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
