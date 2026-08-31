/// Widgets de midia do chat da central — imagem inline com tela cheia,
/// documento e video abrindo no navegador/visualizador do sistema.
/// Audio inline (player) chega na Fase 2b; por ora abre externamente.
library;

import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/central_models.dart';
import 'texto_copiavel.dart';

/// Player unico compartilhado: tocar um audio pausa o anterior,
/// como no WhatsApp.
class _AudioCentral {
  static final AudioPlayer player = AudioPlayer();
  static final ValueNotifier<String?> urlAtual = ValueNotifier<String?>(null);

  /// Velocidade de reproducao (1x → 1.5x → 2x), como no WhatsApp.
  static final ValueNotifier<double> velocidade = ValueNotifier<double>(1.0);
  static void ciclarVelocidade() {
    const passos = [1.0, 1.5, 2.0];
    final atual = passos.indexOf(velocidade.value);
    final proxima = passos[(atual + 1) % passos.length];
    velocidade.value = proxima;
    player.setSpeed(proxima);
  }

  /// URLs ja ouvidas ate o fim — ficam 100% azuis (WhatsApp).
  /// Persistido em SharedPreferences pra sobreviver a sair/voltar do chat
  /// e a reinicios do app.
  static final Set<String> ouvidos = <String>{};
  static final ValueNotifier<int> ouvidosVersao = ValueNotifier<int>(0);
  static bool _listenerPronto = false;

  static const _chaveOuvidos = 'central_audios_ouvidos';
  static bool _ouvidosCarregados = false;

  /// Carrega do disco na primeira bolha de audio renderizada.
  static Future<void> carregarOuvidos() async {
    if (_ouvidosCarregados) return;
    _ouvidosCarregados = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvos = prefs.getStringList(_chaveOuvidos) ?? const [];
      if (salvos.isNotEmpty) {
        ouvidos.addAll(salvos);
        ouvidosVersao.value++;
      }
    } catch (_) {
      // Sem persistencia disponivel — segue so com o estado em memoria.
    }
  }

  static Future<void> _salvarOuvidos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Mantem no maximo 500 audios pra lista nao crescer sem limite.
      var lista = ouvidos.toList();
      if (lista.length > 500) lista = lista.sublist(lista.length - 500);
      await prefs.setStringList(_chaveOuvidos, lista);
    } catch (_) {}
  }

  static void _garantirListener() {
    if (_listenerPronto) return;
    _listenerPronto = true;
    player.processingStateStream.listen((s) {
      final url = urlAtual.value;
      if (s == ProcessingState.completed && url != null && ouvidos.add(url)) {
        ouvidosVersao.value++;
        _salvarOuvidos();
      }
    });
  }

  /// iOS não decodifica ogg/opus (formato das notas de voz do WhatsApp).
  /// No iPhone, áudios .ogg de /uploads passam pela rota de transcodificação
  /// AAC do servidor; Android e demais tocam a URL original.
  static String _urlReproducao(String url) {
    if (!Platform.isIOS) return url;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final p = uri.path.toLowerCase();
    final ehOgg =
        p.endsWith('.ogg') || p.endsWith('.opus') || p.endsWith('.oga');
    if (!ehOgg || !uri.path.startsWith('/uploads/whatsapp/')) return url;
    return uri
        .replace(
          path: '/api/whatsapp/media/aac',
          queryParameters: {'src': uri.path},
        )
        .toString();
  }

  static bool _sessaoPronta = false;

  /// Garante a sessão de áudio em modo reprodução — o plugin de gravação
  /// (record) pode deixá-la em categoria de captura, que sai mudo no iOS.
  static Future<void> _garantirSessao() async {
    if (_sessaoPronta) return;
    _sessaoPronta = true;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (_) {
      // Sem sessão configurável — segue com o padrão da plataforma.
    }
  }

  static Future<void> tocar(String url) async {
    _garantirListener();
    await _garantirSessao();
    if (urlAtual.value != url) {
      await player.stop();
      urlAtual.value = url;
      await player.setUrl(_urlReproducao(url));
    }
    // Terminou? Volta pro inicio antes de tocar de novo.
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    await player.play();
  }
}

/// Conteudo da bolha para mensagens de midia.
class MidiaConteudo extends StatelessWidget {
  const MidiaConteudo({
    super.key,
    required this.mensagem,
    required this.corTexto,
  });

  final Mensagem mensagem;
  final Color corTexto;

  @override
  Widget build(BuildContext context) {
    switch (mensagem.contentType) {
      case 'image':
      case 'sticker':
        return _Imagem(mensagem: mensagem, corTexto: corTexto);
      case 'video':
        return mensagem.mediaUrl == null
            ? _ArquivoTile(
                mensagem: mensagem,
                corTexto: corTexto,
                icone: Icons.play_circle_fill_rounded,
                rotulo: mensagem.mediaFilename ?? 'Vídeo',
                dica: 'Tocar vídeo',
              )
            : _VideoBolha(
                url: mensagem.mediaUrl!,
                caption: mensagem.caption,
                corTexto: corTexto,
              );
      case 'audio':
      case 'ptt': // nota de voz vinda da Z-API
      case 'voice':
        return mensagem.mediaUrl == null
            ? _ArquivoTile(
                mensagem: mensagem,
                corTexto: corTexto,
                icone: Icons.mic_rounded,
                rotulo: 'Mensagem de voz',
                dica: 'Ouvir áudio',
              )
            : _AudioBolha(url: mensagem.mediaUrl!, corTexto: corTexto);
      case 'document':
        return _ArquivoTile(
          mensagem: mensagem,
          corTexto: corTexto,
          icone: Icons.insert_drive_file_rounded,
          rotulo: mensagem.mediaFilename ?? 'Documento',
          dica: 'Abrir documento',
        );
      default:
        return TextoComCopiaveis(
          texto: mensagem.previewTexto,
          corTexto: corTexto,
        );
    }
  }
}

class _Imagem extends StatelessWidget {
  const _Imagem({required this.mensagem, required this.corTexto});

  final Mensagem mensagem;
  final Color corTexto;

  @override
  Widget build(BuildContext context) {
    final local = mensagem.localFilePath;
    final url = mensagem.mediaUrl;

    Widget img;
    if (local != null) {
      img = Image.file(File(local), fit: BoxFit.cover);
    } else if (url != null) {
      img = Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                height: 180,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
        errorBuilder: (_, __, ___) => Container(
          height: 120,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_rounded,
                color: corTexto.withValues(alpha: 0.5),
              ),
              Text(
                'Falha ao carregar imagem',
                style: TextStyle(
                  fontSize: 11,
                  color: corTexto.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Text('📷 Foto', style: TextStyle(fontSize: 15, color: corTexto));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: url == null && local == null
              ? null
              : () => _abrirTelaCheia(context, url: url, local: local),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, minWidth: 160),
              child: img,
            ),
          ),
        ),
        if (mensagem.caption != null && mensagem.caption!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              mensagem.caption!,
              style: TextStyle(fontSize: 14, color: corTexto, height: 1.25),
            ),
          ),
      ],
    );
  }

  void _abrirTelaCheia(BuildContext context, {String? url, String? local}) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      // O contexto do proprio dialogo garante o pop no navegador certo
      // (com go_router, o contexto de fora fecharia a rota errada).
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: local != null
                      ? Image.file(File(local))
                      : Image.network(url!),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bolha de video estilo WhatsApp: quadro escuro com play; toca DENTRO do
/// app em tela cheia com controles (chewie/video_player).
class _VideoBolha extends StatelessWidget {
  const _VideoBolha({required this.url, required this.corTexto, this.caption});

  final String url;
  final String? caption;
  final Color corTexto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => showDialog<void>(
            context: context,
            barrierColor: Colors.black,
            builder: (dialogContext) => _VideoTelaCheia(
              url: url,
              onFechar: () => Navigator.of(dialogContext).pop(),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 230,
              height: 150,
              color: Colors.black87,
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
            ),
          ),
        ),
        if (caption != null && caption!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              caption!,
              style: TextStyle(fontSize: 14, color: corTexto, height: 1.25),
            ),
          ),
      ],
    );
  }
}

class _VideoTelaCheia extends StatefulWidget {
  const _VideoTelaCheia({required this.url, required this.onFechar});

  final String url;
  final VoidCallback onFechar;

  @override
  State<_VideoTelaCheia> createState() => _VideoTelaCheiaState();
}

class _VideoTelaCheiaState extends State<_VideoTelaCheia> {
  late final VideoPlayerController _video;
  ChewieController? _chewie;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _video = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _video
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {
            _chewie = ChewieController(
              videoPlayerController: _video,
              autoPlay: true,
              allowFullScreen: false,
              allowMuting: true,
            );
          });
        })
        .catchError((Object e) {
          if (mounted) setState(() => _erro = e.toString());
        });
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: _erro != null
                  ? Text(
                      'Não foi possível reproduzir o vídeo.\n$_erro',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    )
                  : _chewie == null
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Chewie(controller: _chewie!),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: widget.onFechar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bolha de audio com play/pause, progresso e duracao — sem sair do app.
class _AudioBolha extends StatelessWidget {
  const _AudioBolha({required this.url, required this.corTexto});

  final String url;
  final Color corTexto;

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Restaura os "ja ouvidos" do disco (no-op apos a primeira chamada);
    // quando carregar, ouvidosVersao muda e o builder repinta.
    _AudioCentral.carregarOuvidos();
    return ListenableBuilder(
      listenable: Listenable.merge([
        _AudioCentral.urlAtual,
        _AudioCentral.ouvidosVersao,
      ]),
      builder: (context, _) {
        final souAtiva = _AudioCentral.urlAtual.value == url;
        final jaOuvido = _AudioCentral.ouvidos.contains(url);
        return SizedBox(
          width: 230,
          child: Row(
            children: [
              StreamBuilder<PlayerState>(
                stream: _AudioCentral.player.playerStateStream,
                builder: (context, snap) {
                  final tocando =
                      souAtiva &&
                      (snap.data?.playing ?? false) &&
                      snap.data?.processingState != ProcessingState.completed;
                  final carregando =
                      souAtiva &&
                      (snap.data?.processingState == ProcessingState.loading ||
                          snap.data?.processingState ==
                              ProcessingState.buffering);
                  return InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      if (tocando) {
                        await _AudioCentral.player.pause();
                      } else {
                        await _AudioCentral.tocar(url);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: carregando
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              tocando
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: souAtiva
                      ? _AudioCentral.player.positionStream
                      : const Stream<Duration>.empty(),
                  builder: (context, snap) {
                    final posicao = souAtiva
                        ? (snap.data ?? Duration.zero)
                        : Duration.zero;
                    final total = souAtiva
                        ? (_AudioCentral.player.duration ?? Duration.zero)
                        : Duration.zero;
                    // Ja ouvido ate o fim: permanece 100% azul (WhatsApp).
                    final progresso = souAtiva && total.inMilliseconds > 0
                        ? (posicao.inMilliseconds / total.inMilliseconds).clamp(
                            0.0,
                            1.0,
                          )
                        : (jaOuvido ? 1.0 : 0.0);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Ondinhas(
                          seed: url,
                          progresso: progresso,
                          corBase: corTexto.withValues(alpha: 0.25),
                          onSeek: !souAtiva || total == Duration.zero
                              ? null
                              : (v) => _AudioCentral.player.seek(
                                  Duration(
                                    milliseconds: (total.inMilliseconds * v)
                                        .round(),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          souAtiva && total > Duration.zero
                              ? '${_fmt(posicao)} / ${_fmt(total)}'
                              : 'Mensagem de voz',
                          style: TextStyle(
                            fontSize: 11,
                            color: corTexto.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (souAtiva)
                ValueListenableBuilder<double>(
                  valueListenable: _AudioCentral.velocidade,
                  builder: (context, vel, _) => InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _AudioCentral.ciclarVelocidade,
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: corTexto.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        vel == vel.roundToDouble()
                            ? '${vel.toInt()}x'
                            : '${vel}x',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: corTexto.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Ondinhas do audio (estilo WhatsApp/web): barras pseudo-aleatorias
/// derivadas da URL (estaveis entre rebuilds), pintadas de verde conforme
/// o progresso; toque busca a posicao.
class _Ondinhas extends StatelessWidget {
  const _Ondinhas({
    required this.seed,
    required this.progresso,
    required this.corBase,
    this.onSeek,
  });

  final String seed;
  final double progresso;
  final Color corBase;
  final ValueChanged<double>? onSeek;

  static const int _qtd = 28;

  List<double> _alturas() {
    var estado = seed.codeUnits.fold<int>(2166136261, (a, c) {
      final x = (a ^ c) * 16777619;
      return x & 0x7fffffff;
    });
    final alturas = <double>[];
    for (var i = 0; i < _qtd; i++) {
      estado = (estado * 48271) % 0x7fffffff;
      alturas.add(6 + (estado % 17).toDouble()); // 6..22 px
    }
    return alturas;
  }

  @override
  Widget build(BuildContext context) {
    final alturas = _alturas();
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onSeek == null
            ? null
            : (d) => onSeek!(
                (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
              ),
        child: SizedBox(
          height: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < _qtd; i++) ...[
                Expanded(
                  child: Container(
                    height: alturas[i],
                    decoration: BoxDecoration(
                      // Parte ja ouvida fica azul, como no WhatsApp.
                      color: (i + 1) / _qtd <= progresso
                          ? const Color(0xFF53BDEB)
                          : corBase,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < _qtd - 1) const SizedBox(width: 2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ArquivoTile extends StatelessWidget {
  const _ArquivoTile({
    required this.mensagem,
    required this.corTexto,
    required this.icone,
    required this.rotulo,
    required this.dica,
  });

  final Mensagem mensagem;
  final Color corTexto;
  final IconData icone;
  final String rotulo;
  final String dica;

  @override
  Widget build(BuildContext context) {
    final url = mensagem.mediaUrl;
    return InkWell(
      onTap: url == null
          ? null
          : () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: const Color(0xFF128C7E), size: 22),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: corTexto,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  url == null ? 'Enviando…' : dica,
                  style: TextStyle(
                    fontSize: 11,
                    color: corTexto.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
