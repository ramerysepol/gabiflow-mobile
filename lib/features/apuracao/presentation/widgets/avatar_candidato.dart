import 'package:flutter/material.dart';

import '../cores_duelo.dart';

/// "Foto" do candidato: a API não traz imagem, então usa as iniciais sobre a
/// cor do partido.
class AvatarCandidato extends StatelessWidget {
  const AvatarCandidato({
    super.key,
    required this.nome,
    required this.cor,
    this.tamanho = 48,
  });

  final String nome;
  final Color cor;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(tamanho * 0.28),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        iniciaisCandidato(nome),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: tamanho * 0.38,
        ),
      ),
    );
  }
}
