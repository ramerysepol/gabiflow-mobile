import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/acao_social_models.dart';

// ── Formatacao ──────────────────────────────────────────────────────────────

String formatarData(DateTime? d) =>
    d == null ? '—' : DateFormat('dd/MM/yyyy').format(d);

String formatarDataHora(DateTime? d) =>
    d == null ? '—' : DateFormat('dd/MM HH:mm').format(d);

/// (71) 99130-5616 a partir de qualquer coisa com 10-13 digitos.
String formatarTelefone(String? t) {
  if (t == null || t.isEmpty) return '';
  var d = t.replaceAll(RegExp(r'\D'), '');
  if (d.length >= 12 && d.startsWith('55')) d = d.substring(2);
  if (d.length == 11) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
  }
  if (d.length == 10) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
  }
  return t;
}

String iniciais(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (partes.isEmpty) return '?';
  final a = partes.first[0];
  final b = partes.length > 1 ? partes.last[0] : '';
  return (a + b).toUpperCase();
}

// ── Cores ───────────────────────────────────────────────────────────────────

/// Identidade do modulo (HeartPulse no painel): rosa/magenta.
const corAcaoSocial = Color(0xFFC2185B);
const corAcaoSocialClara = Color(0xFFEC407A);

Color corNivelVagas(NivelVagas n, ColorScheme cs) => switch (n) {
      NivelVagas.semVagas => cs.outline,
      NivelVagas.esgotado => const Color(0xFFD32F2F),
      NivelVagas.critico => const Color(0xFFE53935),
      NivelVagas.alto => const Color(0xFFF9A825),
      NivelVagas.ok => const Color(0xFF2E7D32),
    };

Color corStatusAtendimento(String status) => switch (status) {
      'concluido' => const Color(0xFF2E7D32),
      'cancelado' => const Color(0xFF9E9E9E),
      _ => const Color(0xFF1976D2),
    };

String rotuloStatusAtendimento(String status) => switch (status) {
      'concluido' => 'Concluído',
      'cancelado' => 'Cancelado',
      _ => 'Em atendimento',
    };

String rotuloStatusEvento(String status) => switch (status) {
      'finalizado' => 'Finalizado',
      'cancelado' => 'Cancelado',
      _ => 'Ativo',
    };

Color corStatusEvento(String status) => switch (status) {
      'finalizado' => const Color(0xFF546E7A),
      'cancelado' => const Color(0xFF9E9E9E),
      _ => const Color(0xFF2E7D32),
    };

// ── Badges ──────────────────────────────────────────────────────────────────

/// `utilizadas/total` com cor por ocupacao — regra identica ao painel.
class SlotStatusBadge extends StatelessWidget {
  const SlotStatusBadge({
    super.key,
    required this.total,
    required this.utilizadas,
    this.compacto = false,
  });

  final int total;
  final int utilizadas;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nivel = nivelVagas(total, utilizadas);
    final cor = corNivelVagas(nivel, cs);
    final texto = switch (nivel) {
      NivelVagas.semVagas => '—',
      NivelVagas.esgotado => compacto ? '$utilizadas/$total' : 'ESGOTADO',
      _ => '$utilizadas/$total',
    };
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compacto ? 6 : 8, vertical: compacto ? 1 : 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: cor,
          fontSize: compacto ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.rotulo, required this.cor});

  final String rotulo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        rotulo,
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Chip de especialidade colorido pelo status do atendimento.
/// [onTap] abre o menu de acoes (reabrir/concluir/cancelar) — mostra um
/// icone de edicao no fim; [onCancelar] mostra o "x" direto (legado).
class EspecialidadeChip extends StatelessWidget {
  const EspecialidadeChip({
    super.key,
    required this.atendimento,
    this.onCancelar,
    this.onTap,
  });

  final Atendimento atendimento;
  final VoidCallback? onCancelar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cor = corStatusAtendimento(atendimento.status);
    final icone = atendimento.concluido
        ? Icons.check_circle_rounded
        : atendimento.cancelado
            ? Icons.cancel_rounded
            : Icons.schedule_rounded;
    return Material(
      color: cor.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: BorderSide(color: cor.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: cor),
          const SizedBox(width: 4),
          Text(
            atendimento.especialidadeNome ?? atendimento.especialidadeSlug ?? '',
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              decoration:
                  atendimento.cancelado ? TextDecoration.lineThrough : null,
            ),
          ),
          if (onCancelar != null && !atendimento.cancelado) ...[
            const SizedBox(width: 2),
            InkWell(
              onTap: onCancelar,
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 14, color: cor),
              ),
            ),
          ] else if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.edit_rounded, size: 12, color: cor.withValues(alpha: 0.8)),
          ],
        ],
      ),
        ),
      ),
    );
  }
}

// ── Seletor de especialidades ───────────────────────────────────────────────

/// Selecao MULTIPLA de especialidades para atender um paciente. Esgotadas
/// aparecem desabilitadas. Retorna a lista escolhida ou null se cancelou.
class EspecialidadeSelectorSheet extends StatefulWidget {
  const EspecialidadeSelectorSheet({
    super.key,
    required this.especialidades,
    required this.pacienteNome,
    this.jaAtendidas = const {},
  });

  final List<EspecialidadeEvento> especialidades;
  final String pacienteNome;

  /// ids de especialidades que o paciente ja tem atendimento (nao cancelado).
  final Set<String> jaAtendidas;

  static Future<List<EspecialidadeEvento>?> mostrar(
    BuildContext context, {
    required List<EspecialidadeEvento> especialidades,
    required String pacienteNome,
    Set<String> jaAtendidas = const {},
  }) {
    return showModalBottomSheet<List<EspecialidadeEvento>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => EspecialidadeSelectorSheet(
        especialidades: especialidades,
        pacienteNome: pacienteNome,
        jaAtendidas: jaAtendidas,
      ),
    );
  }

  @override
  State<EspecialidadeSelectorSheet> createState() =>
      _EspecialidadeSelectorSheetState();
}

class _EspecialidadeSelectorSheetState
    extends State<EspecialidadeSelectorSheet> {
  final _selecionadas = <String>{};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final alturaMax = MediaQuery.sizeOf(context).height * 0.8;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: alturaMax),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Atender',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  widget.pacienteNome,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selecione uma ou mais especialidades. A vaga é reservada na hora.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (final e in widget.especialidades)
                  _itemEspecialidade(e, cs),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selecionadas.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                          widget.especialidades
                              .where((e) => _selecionadas.contains(e.id))
                              .toList(growable: false),
                        ),
                icon: const Icon(Icons.medical_services_rounded),
                label: Text(_selecionadas.isEmpty
                    ? 'Selecione ao menos uma'
                    : 'Reservar ${_selecionadas.length} '
                        '${_selecionadas.length == 1 ? 'vaga' : 'vagas'}'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemEspecialidade(EspecialidadeEvento e, ColorScheme cs) {
    final jaTem = widget.jaAtendidas.contains(e.id);
    final bloqueada = e.esgotada || jaTem;
    final marcada = _selecionadas.contains(e.id);
    return CheckboxListTile(
      value: marcada,
      enabled: !bloqueada,
      onChanged: bloqueada
          ? null
          : (v) => setState(() {
                if (v == true) {
                  _selecionadas.add(e.id);
                } else {
                  _selecionadas.remove(e.id);
                }
              }),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(e.nome),
      subtitle: jaTem
          ? const Text('Já possui atendimento nesta especialidade')
          : Text('${e.vagasDisponiveis} '
              '${e.vagasDisponiveis == 1 ? 'vaga disponível' : 'vagas disponíveis'}'),
      secondary: SlotStatusBadge(
          total: e.totalVagas, utilizadas: e.vagasUtilizadas, compacto: true),
    );
  }
}
