import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/friendly_error.dart';
import '../apuracao_format.dart';
import '../providers/apuracao_mapa_uf_provider.dart';
import '../widgets/apuracao_estados_vazios.dart';
import '../widgets/card_mapa_brasil.dart';
import '../widgets/card_nacional_duelo.dart';
import '../widgets/lista_estados_card.dart';

const _intervaloPollSegundos = 30;

/// Dashboard da Apuração ao vivo (resultados oficiais do TSE) para a disputa
/// nacional de [cargo] (padrão 1 = Presidente): card nacional com o duelo,
/// mapa do Brasil por estados e lista por UF.
///
/// Renderiza dentro do shell da Home (header + dock). Atualiza sozinha a cada
/// 30s e por pull-to-refresh.
class ApuracaoPage extends ConsumerStatefulWidget {
  const ApuracaoPage({super.key, this.cargo = 1});

  final int cargo;

  @override
  ConsumerState<ApuracaoPage> createState() => _ApuracaoPageState();
}

class _ApuracaoPageState extends ConsumerState<ApuracaoPage> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(
      const Duration(seconds: _intervaloPollSegundos),
      (_) {
        if (mounted) ref.invalidate(apuracaoMapaUfProvider(widget.cargo));
      },
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _recarregar() async {
    try {
      ref.invalidate(apuracaoMapaUfProvider(widget.cargo));
      await ref.read(apuracaoMapaUfProvider(widget.cargo).future);
    } catch (_) {
      // O erro já aparece no estado do provider.
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(apuracaoMapaUfProvider(widget.cargo));

    return RefreshIndicator(
      onRefresh: _recarregar,
      child: async.when(
        skipLoadingOnRefresh: true,
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (e, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ApuracaoErro(
              mensagem: mensagemAmigavel(e),
              onRetry: () =>
                  ref.invalidate(apuracaoMapaUfProvider(widget.cargo)),
            ),
          ],
        ),
        data: (dados) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
          children: [
            _Cabecalho(cargo: widget.cargo),
            const SizedBox(height: 12),
            if (dados.aguardando)
              const AguardandoApuracao(
                intervaloSegundos: _intervaloPollSegundos,
              )
            else ...[
              LayoutBuilder(
                builder: (context, c) {
                  final nacional = CardNacionalDuelo(dados: dados);
                  final mapa = CardMapaBrasil(dados: dados);
                  if (c.maxWidth >= 760) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: nacional),
                        const SizedBox(width: 12),
                        Expanded(flex: 6, child: mapa),
                      ],
                    );
                  }
                  return Column(
                    children: [nacional, const SizedBox(height: 12), mapa],
                  );
                },
              ),
              const SizedBox(height: 12),
              ListaEstadosCard(estados: dados.estados, itens: dados.itens),
              const SizedBox(height: 12),
              Text(
                'Fonte: Tribunal Superior Eleitoral (divulgação oficial). '
                'Percentuais sobre os votos válidos já totalizados — os '
                'números mudam até a totalização final. Última atualização '
                'do TSE: ${formatarHoraApuracao(dados.resumo?.atualizadoEm)}.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.cargo});

  final int cargo;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Dados oficiais do TSE, atualizados a cada '
            '$_intervaloPollSegundos segundos.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0B1020),
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => context.push('/home/apuracao/tv?cargo=$cargo'),
          icon: const Icon(Icons.tv_rounded, size: 16),
          label: const Text('Sala de guerra'),
        ),
      ],
    );
  }
}
