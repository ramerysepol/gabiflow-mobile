import 'package:go_router/go_router.dart';

import '../../features/agenda/presentation/pages/agenda_page.dart';
import '../../features/agenda/presentation/pages/event_detail_page.dart';
import '../../features/agenda/presentation/pages/event_form_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/constituents/presentation/pages/constituent_detail_page.dart';
import '../../features/constituents/presentation/pages/constituent_form_page.dart';
import '../../features/constituents/presentation/pages/constituents_list_page.dart';
import '../../features/demands/presentation/pages/demand_detail_page.dart';
import '../../features/demands/presentation/pages/demand_form_page.dart';
import '../../features/demands/presentation/pages/demands_list_page.dart';
import '../../features/home/presentation/pages/dashboard_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/tenant/presentation/pages/tenant_setup_page.dart';
import '../../features/whatsapp/presentation/pages/envio_massa_progress_page.dart';
import '../../features/command_center/presentation/pages/command_center_page.dart';
import '../../features/command_center/presentation/pages/ia_chat_page.dart';
import '../../features/electoral_data/presentation/pages/analise_page.dart';
import '../../features/electoral_data/presentation/pages/candidato_comparar_page.dart';
import '../../features/electoral_data/presentation/pages/candidato_detail_page.dart';
import '../../features/electoral_data/presentation/pages/eleitoral_home_page.dart';
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
///     /home/agenda       → AgendaPage
///     /home/agenda/new   → EventFormPage
///     /home/agenda/:id   → EventDetailPage
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
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashPage(),
    ),
    GoRoute(
      path: '/tenant-setup',
      builder: (_, __) => const TenantSetupPage(),
    ),
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
        GoRoute(
          path: '/home',
          builder: (_, __) => const DashboardPage(),
        ),

        // ── Munícipes ──────────────────────────────────────────────────────
        GoRoute(
          path: '/home/constituents',
          builder: (_, __) => const ConstituentsListPage(),
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
          builder: (_, __) => const DemandsListPage(),
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

        // ── Agenda ─────────────────────────────────────────────────────────
        GoRoute(
          path: '/home/agenda',
          builder: (_, __) => const AgendaPage(),
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

        // ── Dados Eleitorais ──────────────────────────────────────────────
        GoRoute(
          path: '/home/eleitoral',
          builder: (_, __) => const EleitoralHomePage(),
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
          path: '/home/eleitoral/rankings',
          builder: (_, __) => const RankingsPage(),
        ),
        GoRoute(
          path: '/home/eleitoral/analise',
          builder: (_, __) => const AnalisePage(),
        ),
        GoRoute(
          path: '/home/eleitoral/ia',
          builder: (_, __) => const CommandCenterPage(),
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
