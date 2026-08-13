import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

/// Permissoes do GabiFlow, no formato `modulo:acao`.
///
/// Sao as MESMAS chaves do painel (lib/permissions.ts) e as mesmas que a API
/// mobile exige em cada rota. Constantes em vez de texto solto porque um erro
/// de digitacao aqui esconderia um botao sem ninguem perceber.
abstract final class Permissoes {
  // Agenda
  static const agendaVer = 'schedule:view';
  static const agendaCriar = 'schedule:create';
  static const agendaEditar = 'schedule:edit';
  static const agendaExcluir = 'schedule:delete';

  // Demandas
  static const demandasListar = 'demands:list';
  static const demandasCriar = 'demands:create';
  static const demandasEditar = 'demands:edit';
  static const demandasExcluir = 'demands:delete';

  // Eleitores (people no painel)
  static const eleitoresListar = 'people:list';
  static const eleitoresCriar = 'people:create';
  static const eleitoresEditar = 'people:edit';
  static const eleitoresExcluir = 'people:delete';

  // Interacoes com o eleitor
  static const interacoesVer = 'interactions:view';
  static const interacoesCriar = 'interactions:create';

  // WhatsApp
  static const whatsappCentral = 'whatsapp:central';
  static const whatsappEnvioMassa = 'whatsapp:bulk_send';
  static const whatsappTemplates = 'whatsapp:templates';
  static const whatsappCampanhas = 'whatsapp:campaigns';

  // Dados eleitorais
  static const eleitoralVer = 'dados_eleitorais:view';
  static const eleitoralCandidatos = 'dados_eleitorais:candidates';
  static const eleitoralMapa = 'dados_eleitorais:map';
  static const eleitoralEstatisticas = 'dados_eleitorais:statistics';
  static const eleitoralPartidos = 'dados_eleitorais:parties';
  static const eleitoralColigacoes = 'dados_eleitorais:coalitions';
  static const eleitoralAnalise = 'dados_eleitorais:analysis';

  // Inteligencia artificial
  static const iaVer = 'ia:view';

  // Painel
  static const dashboard = 'dashboard:access';
}

/// Permissoes efetivas do usuario logado.
///
/// Vem do login e sao renovadas pelo /auth/me. Lista vazia enquanto ninguem
/// esta autenticado — e' o padrao seguro: sem permissao, nada aparece.
final permissoesProvider = Provider<List<String>>((ref) {
  return ref.watch(authProvider).user?.permissions ?? const <String>[];
});

/// True quando o usuario tem a permissao.
///
/// Esconder na tela e' conveniencia, nao protecao: quem barra de verdade e' o
/// servidor, em `app/api/mobile/_lib/permissoes.ts`. As duas camadas leem a
/// mesma lista, entao nao divergem.
final temPermissaoProvider = Provider.family<bool, String>((ref, permissao) {
  final minhas = ref.watch(permissoesProvider);
  return minhas.contains('*') || minhas.contains(permissao);
});

/// True quando tem ao menos uma das permissoes — util para uma tela que abre
/// com qualquer um de varios acessos.
final temAlgumaPermissaoProvider =
    Provider.family<bool, List<String>>((ref, permissoes) {
  final minhas = ref.watch(permissoesProvider);
  if (minhas.contains('*')) return true;
  return permissoes.any(minhas.contains);
});

/// Mostra o filho apenas quando a pessoa tem a permissao.
///
/// ```dart
/// SePodeVer(
///   permissao: Permissoes.agendaCriar,
///   child: FloatingActionButton(...),
/// )
/// ```
class SePodeVer extends ConsumerWidget {
  const SePodeVer({
    super.key,
    required this.permissao,
    required this.child,
    this.substituto,
  });

  final String permissao;
  final Widget child;

  /// Exibido quando falta permissao. Nulo esconde por completo — preferivel a
  /// mostrar um botao desabilitado, que so' gera duvida sobre o que fazer.
  final Widget? substituto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pode = ref.watch(temPermissaoProvider(permissao));
    if (pode) return child;
    return substituto ?? const SizedBox.shrink();
  }
}

/// Tela inteira barrada por falta de permissao.
///
/// Usada quando a pessoa chega por link ou por um item de menu que ficou
/// visivel: melhor explicar do que mostrar uma lista vazia, que parece defeito.
class SemPermissao extends StatelessWidget {
  const SemPermissao({super.key, this.titulo = 'Acesso restrito'});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 48, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'Você não tem acesso a esta área',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Fale com o administrador do gabinete se precisar deste acesso.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
