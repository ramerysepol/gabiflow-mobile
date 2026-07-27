import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/candidato_model.dart';
import 'numero_formatado.dart';

class CandidatoCard extends StatelessWidget {
  const CandidatoCard({
    super.key,
    required this.candidato,
    required this.onTap,
  });

  final CandidatoModel candidato;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _AvatarCandidato(
                nomeUrna: candidato.nomeUrna,
                fotoUrl: candidato.fotoUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidato.nomeUrna,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${candidato.siglaPartido} · ${candidato.cargo}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (candidato.municipiosAtingidos > 0)
                      Text(
                        '${candidato.municipiosAtingidos} municípios',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatarVotos(candidato.votosTotal),
                style: tt.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarCandidato extends StatelessWidget {
  const _AvatarCandidato({required this.nomeUrna, this.fotoUrl});

  final String nomeUrna;
  final String? fotoUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inicial = nomeUrna.isNotEmpty ? nomeUrna[0].toUpperCase() : '?';

    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: cs.primaryContainer,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: fotoUrl!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Text(
              inicial,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: cs.primaryContainer,
      child: Text(
        inicial,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
