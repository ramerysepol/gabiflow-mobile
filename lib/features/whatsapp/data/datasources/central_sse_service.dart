import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'central_remote_datasource.dart';

/// Conexao SSE com a central (/api/whatsapp/sse) usada como GATILHO de refresh:
/// a cada evento recebido dispara [onEvento] (com debounce), sem depender do
/// formato exato de cada evento. O polling dos notifiers continua como fallback,
/// entao se a conexao cair nada quebra — so fica um pouco menos instantaneo.
class CentralSseService {
  CentralSseService(this._ds, {required this.onEvento, this.onTyping});

  final CentralRemoteDataSource _ds;
  final void Function() onEvento;

  /// Digitação do visitante do webchat (typing_start/typing_stop). Chamado
  /// com o id da conversa e o estado; typing NAO dispara [onEvento] (refresh
  /// de lista/mensagens seria desperdicio a cada tecla do cliente).
  final void Function(int conversationId, bool digitando)? onTyping;

  String _eventoAtual = '';

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
              // Formato SSE: "event: nome" define o tipo, "data: {...}" traz o
              // payload e linha em branco encerra o bloco.
              if (linha.startsWith('event:')) {
                _eventoAtual = linha.substring(6).trim();
                return;
              }
              if (linha.isEmpty) {
                _eventoAtual = '';
                return;
              }
              if (!linha.startsWith('data:')) return;
              if (_eventoAtual == 'typing_start' ||
                  _eventoAtual == 'typing_stop') {
                _tratarTyping(
                    _eventoAtual == 'typing_start', linha.substring(5).trim());
                return;
              }
              _agendar();
            },
            onError: (_) => _reconectar(),
            onDone: _reconectar,
            cancelOnError: true,
          );
    } catch (_) {
      _reconectar();
    }
  }

  void _tratarTyping(bool digitando, String payload) {
    final cb = onTyping;
    if (cb == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      final id = data is Map ? data['conversationId'] : null;
      if (id is num) cb(id.toInt(), digitando);
    } catch (_) {
      // payload não-JSON: ignora
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
