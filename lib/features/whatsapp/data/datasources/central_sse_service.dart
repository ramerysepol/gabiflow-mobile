import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'central_remote_datasource.dart';

/// Conexao SSE com a central (/api/whatsapp/sse) usada como GATILHO de refresh:
/// a cada evento recebido dispara [onEvento] (com debounce), sem depender do
/// formato exato de cada evento. O polling dos notifiers continua como fallback,
/// entao se a conexao cair nada quebra — so fica um pouco menos instantaneo.
class CentralSseService {
  CentralSseService(this._ds, {required this.onEvento});

  final CentralRemoteDataSource _ds;
  final void Function() onEvento;

  CancelToken? _cancel;
  StreamSubscription<String>? _sub;
  Timer? _debounce;
  Timer? _reconexao;
  bool _fechado = false;
  int _tentativas = 0;

  Future<void> conectar() async {
    if (_fechado) return;
    _cancel = CancelToken();
    try {
      final body = await _ds.conectarSse(_cancel!);
      _tentativas = 0;
      _sub = body.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (linha) {
              // Linhas SSE de dados começam com "data:". Ignora comentários
              // (keepalive ":") e cabeçalhos de evento.
              if (linha.startsWith('data:')) _agendar();
            },
            onError: (_) => _reconectar(),
            onDone: _reconectar,
            cancelOnError: true,
          );
    } catch (_) {
      _reconectar();
    }
  }

  void _agendar() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!_fechado) onEvento();
    });
  }

  void _reconectar() {
    if (_fechado) return;
    _sub?.cancel();
    _sub = null;
    _tentativas = (_tentativas + 1).clamp(1, 6);
    final segundos = [2, 4, 8, 15, 30, 30][_tentativas - 1];
    _reconexao?.cancel();
    _reconexao = Timer(Duration(seconds: segundos), conectar);
  }

  void fechar() {
    _fechado = true;
    _debounce?.cancel();
    _reconexao?.cancel();
    _sub?.cancel();
    _cancel?.cancel('fechado');
  }
}
