// Visuais compartilhados da Central (canais e etiquetas), em paridade com a
// central web (ConversationList.tsx / ChatHeader.tsx):
//  - canal efetivo: webchat + channel_account_id 'app' => 'app' (App), senao o
//    proprio canal;
//  - cores/labels/icones por canal (whatsapp/instagram/messenger/webchat/app);
//  - resolucao de cor de etiqueta (formato "nome:#cor" ou via catalogo).

import 'package:flutter/material.dart';

/// Deriva o canal "efetivo" para exibicao. App e Site compartilham o canal
/// `webchat`; a distincao vem do `channelAccountId` ('app' = App PagMeia).
String canalEfetivo(String channel, String? channelAccountId) {
  if (channel == 'webchat' && channelAccountId == 'app') return 'app';
  return channel;
}

/// True quando a conversa veio do app OU do site (canal webchat) — usado para
/// mostrar o botao "copiar nome".
bool canalAppOuSite(String channel, String? channelAccountId) {
  final c = canalEfetivo(channel, channelAccountId);
  return c == 'app' || c == 'webchat';
}

class CanalVisual {
  final String label;
  final Color cor;
  final IconData icone;
  const CanalVisual(this.label, this.cor, this.icone);
}

/// Visual por canal efetivo (mesmas cores da central web).
CanalVisual canalVisual(String canalEfetivo) {
  switch (canalEfetivo) {
    case 'instagram':
      return const CanalVisual(
          'Instagram', Color(0xFFE4405F), Icons.camera_alt_rounded);
    case 'messenger':
      return const CanalVisual(
          'Messenger', Color(0xFF0084FF), Icons.messenger_outline_rounded);
    case 'app':
      return const CanalVisual('App', Color(0xFF0095F3), Icons.phone_iphone_rounded);
    case 'webchat':
      return const CanalVisual('Site', Color(0xFF6366F1), Icons.language_rounded);
    case 'whatsapp':
    default:
      return const CanalVisual('WhatsApp', Color(0xFF25D366), Icons.chat_rounded);
  }
}

/// Etiqueta resolvida (nome + cor) pronta para render.
class EtiquetaResolvida {
  final String nome;
  final Color cor;
  const EtiquetaResolvida(this.nome, this.cor);
}

const Color _corEtiquetaPadrao = Color(0xFF6B7280); // cinza neutro

Color? _hexToColor(String? hex) {
  if (hex == null) return null;
  var h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

/// Resolve uma string de etiqueta vinda da conversa. Aceita tanto o formato
/// "nome:#RRGGBB" (usado em alguns pontos do web) quanto so o nome — nesse
/// caso a cor vem do [catalogo] (mapa nome->hex). Sem cor conhecida, usa o
/// cinza padrao.
EtiquetaResolvida resolverEtiqueta(String bruta, Map<String, String> catalogo) {
  var nome = bruta.trim();
  String? hex;
  final idx = nome.lastIndexOf(':');
  if (idx > 0 && idx < nome.length - 1 && nome.substring(idx + 1).contains('#')) {
    hex = nome.substring(idx + 1).trim();
    nome = nome.substring(0, idx).trim();
  }
  hex ??= catalogo[nome];
  return EtiquetaResolvida(nome, _hexToColor(hex) ?? _corEtiquetaPadrao);
}

/// Chip pequeno para render de etiqueta na lista/cabecalho.
class EtiquetaChip extends StatelessWidget {
  const EtiquetaChip(this.etiqueta, {super.key, this.compacto = false});

  final EtiquetaResolvida etiqueta;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 6 : 8,
        vertical: compacto ? 1 : 3,
      ),
      decoration: BoxDecoration(
        color: etiqueta.cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: etiqueta.cor.withValues(alpha: 0.55)),
      ),
      child: Text(
        etiqueta.nome,
        style: TextStyle(
          fontSize: compacto ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: etiqueta.cor,
        ),
      ),
    );
  }
}

/// Badge de canal (icone colorido) para a lista e o cabecalho.
class CanalBadge extends StatelessWidget {
  const CanalBadge(this.canalEfetivo, {super.key, this.size = 16, this.comLabel = false});

  final String canalEfetivo;
  final double size;
  final bool comLabel;

  @override
  Widget build(BuildContext context) {
    final v = canalVisual(canalEfetivo);
    if (comLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: v.cor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(v.icone, size: size, color: v.cor),
            const SizedBox(width: 4),
            Text(
              v.label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: v.cor),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: v.cor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(v.icone, size: size, color: Colors.white),
    );
  }
}
