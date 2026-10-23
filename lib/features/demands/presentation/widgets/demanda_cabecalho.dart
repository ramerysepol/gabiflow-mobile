import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/demanda_model.dart';
import '../../data/models/demanda_vocab.dart';
import 'demanda_chips.dart';

/// Cabeçalho: protocolo, título, chips, SLA com semáforo e munícipe.
class DemandaCabecalho extends StatelessWidget {
  const DemandaCabecalho({super.key, required this.demanda});
  final DemandaDetalhe demanda;

  Future<void> _whatsapp(BuildContext context) async {
    final m = demanda.municipe;
    final conv = demanda.conversationId;
    if (conv != null) {
      final q = <String, String>{
        if (m != null) 'nome': m.nome,
        if ((m?.telefone ?? '').isNotEmpty) 'tel': m!.telefone!,
      };
      context.push(
        Uri(
          path: '/home/atendimento/chat/$conv',
          queryParameters: q.isEmpty ? null : q,
        ).toString(),
      );
      return;
    }
    var digitos = (m?.telefone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return;
    if (digitos.length <= 11) digitos = '55$digitos';
    await launchUrl(
      Uri.parse('https://wa.me/$digitos'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final d = demanda;
    final m = d.municipe;
    final temTel = (m?.telefone ?? '').trim().isNotEmpty;
    final acento = d.ehSaude ? DemandaVocab.corSaude(context) : null;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        side: BorderSide(
          color: acento?.withValues(alpha: 0.5) ?? cs.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.protocolo,
              style: tt.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              d.titulo,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                DemandaStatusChip(d.status),
                DemandaPrioridadeChip(d.prioridade),
                if (d.ehSaude) const DemandaSaudeChip(),
                DemandaChip(
                  rotulo: DemandaVocab.canal(d.canal),
                  cor: cs.onSurfaceVariant,
                ),
              ],
            ),
            if (semaforoPrazo(context, d) != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: DemandaPrazoLabel(d, grande: true)),
                  if (d.responsavel != null)
                    Flexible(
                      child: Text(
                        'Resp.: ${d.responsavel!.nome}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ] else if (d.responsavel != null) ...[
              const SizedBox(height: 8),
              Text('Responsável: ${d.responsavel!.nome}', style: tt.bodySmall),
            ],
            if (m != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      m.nome.isEmpty ? '?' : m.nome[0].toUpperCase(),
                      style: TextStyle(color: cs.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          [
                            m.telefone,
                            d.bairro ?? m.bairro,
                          ].where((e) => e != null && e.isNotEmpty).join(' · '),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (temTel || d.conversationId != null)
                    IconButton.filledTonal(
                      tooltip: 'Abrir WhatsApp',
                      icon: const Icon(Icons.chat_rounded),
                      onPressed: () => _whatsapp(context),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
