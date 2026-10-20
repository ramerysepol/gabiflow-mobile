import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/apuracao_mapa_uf_model.dart';
import 'apuracao_providers.dart';

/// Painel nacional por estados do [cargo] (padrão 1 = Presidente).
///
/// `invalidate` mantém o valor anterior visível enquanto recarrega (poll de
/// 30s/15s sem piscar a tela).
final apuracaoMapaUfProvider = FutureProvider.autoDispose
    .family<ApuracaoMapaUfModel, int>((ref, cargo) {
      return ref.watch(apuracaoDatasourceProvider).getMapaUf(cargo: cargo);
    });
