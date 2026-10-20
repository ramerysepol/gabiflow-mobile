import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/friendly_error.dart';
import '../../data/models/apuracao_mapa_uf_model.dart';
import '../apuracao_format.dart';
import '../cores_duelo.dart';
import '../providers/apuracao_mapa_uf_provider.dart';
import '../widgets/ao_vivo_pill.dart';
import '../widgets/mapa_brasil_widget.dart';
import '../widgets/tv_card_nacional.dart';

const _tvFundo = Color(0xFF0B1020);
const _intervaloPollSegundos = 15;

/// "Sala de guerra" mobile/tablet para o [cargo] (padrão 1 = Presidente):
/// card nacional gigante + mapa do Brasil, tela cheia, sem nenhuma interação
/// necessária. Atualiza sozinha a cada 15s. Em paisagem fica lado a lado; em
/// retrato empilha (com rolagem).
class ApuracaoTvPage extends ConsumerStatefulWidget {
  const ApuracaoTvPage({super.key, this.cargo = 1});

  final int cargo;

  @override
  ConsumerState<ApuracaoTvPage> createState() => _ApuracaoTvPageState();
}

class _ApuracaoTvPageState extends ConsumerState<ApuracaoTvPage> {
  Timer? _pollTimer;
  Timer? _clockTimer;
  DateTime _agora = DateTime.now();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pollTimer = Timer.periodic(
      const Duration(seconds: _intervaloPollSegundos),
      (_) {
        if (mounted) ref.invalidate(apuracaoMapaUfProvider(widget.cargo));
      },
    );
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _agora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _sair() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home/apuracao');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(apuracaoMapaUfProvider(widget.cargo));
    final dados = async.valueOrNull;

    return Scaffold(
      backgroundColor: _tvFundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            children: [
              _Topo(
                titulo: dados?.resumo?.cargoNome ?? 'Presidente',
                finalizado: dados?.resumo?.finalizado ?? false,
                temDados: dados != null && !dados.aguardando,
                agora: _agora,
                onSair: _sair,
              ),
              const SizedBox(height: 8),
              Expanded(child: _corpo(async, dados)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _corpo(AsyncValue<ApuracaoMapaUfModel> async, ApuracaoMapaUfModel? d) {
    if (d == null) {
      if (async.hasError) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: Colors.white54, size: 40),
              const SizedBox(height: 10),
              Text(
                mensagemAmigavel(async.error!),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: () =>
                    ref.invalidate(apuracaoMapaUfProvider(widget.cargo)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    if (d.aguardando) {
      return const Center(
        child: Text(
          'Aguardando o início da apuração…\nA tela atualiza sozinha.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final paisagem = c.maxWidth > c.maxHeight;
        final escala = (paisagem ? c.maxHeight / 420 : c.maxWidth / 380)
            .clamp(0.85, 2.2)
            .toDouble();
        final card = TvCardNacional(dados: d, escala: escala);
        final mapa = _PainelMapa(dados: d, escala: escala);
        if (paisagem) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: SingleChildScrollView(child: card),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 6, child: mapa),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              card,
              const SizedBox(height: 12),
              SizedBox(height: c.maxWidth * 1.05, child: mapa),
            ],
          ),
        );
      },
    );
  }
}

class _Topo extends StatelessWidget {
  const _Topo({
    required this.titulo,
    required this.finalizado,
    required this.temDados,
    required this.agora,
    required this.onSair,
  });

  final String titulo;
  final bool finalizado;
  final bool temDados;
  final DateTime agora;
  final VoidCallback onSair;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onSair,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          tooltip: 'Sair da sala de guerra',
        ),
        Expanded(
          child: Text(
            'APURAÇÃO · ${titulo.toUpperCase()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
        ),
        if (temDados) AoVivoPill(aoVivo: !finalizado),
        const SizedBox(width: 12),
        Text(
          formatarHoraApuracao(agora),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _PainelMapa extends StatelessWidget {
  const _PainelMapa({required this.dados, required this.escala});

  final ApuracaoMapaUfModel dados;
  final double escala;

  @override
  Widget build(BuildContext context) {
    final itens = dados.itens;
    Color cor(String sq) => CoresDuelo.doCandidato(sq, itens);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Expanded(
            child: MapaBrasilWidget(
              estados: dados.estados,
              corDe: cor,
              escuro: true,
              escalaTexto: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              for (final c in itens.take(2))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cor(c.sqcand),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      c.nomeUrna,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: CoresDuelo.semDados(escuro: true),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Sem dados',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
