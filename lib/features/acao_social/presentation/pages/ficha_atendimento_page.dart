import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../core/auth/permissoes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/acao_social_models.dart';
import '../providers/acao_social_providers.dart';
import '../widgets/acao_social_widgets.dart';
import '../widgets/atendimento_acoes.dart';

/// Ficha de anamnese do paciente no evento: sinais vitais, condicoes de
/// saude, observacoes, local e LGPD. A ficha e' do PACIENTE: ao salvar, o
/// mesmo conteudo vai para todos os atendimentos nao cancelados dele
/// (comportamento do painel).
class FichaAtendimentoPage extends ConsumerStatefulWidget {
  const FichaAtendimentoPage({
    super.key,
    required this.eventoId,
    required this.eleitorId,
  });

  final String eventoId;
  final int eleitorId;

  @override
  ConsumerState<FichaAtendimentoPage> createState() =>
      _FichaAtendimentoPageState();
}

class _FichaAtendimentoPageState extends ConsumerState<FichaAtendimentoPage> {
  final _pa = TextEditingController();
  final _fc = TextEditingController();
  final _hgt = TextEditingController();
  final _peso = TextEditingController();
  final _altura = TextEditingController();
  final _cirurgias = TextEditingController();
  final _observacoes = TextEditingController();
  final _local = TextEditingController();

  final _condicoes = <String, bool>{
    'diabetes': false,
    'hipertensao_arterial': false,
    'tabagismo': false,
    'varizes': false,
    'epilepsia': false,
    'hipotensao_arterial': false,
    'proteses_dentaria': false,
    'lesoes': false,
  };
  static const _rotulosCondicoes = <String, String>{
    'diabetes': 'Diabetes',
    'hipertensao_arterial': 'Hipertensão arterial',
    'tabagismo': 'Tabagismo',
    'varizes': 'Varizes',
    'epilepsia': 'Epilepsia',
    'hipotensao_arterial': 'Hipotensão arterial',
    'proteses_dentaria': 'Próteses dentárias',
    'lesoes': 'Lesões',
  };

  bool _lgpd = false;
  bool _inicializado = false;

  PacienteKey get _key => (eventoId: widget.eventoId, eleitorId: widget.eleitorId);

  @override
  void dispose() {
    for (final c in [
      _pa, _fc, _hgt, _peso, _altura, _cirurgias, _observacoes, _local,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Preenche uma unica vez a partir do primeiro atendimento nao cancelado
  /// (todos carregam a mesma anamnese).
  void _inicializar(List<Atendimento> lista) {
    if (_inicializado) return;
    _inicializado = true;
    final base = lista.where((a) => !a.cancelado).firstOrNull ??
        lista.firstOrNull;
    if (base == null) return;
    _pa.text = base.pressaoArterial ?? '';
    _fc.text = base.frequenciaCardiaca ?? '';
    _hgt.text = base.hgt ?? '';
    _peso.text = base.peso ?? '';
    _altura.text = base.altura ?? '';
    _cirurgias.text = base.cirurgias ?? '';
    _observacoes.text = base.observacoes ?? '';
    _condicoes['diabetes'] = base.diabetes;
    _condicoes['hipertensao_arterial'] = base.hipertensaoArterial;
    _condicoes['tabagismo'] = base.tabagismo;
    _condicoes['varizes'] = base.varizes;
    _condicoes['epilepsia'] = base.epilepsia;
    _condicoes['hipotensao_arterial'] = base.hipotensaoArterial;
    _condicoes['proteses_dentaria'] = base.protesesDentaria;
    _condicoes['lesoes'] = base.lesoes;
    _lgpd = base.lgpdConsentimento;
    _local.text = base.localAtendimento ??
        ref.read(acaoSocialAcoesProvider.notifier).localLembrado ??
        '';
  }

  Map<String, dynamic> _montarFicha() => {
        'pressao_arterial': _pa.text.trim(),
        'frequencia_cardiaca': _fc.text.trim(),
        'hgt': _hgt.text.trim(),
        'peso': _peso.text.trim(),
        'altura': _altura.text.trim(),
        ..._condicoes,
        'cirurgias': _cirurgias.text.trim(),
        'observacoes': _observacoes.text.trim(),
        'lgpd_consentimento': _lgpd,
        'local_atendimento': _local.text.trim(),
      };

  Future<void> _salvar(List<Atendimento> lista, {required bool concluir}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (concluir && !_lgpd) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Consentimento LGPD'),
          content: const Text(
              'O paciente não marcou o consentimento LGPD. Concluir mesmo assim?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Voltar')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Concluir')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    HapticFeedback.mediumImpact();
    final sucesso = await ref.read(acaoSocialAcoesProvider.notifier).salvarFicha(
          eventoId: widget.eventoId,
          eleitorId: widget.eleitorId,
          atendimentos: lista,
          ficha: _montarFicha(),
          concluir: concluir,
        );
    if (!mounted) return;
    if (!sucesso) {
      final erro = ref.read(acaoSocialAcoesProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(erro ?? 'Não foi possível salvar a ficha.'),
        backgroundColor: AppColors.dangerLight,
      ));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(concluir ? 'Atendimento concluído.' : 'Ficha salva.'),
      backgroundColor: AppColors.successLight,
    ));
    if (concluir) context.pop();
  }

  /// Imprimir ou compartilhar a ficha em PDF (gerado pelo servidor: uma
  /// ficha do paciente com todas as especialidades, 2 vias por pagina).
  /// [compartilhar] = false abre o dialogo nativo de impressao (que no
  /// Android tambem oferece "Salvar como PDF").
  Future<void> _fichaPdf(List<Atendimento> lista,
      {required bool compartilhar}) async {
    final base = lista.where((a) => !a.cancelado).firstOrNull ?? lista.first;
    final bytes =
        await ref.read(acaoSocialAcoesProvider.notifier).baixarFichaPdf(base.id);
    if (!mounted) return;
    if (bytes == null) {
      final erro = ref.read(acaoSocialAcoesProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(erro ?? 'Não foi possível gerar o PDF.'),
        backgroundColor: AppColors.dangerLight,
      ));
      return;
    }
    final nome = (base.pacienteNome ?? 'paciente')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final arquivo = 'ficha-$nome.pdf';
    final dados = Uint8List.fromList(bytes);
    try {
      if (compartilhar) {
        await Printing.sharePdf(bytes: dados, filename: arquivo);
      } else {
        await Printing.layoutPdf(
          onLayout: (_) async => dados,
          name: arquivo,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Não foi possível abrir o PDF: ${mensagemErroAcaoSocial(e)}'),
        backgroundColor: AppColors.dangerLight,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(atendimentosPacienteProvider(_key));
    final acoes = ref.watch(acaoSocialAcoesProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final lista = async.valueOrNull ?? const <Atendimento>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha de atendimento'),
        actions: [
          if (lista.isNotEmpty)
            SePodeVer(
              permissao: Permissoes.acaoSocialAtender,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Imprimir ficha',
                    onPressed: acoes.isLoading
                        ? null
                        : () => _fichaPdf(lista, compartilhar: false),
                    icon: const Icon(Icons.print_rounded),
                  ),
                  IconButton(
                    tooltip: 'Compartilhar PDF',
                    onPressed: acoes.isLoading
                        ? null
                        : () => _fichaPdf(lista, compartilhar: true),
                    icon: const Icon(Icons.share_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppEmptyState(
          title: 'Não foi possível carregar a ficha',
          subtitle: mensagemErroAcaoSocial(e),
          actionLabel: 'Tentar novamente',
          onAction: () => ref.invalidate(atendimentosPacienteProvider(_key)),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return const AppEmptyState(
              title: 'Sem atendimentos',
              subtitle: 'Este paciente não tem atendimento neste evento.',
            );
          }
          _inicializar(lista);
          final ativos = lista.where((a) => !a.cancelado).toList();
          final pendentes = ativos.where((a) => a.emAtendimento).length;
          final nome = lista.first.pacienteNome ?? 'Paciente';
          final somenteLeitura = ativos.isEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
            children: [
              // Paciente
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                corAcaoSocial.withValues(alpha: 0.12),
                            foregroundColor: corAcaoSocial,
                            child: Text(iniciais(nome),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nome, style: tt.titleMedium),
                                if (lista.first.pacienteTelefone != null)
                                  Text(
                                    formatarTelefone(
                                        lista.first.pacienteTelefone),
                                    style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final a in lista)
                            EspecialidadeChip(
                              atendimento: a,
                              onTap: () => editarAtendimento(context, ref, a),
                            ),
                        ],
                      ),
                      if (lista.first.atendenteNome != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Atendente: ${lista.first.atendenteNome} · ${formatarDataHora(lista.first.dataAtendimento)}',
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sinais vitais
              Text('Sinais vitais', style: tt.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(child: _campo(_pa, 'Pressão arterial', '120/80')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _campo(_fc, 'Freq. cardíaca', 'bpm', numerico: true)),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(child: _campo(_hgt, 'HGT', 'mg/dL', numerico: true)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _campo(_peso, 'Peso', 'kg', numerico: true)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _campo(_altura, 'Altura', 'cm', numerico: true)),
              ]),
              const SizedBox(height: AppSpacing.lg),

              // Condicoes de saude
              Text('Condições de saúde', style: tt.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final e in _rotulosCondicoes.entries)
                      CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(e.value),
                        value: _condicoes[e.key] ?? false,
                        onChanged: somenteLeitura
                            ? null
                            : (v) => setState(
                                () => _condicoes[e.key] = v ?? false),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _cirurgias,
                maxLines: 2,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Cirurgias realizadas',
                  alignLabelWithHint: true,
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Observacoes e local
              Text('Atendimento', style: tt.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _observacoes,
                maxLines: 4,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  alignLabelWithHint: true,
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _local,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Local do atendimento',
                  hintText: 'Ex.: Escola Municipal, Praça Central',
                  prefixIcon: Icon(Icons.place_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                margin: EdgeInsets.zero,
                child: SwitchListTile(
                  title: const Text('Consentimento LGPD'),
                  subtitle: const Text(
                      'O paciente autoriza o uso dos dados de saúde para este atendimento.'),
                  value: _lgpd,
                  onChanged:
                      somenteLeitura ? null : (v) => setState(() => _lgpd = v),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (!somenteLeitura)
                SePodeVer(
                  permissao: Permissoes.acaoSocialAtender,
                  substituto: Text(
                    'Você não tem permissão para editar fichas.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Salvar ficha',
                        icon: Icons.save_rounded,
                        variant: PrimaryButtonVariant.secondary,
                        isLoading: acoes.isLoading,
                        onPressed: () => _salvar(lista, concluir: false),
                      ),
                      if (pendentes > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        PrimaryButton(
                          label: pendentes == 1
                              ? 'Salvar e concluir atendimento'
                              : 'Salvar e concluir $pendentes atendimentos',
                          icon: Icons.task_alt_rounded,
                          isLoading: acoes.isLoading,
                          onPressed: () => _salvar(lista, concluir: true),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, String hint,
      {bool numerico = false}) {
    return TextFormField(
      controller: c,
      keyboardType: numerico
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLength: 20,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
      ),
    );
  }
}
