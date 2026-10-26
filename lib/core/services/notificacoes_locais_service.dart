import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'logger_service.dart';

/// Serviço de notificações locais (in-app), usado para avisos de mensagens
/// de WhatsApp em primeiro plano. A inicialização é lazy.
abstract final class NotificacoesLocaisService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _inicializado = false;

  /// Callback chamado quando o usuário toca numa notificação local que tem
  /// payload (ex.: mensagem de WhatsApp em primeiro plano). Definido pelo
  /// PushService.
  static void Function(String payload)? aoTocar;

  static const _canalWhatsappId = 'whatsapp';
  static const _canalWhatsappNome = 'Mensagens de WhatsApp';
  static const _canalWhatsappDescricao =
      'Avisos de novas mensagens recebidas no atendimento';

  /// Inicializa o plugin, cria o canal Android e pede permissão ao usuário.
  /// Seguro de chamar mais de uma vez — só executa na primeira.
  static Future<void> init() async {
    if (_inicializado) return;
    _inicializado = true;
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      // No iOS, initialize() já solicita a permissão de alert/sound/badge
      // (valores padrão de DarwinInitializationSettings).
      const iosSettings = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: (resposta) {
          final payload = resposta.payload;
          if (payload != null && payload.isNotEmpty) aoTocar?.call(payload);
        },
      );

      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _canalWhatsappId,
          _canalWhatsappNome,
          description: _canalWhatsappDescricao,
          importance: Importance.high,
        ),
      );
      await androidImpl?.requestNotificationsPermission();
    } catch (e, st) {
      LoggerService.e('Falha ao inicializar notificações locais', e, st);
    }
  }

  /// Mostra uma notificação de mensagem de WhatsApp (canal 'whatsapp'),
  /// carregando [payload] para o tap abrir a conversa.
  static Future<void> mostrarWhatsapp(
    int id,
    String titulo,
    String corpo, {
    String? payload,
  }) async {
    if (!_inicializado) await init();
    try {
      await _plugin.show(
        id,
        titulo,
        corpo,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _canalWhatsappId,
            _canalWhatsappNome,
            channelDescription: _canalWhatsappDescricao,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e, st) {
      LoggerService.e('Falha ao mostrar notificação de WhatsApp', e, st);
    }
  }
}
