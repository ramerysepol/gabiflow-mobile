import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Perfil do usuário logado — identidade, gabinete e sessão.
/// Sem edição por aqui: dados cadastrais são geridos pelo administrador
/// no painel web; o app mostra e cuida da sessão (sair / trocar gabinete).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tinta =
        isDark ? const Color(0xFF10151F) : const Color(0xFF16213E);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: tinta,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      tinta,
                      Color.lerp(tinta, cs.primary, 0.35)!,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: UserAvatar(
                          avatarData: user?.avatar,
                          userName: user?.name ?? 'Usuário',
                          radius: 42,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'Usuário',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _Secao(titulo: 'CONTA', children: [
                  _Linha(
                    icone: Icons.badge_outlined,
                    rotulo: 'Papel',
                    valor: _papelBonito(user?.role),
                  ),
                  _Linha(
                    icone: Icons.apartment_rounded,
                    rotulo: 'Gabinete',
                    valor: user?.tenant ?? user?.tenantId ?? '—',
                  ),
                  if ((user?.telefone ?? '').isNotEmpty)
                    _Linha(
                      icone: Icons.phone_outlined,
                      rotulo: 'Telefone',
                      valor: user!.telefone!,
                    ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                _Secao(titulo: 'SESSÃO', children: [
                  _Acao(
                    icone: Icons.swap_horiz_rounded,
                    rotulo: 'Trocar de gabinete',
                    descricao: 'Sair e acessar outro gabinete',
                    onTap: () => _trocarGabinete(context),
                  ),
                  _Acao(
                    icone: Icons.logout_rounded,
                    rotulo: 'Sair',
                    descricao: 'Encerrar a sessão neste aparelho',
                    destrutiva: true,
                    onTap: () => _sair(context, ref),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snap) => Text(
                      snap.hasData
                          ? 'GabiFlow ${snap.data!.version} (${snap.data!.buildNumber})'
                          : 'GabiFlow',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _papelBonito(String? role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'assessor':
        return 'Assessor';
      case 'atendente':
        return 'Atendente';
      default:
        return role ?? '—';
    }
  }

  Future<void> _sair(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar saída'),
        content: const Text('Deseja realmente sair do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sair',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/');
    }
  }

  Future<void> _trocarGabinete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trocar de Gabinete'),
        content: const Text(
          'Ao trocar de gabinete, você será desconectado. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await StorageService.clearSecureStorage();
      if (context.mounted) context.go('/tenant-setup');
    }
  }
}

// ── Blocos visuais ──────────────────────────────────────────────────────────

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icone, color: cs.primary),
      title: Text(rotulo,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      subtitle: Text(
        valor,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      dense: true,
    );
  }
}

class _Acao extends StatelessWidget {
  const _Acao({
    required this.icone,
    required this.rotulo,
    required this.descricao,
    required this.onTap,
    this.destrutiva = false,
  });

  final IconData icone;
  final String rotulo;
  final String descricao;
  final VoidCallback onTap;
  final bool destrutiva;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cor = destrutiva ? cs.error : cs.primary;
    return ListTile(
      leading: Icon(icone, color: cor),
      title: Text(
        rotulo,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: destrutiva ? cs.error : cs.onSurface,
        ),
      ),
      subtitle: Text(descricao, style: const TextStyle(fontSize: 12)),
      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
