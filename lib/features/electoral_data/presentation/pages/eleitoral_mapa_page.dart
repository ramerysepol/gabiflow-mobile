import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/candidato_model.dart';
import '../providers/eleitoral_providers.dart';
import '../widgets/erro_inline.dart';
import '../widgets/numero_formatado.dart';
import 'candidato_mapa_page.dart';

/// Aba MAPA do sub-app Eleitoral — o mapa de calor como destino de primeira
/// classe: escolhe o candidato e vê a mancha de votos na Bahia, já no modo
/// calor, com legenda dinâmica, drill-down por zonas e microrregiões.
class EleitoralMapaPage extends ConsumerStatefulWidget {
  const EleitoralMapaPage({super.key});

  @override
  ConsumerState<EleitoralMapaPage> createState() => _EleitoralMapaPageState();
}

class _EleitoralMapaPageState extends ConsumerState<EleitoralMapaPage> {
  CandidatoModel? _candidato;

  Future<void> _escolherCandidato() async {
    ref.read(comparacaoSearchProvider.notifier).state = '';
    final escolhido = await showModalBottomSheet<CandidatoModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _BuscaCandidatoSheet(),
    );
    if (escolhido != null && mounted) {
      setState(() => _candidato = escolhido);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Candidato pertence à eleição: trocou a eleição, limpa a seleção.
    ref.listen(selectedElectionProvider, (prev, next) {
      if (prev != null && next != null && prev.label != next.label &&
          _candidato != null) {
        setState(() => _candidato = null);
      }
    });

    final eleicao = ref.watch(selectedElectionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corHeader =
        isDark ? const Color(0xFF10151F) : const Color(0xFF16213E);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: corHeader,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFFF7043), size: 22),
            const SizedBox(width: 8),
            const Text('Mapa de Calor',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const Spacer(),
            if (eleicao != null)
              Text(eleicao.label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: eleicao == null
          ? _Convite(
              titulo: 'Selecione a eleição primeiro',
              botao: 'Selecionar eleição',
              onTap: () => context.push('/home/eleitoral/selecionar'),
            )
          : _candidato == null
              ? _Convite(
                  titulo:
                      'Escolha um candidato para acender o mapa de votos da Bahia',
                  botao: 'Escolher candidato',
                  onTap: _escolherCandidato,
                )
              : _MapaDoCandidato(
                  candidato: _candidato!,
                  onTrocar: _escolherCandidato,
                ),
    );
  }
}

class _Convite extends StatelessWidget {
  const _Convite({
    required this.titulo,
    required this.botao,
    required this.onTap,
  });

  final String titulo;
  final String botao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFEF6C00)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  size: 44, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(botao),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapaDoCandidato extends ConsumerWidget {
  const _MapaDoCandidato({required this.candidato, required this.onTrocar});

  final CandidatoModel candidato;
  final VoidCallback onTrocar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapa = ref.watch(candidatoMapaProvider(candidato.sequencial));
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Faixa do candidato selecionado
        Material(
          color: cs.surface,
          child: ListTile(
            dense: true,
            leading: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFEF6C00),
              child: Icon(Icons.person_rounded,
                  size: 18, color: Colors.white),
            ),
            title: Text(
              candidato.nomeUrna,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14),
            ),
            subtitle: Text(
              '${candidato.siglaPartido} · ${formatarVotos(candidato.votosTotal)} votos',
              style: const TextStyle(fontSize: 11.5),
            ),
            trailing: TextButton.icon(
              onPressed: onTrocar,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('Trocar', style: TextStyle(fontSize: 12)),
            ),
            onTap: () => context
                .push('/home/eleitoral/candidato/${candidato.sequencial}'),
          ),
        ),
        Expanded(
          child: mapa.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErroInline(
              mensagem: 'Não foi possível carregar o mapa.',
              onRetry: () =>
                  ref.invalidate(candidatoMapaProvider(candidato.sequencial)),
            ),
            data: (dados) => CandidatoMapaPage(
              sequencial: candidato.sequencial,
              municipios: dados.municipios,
              maxVotos: dados.maxVotosMunicipio,
              embedded: true,
              modoInicialCalor: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// Busca de candidato (reusa os providers da comparação).
class _BuscaCandidatoSheet extends ConsumerStatefulWidget {
  const _BuscaCandidatoSheet();

  @override
  ConsumerState<_BuscaCandidatoSheet> createState() =>
      _BuscaCandidatoSheetState();
}

class _BuscaCandidatoSheetState extends ConsumerState<_BuscaCandidatoSheet> {
  @override
  Widget build(BuildContext context) {
    final resultado = ref.watch(comparacaoCandidatoBuscaProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (v) =>
                  ref.read(comparacaoSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Nome do candidato',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: resultado.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Falha na busca: $e')),
              data: (pagina) => pagina.items.isEmpty
                  ? const Center(
                      child: Text('Digite o nome pra buscar.',
                          style: TextStyle(fontSize: 13)))
                  : ListView.builder(
                      itemCount: pagina.items.length,
                      itemBuilder: (ctx, i) {
                        final c = pagina.items[i];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            child: Text(
                              c.nomeUrna.isNotEmpty
                                  ? c.nomeUrna.characters.first
                                  : '?',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          title: Text(c.nomeUrna,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${c.siglaPartido} · ${c.cargo} · ${formatarVotos(c.votosTotal)} votos',
                              style: const TextStyle(fontSize: 11.5)),
                          onTap: () => Navigator.of(ctx).pop(c),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
