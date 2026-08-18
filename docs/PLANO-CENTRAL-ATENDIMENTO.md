# Plano: Central de Atendimento WhatsApp no Mobile

> Estudo aprovado em 18/08/2026. Principio inegociavel: o mobile NAO tem logica
> de negocio propria — consome as MESMAS rotas da central web (madura), que
> aceitam `Authorization: Bearer` do login mobile nativamente.

## Descoberta que fundamenta o plano

- `lib/api-auth-middleware.ts` (web) → `extractJWTToken()` aceita Bearer ANTES de cookie.
- O token emitido por `POST /api/mobile/auth/login` e o mesmo JWT (HS256, `JWT_SECRET`,
  payload `{id, role, tenant, type:'access'}`) que as rotas da central validam.
- O `AuthInterceptor` do app ja envia `X-Tenant-ID` + `Origin`/`Referer` (CSRF ok).
- Logo: `/api/whatsapp/conversations/*` funciona pro app SEM backend novo.

## Rotas reutilizadas (todas da central web)

| Uso | Rota |
|---|---|
| Lista de conversas | `GET /api/whatsapp/conversations?status=&search=&limit=&offset=&include_stats=true` |
| Mensagens + marcar lida | `GET /api/whatsapp/conversations/[id]/messages?mark_read=true&limit=&before_id=` |
| Enviar texto/template | `POST /api/whatsapp/conversations/[id]/messages` |
| Enviar midia/audio | `POST /api/whatsapp/conversations/[id]/messages/media` (multipart; servidor transcodifica audio p/ OGG/Opus voz) |
| Midia recebida | `GET /api/whatsapp/media/[id]` (sem JWT; seguro por host/tenant) |
| Assumir/atribuir | `PATCH /api/whatsapp/conversations/[id]` (`assignedTo`) |
| Transferir / encerrar | `POST .../transfer`, `POST .../close` |
| Respostas rapidas / templates | `/api/whatsapp/quick-replies`, `/api/whatsapp/templates?source=meta&active_only=true` |
| Tempo real | `GET /api/whatsapp/sse` (EventSource; heartbeat 15s; eventos new_message, message_status_update, conversation_updated...) + `POST /api/whatsapp/sse/subscribe` |

Regras herdadas de graca (decididas no servidor): janela 24h (`hasWindowRestriction`,
`within_window`, `window_expires_at`), multiprovedor Meta×Z-API (ultima inbound decide),
`channel_account_id` correto na resposta, status ticks (`pending|sent|delivered|read|played|failed`).

## Fases

- **Fase 0 — Spike (feito em 18/08/2026)**: validar Bearer mobile contra
  `GET /api/whatsapp/conversations` num tenant real.
- **Fase 1 — MVP**: aba "Atendimento" (visivel so com permissao `whatsapp:central`):
  lista de conversas (avatar, preview, hora, badge nao lidas, filtro por status) +
  chat (bolhas, ticks, separador de data, banner janela 24h) + enviar texto +
  marcar lida + assumir conversa + respostas rapidas. Polling (lista 10s / chat 5s);
  SSE na iteracao seguinte (padrao ja existe no app: `ia_remote_datasource.dart` faz SSE via Dio).
- **Fase 2 — Midia**: fotos (image_picker ja existe), documentos, gravacao de audio
  (pacotes novos: `record` + `just_audio`) — servidor ja converte p/ voz.
- **Fase 3 — Push FCM** (unica infra backend nova): tabela `mobile_device_tokens` +
  disparo firebase-admin nos mesmos pontos dos emitters SSE
  (`lib/sse/sse-emitters.ts`, webhooks Meta/Z-API). App: `firebase_messaging`,
  tap abre a conversa (deep link).
- **Fase 4 — Gestao leve**: transferir, encerrar com motivo, tags, vinculo municipe.

## Riscos mapeados

- SSE suspenso em background → re-sync no resume + push (fase 3).
- Toolchain: lock resolvido p/ Flutter 3.35; maquina tem 3.47 — primeiro build pode pedir upgrade.
- `media_url` local (`/uploads/...`) precisa ser prefixada com a URL do tenant no app.
- Permissao `whatsapp:central` controla visibilidade da aba (provider `temPermissaoProvider`).

## Referencias de codigo

- Web central: `app/dashboard/whatsapp/central/page.tsx`, `components/whatsapp/{ConversationList,ChatPanel}.tsx`,
  `components/whatsapp/chat/{MessageList,MessageBubble,ChatInput}.tsx`, `hooks/useWhatsAppSSE.ts`
- Rotas: `app/api/whatsapp/conversations/**`, `app/api/whatsapp/sse/**`
- Mobile: `lib/features/whatsapp/` (esqueleto existente), `lib/core/network/{api_client,auth_interceptor}.dart`
