import 'package:flutter/material.dart';

import '../widgets/hierarquia_tree.dart';

/// Página standalone da hierarquia territorial do candidato.
class CandidatoHierarquiaPage extends StatelessWidget {
  const CandidatoHierarquiaPage({super.key, required this.sequencial});

  final String sequencial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hierarquia Territorial')),
      body: HierarquiaTree(sequencial: sequencial),
    );
  }
}
