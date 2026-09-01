import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/filtros_model.dart';
import '../../data/models/selected_election_model.dart';
import '../providers/eleitoral_providers.dart';

// ─── Mapeamento: quais cargos fazem sentido por tipo de eleição ───────────────

const _cargosMunicipais = ['Prefeito', 'Vereador'];
const _cargosFederaisEstaduais = [
  'Deputado Estadual',
  'Deputado Federal',
  'Senador',
  'Governador',
  'Presidente',
];

// Anos tipicamente municipais
const _anosMunicipais = {2020, 2024, 2016, 2012};

/// Normaliza cargo: lowercase + espaços e underscores tratados como equivalentes.
String _normalizarCargo(String c) => c.toLowerCase().replaceAll('_', ' ').trim();

List<String> _cargosParaAno(int ano, List<String> todos) {
  final isMunicipal = _anosMunicipais.contains(ano);
  final filtro = isMunicipal ? _cargosMunicipais : _cargosFederaisEstaduais;
  // Match substring tolerante a underscore vs espaço (backend envia 'deputado_federal').
  final filtroNorm = filtro.map(_normalizarCargo).toList();
  final filtrados = todos
      .where((c) {
        final n = _normalizarCargo(c);
        return filtroNorm.any((f) => n.contains(f));
      })
      .toList();
  return filtrados.isEmpty ? todos : filtrados;
}

// ─── Página ───────────────────────────────────────────────────────────────────

class SeletorEleicaoPage extends ConsumerStatefulWidget {
  const SeletorEleicaoPage({super.key});

  @override
  ConsumerState<SeletorEleicaoPage> createState() => _SeletorEleicaoPageState();
}

class _SeletorEleicaoPageState extends ConsumerState<SeletorEleicaoPage>
    with SingleTickerProviderStateMixin {
  int? _anoSel;
  String? _cargoSel;
  String? _ufSel;

  late AnimationController _animCtrl;
  final List<Animation<double>> _fadeAnims = [];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // 5 grupos de elementos com stagger
    for (var i = 0; i < 5; i++) {
      final start = i * 0.12;
      final end = (start + 0.4).clamp(0.0, 1.0);
      _fadeAnims.add(
        CurvedAnimation(
          parent: _animCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    }
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  bool get _podeConfirmar =>
      _anoSel != null && _cargoSel != null && _ufSel != null;

  Future<void> _confirmar() async {
    if (!_podeConfirmar) return;
    final election = SelectedElection(
      ano: _anoSel!,
      cargo: _cargoSel!,
      uf: _ufSel!,
    );
    await ref.read(selectedElectionProvider.notifier).select(election);
    // Força o candidatosListProvider a recarregar com nova eleição
    ref.read(candidatosListProvider.notifier).refresh();
    if (mounted) context.go('/home/eleitoral');
  }

  @override
  Widget build(BuildContext context) {
    final filtrosAsync = ref.watch(filtrosProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      // Sem isso a pessoa ficava presa: sem escolher ano+cargo+UF nao havia
      // como sair da tela (motivo de reprovacao na revisao da Play).
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: filtrosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(error: e.toString()),
          data: (filtros) => _buildContent(context, cs, tt, filtros),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    FiltrosModel filtros,
  ) {
    final cargosDisponiveis = _anoSel != null
        ? _cargosParaAno(_anoSel!, filtros.cargos)
        : filtros.cargos;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // ── Hero ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _FadeScaleIn(
                  animation: _fadeAnims[0],
                  child: _HeroSeletor(cs: cs, tt: tt),
                ),
              ),

              // ── Anos ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _FadeScaleIn(
                  animation: _fadeAnims[1],
                  child: _SecaoAnos(
                    anos: filtros.anos,
                    selecionado: _anoSel,
                    onSelecionar: (ano) {
                      setState(() {
                        _anoSel = ano;
                        // Limpa cargo se não estiver disponível para o novo ano
                        final novos = _cargosParaAno(ano, filtros.cargos);
                        if (_cargoSel != null && !novos.contains(_cargoSel)) {
                          _cargoSel = null;
                        }
                      });
                    },
                  ),
                ),
              ),

              // ── Cargo ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _FadeScaleIn(
                  animation: _fadeAnims[2],
                  child: _SecaoCargos(
                    cargos: cargosDisponiveis,
                    selecionado: _cargoSel,
                    habilitado: _anoSel != null,
                    onSelecionar: (c) => setState(() => _cargoSel = c),
                  ),
                ),
              ),

              // ── Estado ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _FadeScaleIn(
                  animation: _fadeAnims[3],
                  child: _SecaoEstado(
                    ufs: filtros.ufs,
                    selecionado: _ufSel,
                    habilitado: _cargoSel != null,
                    onSelecionar: (uf) => setState(() => _ufSel = uf),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),

        // ── Botão fixo no fundo ──────────────────────────────────────────
        _FadeScaleIn(
          animation: _fadeAnims[4],
          child: _BotaoContinuar(
            habilitado: _podeConfirmar,
            onTap: _confirmar,
          ),
        ),
      ],
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HeroSeletor extends StatelessWidget {
  const _HeroSeletor({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.how_to_vote_rounded,
              size: 40,
              color: cs.onPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Selecione a Eleição',
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha o ano, cargo e estado\npara começar a análise',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Seção: Anos ─────────────────────────────────────────────────────────────

class _SecaoAnos extends StatelessWidget {
  const _SecaoAnos({
    required this.anos,
    required this.selecionado,
    required this.onSelecionar,
  });

  final List<int> anos;
  final int? selecionado;
  final ValueChanged<int> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // Garante pelo menos os anos padrão se API retornar vazio
    final listaAnos = anos.isEmpty ? [2018, 2020, 2022, 2024] : anos;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecaoTitulo(
              titulo: 'Ano eleitoral', icone: Icons.calendar_today_rounded),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: listaAnos.length,
            itemBuilder: (_, i) {
              final ano = listaAnos[i];
              final selecionadoItem = ano == selecionado;
              return _AnoCard(
                ano: ano,
                selecionado: selecionadoItem,
                onTap: () => onSelecionar(ano),
                cs: cs,
                tt: tt,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AnoCard extends StatelessWidget {
  const _AnoCard({
    required this.ano,
    required this.selecionado,
    required this.onTap,
    required this.cs,
    required this.tt,
  });

  final int ano;
  final bool selecionado;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selecionado ? cs.primary : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selecionado ? cs.primary : cs.outlineVariant,
                width: selecionado ? 2 : 1,
              ),
              boxShadow: selecionado
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                '$ano',
                style: tt.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selecionado ? cs.onPrimary : cs.onSurface,
                  fontSize: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Seção: Cargo ─────────────────────────────────────────────────────────────

class _SecaoCargos extends StatelessWidget {
  const _SecaoCargos({
    required this.cargos,
    required this.selecionado,
    required this.habilitado,
    required this.onSelecionar,
  });

  final List<String> cargos;
  final String? selecionado;
  final bool habilitado;
  final ValueChanged<String> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecaoTitulo(
            titulo: 'Cargo',
            icone: Icons.badge_outlined,
            desabilitado: !habilitado,
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: habilitado ? 1.0 : 0.4,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cargos.map((cargo) {
                final sel = cargo == selecionado;
                return _CargoChip(
                  cargo: cargo,
                  selecionado: sel,
                  habilitado: habilitado,
                  onTap: habilitado ? () => onSelecionar(cargo) : null,
                  cs: cs,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CargoChip extends StatelessWidget {
  const _CargoChip({
    required this.cargo,
    required this.selecionado,
    required this.habilitado,
    required this.onTap,
    required this.cs,
  });

  final String cargo;
  final bool selecionado;
  final bool habilitado;
  final VoidCallback? onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? cs.primary : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selecionado ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Text(
          cargo,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selecionado ? cs.onPrimary : cs.onSurface,
                fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

// ─── Seção: Estado ────────────────────────────────────────────────────────────

class _SecaoEstado extends StatelessWidget {
  const _SecaoEstado({
    required this.ufs,
    required this.selecionado,
    required this.habilitado,
    required this.onSelecionar,
  });

  final List<String> ufs;
  final String? selecionado;
  final bool habilitado;
  final ValueChanged<String> onSelecionar;

  static const _ufsDefault = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lista = ufs.isEmpty ? _ufsDefault : ufs;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecaoTitulo(
            titulo: 'Estado',
            icone: Icons.map_outlined,
            desabilitado: !habilitado,
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: habilitado ? 1.0 : 0.4,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lista.map((uf) {
                final sel = uf == selecionado;
                return GestureDetector(
                  onTap: habilitado ? () => onSelecionar(uf) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 48,
                    height: 36,
                    decoration: BoxDecoration(
                      color: sel ? cs.primary : cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel ? cs.primary : cs.outlineVariant,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        uf,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: sel ? cs.onPrimary : cs.onSurface,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Botão Continuar ──────────────────────────────────────────────────────────

class _BotaoContinuar extends StatelessWidget {
  const _BotaoContinuar({required this.habilitado, required this.onTap});

  final bool habilitado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: habilitado ? onTap : null,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Continuar'),
          style: FilledButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SecaoTitulo extends StatelessWidget {
  const _SecaoTitulo({
    required this.titulo,
    required this.icone,
    this.desabilitado = false,
  });

  final String titulo;
  final IconData icone;
  final bool desabilitado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icone, size: 18, color: desabilitado ? cs.outlineVariant : cs.primary),
        const SizedBox(width: 6),
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: desabilitado ? cs.outlineVariant : cs.onSurface,
              ),
        ),
      ],
    );
  }
}

class _FadeScaleIn extends StatelessWidget {
  const _FadeScaleIn({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(
        opacity: animation.value,
        child: Transform.scale(
          scale: 0.92 + (0.08 * animation.value),
          child: child,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro ao carregar filtros', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
