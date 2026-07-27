import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/municipio_eleitos_model.dart';
import '../providers/eleitoral_providers.dart';
import 'numero_formatado.dart';

/// Bottom sheet que mostra os candidatos eleitos (e suplentes) que receberam
/// votos no município informado, para o cargo selecionado no filtro global.
class EleitosMunicipioSheet extends ConsumerWidget {
  const EleitosMunicipioSheet({
    super.key,
    required this.idMunicipio,
    required this.nomeMunicipio,
  });

  final String idMunicipio;
  final String nomeMunicipio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(eleitosDoMunicipioProvider(idMunicipio));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomeMunicipio,
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Eleitos com votação no município',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: asyncData.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              size: 36, color: cs.error),
                          const SizedBox(height: 12),
                          Text(
                            'Não foi possível carregar os eleitos',
                            style: tt.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Verifique sua conexão e tente novamente.',
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: () => ref.invalidate(
                                eleitosDoMunicipioProvider(idMunicipio)),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (data) {
                    if (data.items.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhum candidato eleito com votos neste município',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        // KPIs topo
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Row(
                            children: [
                              _KpiChip(
                                label: 'Eleitos com voto',
                                value: '${data.totalEleitos}',
                                icon: Icons.verified_outlined,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 8),
                              _KpiChip(
                                label: 'Total de votos',
                                value: formatarNumero(data.totalVotos),
                                icon: Icons.how_to_vote_outlined,
                                color: cs.tertiary,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.separated(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: data.items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 70),
                            itemBuilder: (ctx, i) => _EleitoTile(
                              posicao: i + 1,
                              eleito: data.items[i],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EleitoTile extends StatelessWidget {
  const _EleitoTile({
    required this.posicao,
    required this.eleito,
  });

  final int posicao;
  final EleitoMunicipioModel eleito;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final badgeColor = eleito.isEleito
        ? const Color(0xFF16A34A)
        : eleito.isSuplente
            ? const Color(0xFFD97706)
            : cs.onSurfaceVariant;
    final badgeLabel = eleito.isEleito
        ? 'ELEITO'
        : eleito.isSuplente
            ? 'SUPLENTE'
            : eleito.resultado.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Posição
          SizedBox(
            width: 22,
            child: Text(
              '$posicao',
              style: tt.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primaryContainer,
            child: eleito.fotoUrl != null && eleito.fotoUrl!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: eleito.fotoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _Inicial(
                        nome: eleito.nomeUrna,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  )
                : _Inicial(
                    nome: eleito.nomeUrna,
                    color: cs.onPrimaryContainer,
                  ),
          ),
          const SizedBox(width: 12),
          // Nome + partido + badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eleito.nomeUrna.isNotEmpty ? eleito.nomeUrna : eleito.nome,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        eleito.siglaPartido.isNotEmpty
                            ? eleito.siglaPartido
                            : '',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Votos + %
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatarNumero(eleito.votosMunicipio),
                style: tt.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${formatarDecimal(eleito.percentualMunicipio)}%',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Inicial extends StatelessWidget {
  const _Inicial({required this.nome, required this.color});

  final String nome;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';
    return Text(
      inicial,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
