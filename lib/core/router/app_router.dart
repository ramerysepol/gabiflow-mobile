import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/acao_social/presentation/pages/acao_social_evento_page.dart';
import '../../features/acao_social/presentation/pages/acao_social_eventos_page.dart';
import '../../features/acao_social/presentation/pages/cadastro_municipe_page.dart';
import '../../features/acao_social/presentation/pages/ficha_atendimento_page.dart';
import '../../features/agenda/presentation/pages/agenda_page.dart';
import '../../features/agenda/presentation/pages/event_detail_page.dart';
import '../../features/agenda/presentation/pages/event_form_page.dart';
import '../../features/apuracao/presentation/pages/apuracao_page.dart';
import '../../features/apuracao/presentation/pages/apuracao_tv_page.dart';
import '../../features/apuracao/presentation/pages/candidato_apuracao_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/constituents/presentation/pages/constituent_detail_page.dart';
import '../../features/constituents/presentation/pages/constituent_form_page.dart';
import '../../features/constituents/presentation/pages/constituents_list_page.dart';
import '../../features/demands/presentation/pages/demand_detail_page.dart';
import '../../features/demands/presentation/pages/demand_form_page.dart';
import '../../features/demands/presentation/pages/demands_list_page.dart';
import '../../features/home/presentation/pages/dashboard_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/tenant/presentation/pages/tenant_setup_page.dart';
import '../../features/whatsapp/presentation/pages/central_chat_page.dart';
import '../../features/whatsapp/presentation/pages/central_page.dart';
import '../../features/whatsapp/presentation/pages/envio_massa_progress_page.dart';
import '../../features/command_center/presentation/pages/command_center_page.dart';
import '../../features/command_center/presentation/pages/ia_chat_page.dart';
import '../../features/command_center/presentation/pages/transferencia_page.dart';
import '../../features/electoral_data/presentation/pages/analise_page.dart';
import '../../features/electoral_data/presentation/comparativo_args.dart';
import '../../features/electoral_data/presentation/pages/bairros_comparativo_page.dart';
import '../../features/electoral_data/presentation/pages/candidato_comparar_page.dart';
import '../../features/electoral_data/presentation/pages/secoes_comparativo_page.dart';
import '../../features/electoral_data/presentation/pages/candidato_detail_page.dart';
import '../../features/electoral_data/presentation/pages/eleitoral_home_page.dart';
import '../../features/electoral_data/presentation/pages/eleitoral_mapa_page.dart';
import '../../features/electoral_data/presentation/pages/eleitoral_shell.dart';
import '../../features/electoral_data/presentation/pages/eleitoral_visao_page.dart';
import '../../features/electoral_data/presentation/pages/rankings_page.dart';
import '../../features/electoral_data/presentation/pages/seletor_eleicao_page.dart';
import '../../features/electoral_data/presentation/pages/simulador_page.dart';

/// Centraliza toda a navegação do app usando go_router.
///
/// Rotas:
///   /                → SplashPage
///   /tenant-setup    → TenantSetupPage
///   /login/:subdomain → LoginPage
///   /home            → HomeShell (ShellRoute)
///     /home              → DashboardPage
///     /home/constituents → ConstituentsListPage
///     /home/constituents/new → ConstituentFormPage (criar)
///     /home/constituents/:id → ConstituentDetailPage
///     /home/constituents/:id/edit → ConstituentFormPage (editar)
///     /home/demands      → DemandsListPage
///     /home/demands/new  → DemandFormPage
///     /home/demands/:id  → DemandDetailPage
///     /home/acao-social                          → AcaoSocialEventosPage
///     /home/acao-social/evento/:id               → AcaoSocialEventoPage (central)
///     /home/acao-social/evento/:id/cadastro      → CadastroMunicipePage
///     /home/acao-social/evento/:id/ficha/:eleitorId → FichaAtendimentoPage
///     /home/agenda       → AgendaPage
///     /home/agenda/new   → EventFormPage
///     /home/agenda/:id   → EventDetailPage
///     /home/apuracao                     → ApuracaoPage (header + dock da Home)
///     /home/apuracao/candidato/:sqcand    → CandidatoApuracaoPage
///     /home/apuracao/tv?cargo=           → ApuracaoTvPage (Modo TV, tela cheia)
///     /home/eleitoral              → EleitoralHomePage (condicional)
///     /home/eleitoral/selecionar   → SeletorEleicaoPage
///     /home/eleitoral/candidato/:sequencial → CandidatoDetailPage
///     /home/eleitoral/comparar     → CompararPage
///     /home/eleitoral/rankings     → RankingsPage
///     /home/eleitoral/ia           → CommandCenterPage (IA)
///     /home/eleitoral/ia/chat      → IaChatPage (?q= pergunta inicial)
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/tenant-setup', builder: (_, __) => const TenantSetupPage()),
    GoRoute(
      path: '/login/:subdomain',
      builder: (_, state) {
        final subdomain = state.pathParameters['subdomain'] ?? '';
        return LoginPage(tenantSubdomain: subdomain);
      },
    ),
    ShellRoute(
      builder: (context, state, child) => HomePage(child: child),
      routes: [
        // Abas do dock trocam SEM transicao (padrao WhatsApp/Instagram):
        // a animacao do Material desenhava a aba nova por cima da antiga
        // enquanto a lista pesada construia — lida como sobreposicao lenta.
        GoRoute(
          path: '/home',
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: const DashboardPage(),
          ),
        ),

        // ── Atendimento (Central WhatsApp) ─────────────────────────────────
        GoRoute(
          path: '/home/atendimento',
          pageBuilder: (_, state) =>
              NoTransitionPage(key: state.pageKey, child: const CentralPage()),
        ),
        GoRoute(
          path: '/home/atendimento/chat/:id',
          // Fade rapido (estilo WhatsApp) em vez do slide iOS padrao:
          // abrir conversa precisa parecer instantaneo.
          pageBuilder: (_, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            // iOS: página Cupertino padrão — slide nativo + gesto de voltar
            // arrastando da borda (a transição custom não suporta o gesto).
            if (Platform.isIOS) {
              return CupertinoPage<void>(
                key: state.pageKey,
                child: CentralChatPage(
                  conversationId: id,
                  nomeContato: state.uri.queryParameters['nome'],
                  telefone: state.uri.queryParameters['tel'],
                  fotoUrl: state.uri.queryParameters['foto'],
                  canal: state.uri.queryParameters['canal'],
                  contaCanal: state.uri.queryParameters['conta'],
                ),
              );
            }
            // Android: slide opaco curto. Fade nao-opaco deixava a lista
            // visivel por tras (sobreposicao); o Zoom padrao do Material e'
            // mais caro e parecia lento. O slide cobre a lista de uma vez.
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: const Duration(milliseconds: 200),
              reverseTransitionDuration: const Duration(milliseconds: 180),
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                );
              },
              child: CentralChatPage(
                conversationId: id,
                nomeContato: state.uri.queryParameters['nome'],
                telefone: state.uri.queryParameters['tel'],
                fotoUrl: state.uri.queryParameters['foto'],
                canal: state.uri.queryParameters['canal'],
                contaCanal: state.uri.queryParameters['conta'],
              ),
            );
          },
        ),

        // ── Perfil do usuário ──────────────────────────────────────────────
        GoRoute(path: '/home/perfil', builder: (_, __) => const ProfilePage()),

        // ── Munícipes ──────────────────────────────────────────────────────
        GoRoute(
          path: '/home/constituents',
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ConstituentsListPage(),
          ),
        ),
        GoRoute(
          path: '/home/constituents/new',
          builder: (_, __) => const ConstituentFormPage(),
        ),
        GoRoute(
          path: '/home/constituents/:id',
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return ConstituentDetailPage(id: id);
          },
        ),
        GoRoute(
          path: '/home/constituents/:id/edit',
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return ConstituentFormPage(constituentId: id);
          },
        ),
        GoRoute(
          path: '/home/constituents/envio/:campaignId',
          builder: (_, state) {
            final id =
                int.tryParse(state.pathParameters['campaignId'] ?? '') ?? 0;
            return EnvioMassaProgressPage(campaignId: id);
          },
        ),

        // ── Demandas ───────────────────────────────────────────────────────
        GoRoute(
          path: '/home/demands',
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: const DemandsListPage(),
          ),
        ),
        GoRoute(
          path: '/home/demands/new',
          builder: (_, state) {
            // Suporta query param ?id= para editar a partir do detalhe
            final id = state.uri.queryParameters['id'];
            return DemandFormPage(demandId: id);
          },
        ),
        GoRoute(
          path: '/home/demands/:id',
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return DemandDetailPage(id: id);
          },
        ),

        // ── Ação Social (expresso-saude no backend) ────────────────────────
        // Sub-páginas (fora do dock): cada uma tem o próprio AppBar.
        GoRoute(
          path: '/home/acao-social',
          builder: (_, __) => const AcaoSocialEventosPage(),
        ),
        GoRoute(
          path: '/home/acao-social/evento/:id',
          builder: (_, state) =>
              AcaoSocialEventoPage(eventoId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/home/acao-social/evento/:id/cadastro',
          builder: (_, state) =>
              CadastroMunicipePage(eventoId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/home/acao-social/evento/:id/ficha/:eleitorId',
          builder: (_, state) => FichaAtendimentoPage(
            eventoId: state.pathParameters['id']!,
            eleitorId:
                int.tryParse(state.pathParameters['eleitorId'] ?? '') ?? 0,
          ),
        ),

        // ── Agenda ─────────────────────────────────────────────────────────
        GoRoute(
          path: '/home/agenda',
          pageBuilder: (_, state) =>
              NoTransitionPage(key: state.pageKey, child: const AgendaPage()),
        ),
        GoRoute(
          path: '/home/agenda/new',
          builder: (_, state) {
            final id = state.uri.queryParameters['id'];
            return EventFormPage(eventId: id);
          },
        ),
        GoRoute(
          path: '/home/agenda/:id',
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return EventDetailPage(id: id);
          },
        ),

        // ── Apuração ao vivo (resultados oficiais do TSE) ───────────────────
        // Página principal fica dentro do shell normal da Home (header +
        // dock, com "Início" selecionado — ver HomePage); o detalhe do
        // candidato abre em tela cheia, como os demais detalhes do app.
        GoRoute(
          path: '/home/apuracao',
          pageBuilder: (_, state) =>
              NoTransitionPage(key: state.pageKey, child: const ApuracaoPage()),
        ),
        GoRoute(
          path: '/home/apuracao/candidato/:sqcand',
          builder: (_, state) {
            final sqcand = state.pathParameters['sqcand']!;
            return CandidatoApuracaoPage(sqcand: sqcand);
          },
        ),
        // Modo TV ("sala de guerra"): tela cheia, sem dock — ver HomePage
        // (rootIndex < 0 pra qualquer rota fora da lista de abas).
        GoRoute(
          path: '/home/apuracao/tv',
          builder: (_, state) {
            final cargo =
                int.tryParse(state.uri.queryParameters['cargo'] ?? '') ?? 1;
            return ApuracaoTvPage(cargo: cargo);
          },
        ),

        // ── Dados Eleitorais (sub-app com barra própria) ──────────────────
        // As 5 abas vivem dentro do EleitoralShell; o resto abre em tela
        // cheia por cima (detalhe, comparar, seletor...).
        ShellRoute(
          builder: (context, state, child) => EleitoralShell(child: child),
          routes: [
            GoRoute(
              path: '/home/eleitoral',
              pageBuilder: (_, state) => NoTransitionPage(
                key: state.pageKey,
                child: const EleitoralVisaoPage(),
              ),
            ),
            GoRoute(
              path: '/home/eleitoral/mapa',
              pageBuilder: (_, state) => NoTransitionPage(
                key: state.pageKey,
                child: const EleitoralMapaPage(),
              ),
            ),
            GoRoute(
              path: '/home/eleitoral/candidatos',
              pageBuilder: (_, state) => NoTransitionPage(
                key: state.pageKey,
                child: const EleitoralHomePage(),
              ),
            ),
            GoRoute(
              path: '/home/eleitoral/rankings',
              pageBuilder: (_, state) => NoTransitionPage(
                key: state.pageKey,
                child: const RankingsPage(),
              ),
            ),
            GoRoute(
              path: '/home/eleitoral/ia',
              pageBuilder: (_, state) => NoTransitionPage(
                key: state.pageKey,
                child: const CommandCenterPage(),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/home/eleitoral/selecionar',
          builder: (_, __) => const SeletorEleicaoPage(),
        ),
        GoRoute(
          path: '/home/eleitoral/comparar',
          builder: (_, __) => const CompararPage(),
        ),
        GoRoute(
          path: '/home/eleitoral/comparar/bairros',
          builder: (_, state) =>
              BairrosComparativoPage(args: state.extra! as ComparativoArgs),
        ),
        GoRoute(
          path: '/home/eleitoral/comparar/bairros/secoes',
          builder: (_, state) =>
              SecoesComparativoPage(args: state.extra! as ComparativoArgs),
        ),
        GoRoute(
          path: '/home/eleitoral/analise',
          builder: (_, __) => const AnalisePage(),
        ),
        GoRoute(
          path: '/home/eleitoral/ia/transferencia',
          builder: (_, __) => const TransferenciaPage(),
        ),
        GoRoute(
          path: '/home/eleitoral/ia/chat',
          builder: (_, state) {
            final q = state.uri.queryParameters['q'];
            return IaChatPage(initialQuestion: q);
          },
        ),
        GoRoute(
          path: '/home/eleitoral/candidato/:sequencial',
          builder: (_, state) {
            final seq = state.pathParameters['sequencial']!;
            return CandidatoDetailPage(sequencial: seq);
          },
        ),
        GoRoute(
          path: '/home/eleitoral/candidato/:sequencial/simulador',
          builder: (_, state) {
            final seq = state.pathParameters['sequencial']!;
            final nome = state.uri.queryParameters['nome'];
            return SimuladorPage(sequencial: seq, nomeCandidato: nome);
          },
        ),
      ],
    ),
  ],
);
