import 'package:flutter/material.dart';

/// Argumentos passados (via go_router extra) entre as telas do comparativo
/// município -> bairros -> seções.
class ComparativoArgs {
  final String municipio; // IBGE 7
  final String nomeMunicipio;
  final String candA;
  final String candB;
  final String nomeA;
  final String nomeB;
  final String? bairro;

  const ComparativoArgs({
    required this.municipio,
    required this.nomeMunicipio,
    required this.candA,
    required this.candB,
    required this.nomeA,
    required this.nomeB,
    this.bairro,
  });

  ComparativoArgs comBairro(String b) => ComparativoArgs(
        municipio: municipio,
        nomeMunicipio: nomeMunicipio,
        candA: candA,
        candB: candB,
        nomeA: nomeA,
        nomeB: nomeB,
        bairro: b,
      );
}

/// Cores A/B do comparativo (mesmo visual da página de comparação).
Color corComparativoA(ColorScheme cs) => cs.primary;
Color corComparativoB(ColorScheme cs) => Colors.orange.shade700;
