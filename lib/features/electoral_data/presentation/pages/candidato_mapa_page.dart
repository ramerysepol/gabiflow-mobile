import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ibge_municipio_model.dart';
import '../../data/models/municipio_voto_model.dart';
import '../widgets/mapa_ba_widget.dart';
import '../widgets/microrregiao_floating_card.dart';
import '../widgets/seletor_microrregiao.dart';

/// Mapa full-screen do candidato. Pode ser embedded na tab ou standalone.
class CandidatoMapaPage extends ConsumerStatefulWidget {
  const CandidatoMapaPage({
    super.key,
    required this.sequencial,
    required this.municipios,
    required this.maxVotos,
    this.embedded = false,
    this.modoInicialCalor = false,
  });

  final String sequencial;
  final List<MunicipioVotoModel> municipios;
  final int maxVotos;
  final bool embedded;
  final bool modoInicialCalor;

  @override
  ConsumerState<CandidatoMapaPage> createState() =>
      _CandidatoMapaPageState();
}

class _CandidatoMapaPageState extends ConsumerState<CandidatoMapaPage> {
  IbgeMicrorregiao? _microrregiaoSelecionada;
  Set<String>? _microrregiaoIds;

  void _selecionarMicrorregiao(IbgeMicrorregiao micro) {
    setState(() {
      _microrregiaoSelecionada = micro;
      _microrregiaoIds = Set<String>.from(micro.municipioIds);
    });
  }

  void _limparMicrorregiao() {
    setState(() {
      _microrregiaoSelecionada = null;
      _microrregiaoIds = null;
    });
  }

  void _abrirSeletorMicrorregiao() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SeletorMicrorregiao(
        onSelected: _selecionarMicrorregiao,
        onClear: _limparMicrorregiao,
      ),
    );
  }

  void _abrirListaMunicipisMicro() {
    if (_microrregiaoSelecionada == null) return;
    final idsSet = Set<String>.from(_microrregiaoSelecionada!.municipioIds);
    final municipiosNaMicro = widget.municipios
        .where((m) => idsSet.contains(m.idMunicipio))
        .toList()
      ..sort((a, b) => b.votosMunicipio.compareTo(a.votosMunicipio));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MunicipiosMicroSheet(
        micro: _microrregiaoSelecionada!,
        municipios: municipiosNaMicro,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final mapa = MapaBaWidget(
      sequencial: widget.sequencial,
      municipios: widget.municipios,
      maxVotos: widget.maxVotos,
      microrregiaoIds: _microrregiaoIds,
      fullScreen: !widget.embedded,
      onMicrorregiaoTap: _abrirSeletorMicrorregiao,
      modoInicialCalor: widget.modoInicialCalor,
    );

    if (widget.embedded) {
      return Stack(
        children: [
          mapa,
          // Card flutuante microrregião (bottom-left) — só quando selecionada
          if (_microrregiaoSelecionada != null)
            Positioned(
              bottom: 16,
              left: 12,
              child: MicrorregiaoFloatingCard(
                micro: _microrregiaoSelecionada!,
                municipios: widget.municipios,
                onClear: _limparMicrorregiao,
                onVerTodos: _abrirListaMunicipisMicro,
              ),
            ),
          // Botão full-screen (acima dos controles do mapa)
          Positioned(
            bottom: 200,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'fullscreen',
              backgroundColor: cs.primaryContainer,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CandidatoMapaPage(
                    sequencial: widget.sequencial,
                    municipios: widget.municipios,
                    maxVotos: widget.maxVotos,
                    embedded: false,
                  ),
                ),
              ),
              child: Icon(Icons.fullscreen, color: cs.onPrimaryContainer),
            ),
          ),
        ],
      );
    }

    // Full-screen standalone
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Votos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            onPressed: _abrirSeletorMicrorregiao,
            tooltip: 'Filtrar por microrregião',
          ),
        ],
      ),
      body: Stack(
        children: [
          mapa,
          // Card flutuante da microrregião selecionada (bottom-left)
          if (_microrregiaoSelecionada != null)
            Positioned(
              bottom: 16,
              left: 12,
              child: MicrorregiaoFloatingCard(
                micro: _microrregiaoSelecionada!,
                municipios: widget.municipios,
                onClear: _limparMicrorregiao,
                onVerTodos: _abrirListaMunicipisMicro,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Sheet: lista de municípios da microrregião ───────────────────────────────

class _MunicipiosMicroSheet extends StatelessWidget {
  const _MunicipiosMicroSheet({
    required this.micro,
    required this.municipios,
  });

  final IbgeMicrorregiao micro;
  final List<MunicipioVotoModel> municipios;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalVotos =
        municipios.fold(0, (sum, m) => sum + m.votosMunicipio);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            micro.nome,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${municipios.length} municípios · $totalVotos votos totais',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: municipios.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum município com votos',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.only(bottom: 32),
                        itemCount: municipios.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final m = municipios[i];
                          final pct = totalVotos > 0
                              ? m.votosMunicipio / totalVotos * 100
                              : 0.0;
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              m.nomeMunicipio,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${m.votosMunicipio}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: cs.primary,
                                  ),
                                ),
                                Text(
                                  '${pct.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
