import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';
import 'design_tokens.dart';

/// Converte "#RRGGBB" em [Color]; null se inválido.
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex.trim());
  if (match == null) return null;
  return Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
}

/// Lê a cor do gabinete salva no storage — usada pelo main() para semear o
/// tema já na abertura, sem flash da cor padrão.
Future<Color> loadSavedSeedColor() async {
  final config = await StorageService.getTenantConfig();
  return parseHexColor(config?['primary_color'] as String?) ??
      AppColors.defaultSeed;
}

/// Cor semente do tema, definida pelo gabinete (theme_primary_color no
/// desktop). Atualizada no setup do tenant e a cada abertura do app.
class TenantSeedNotifier extends StateNotifier<Color> {
  TenantSeedNotifier(super.initial);

  /// Volta à cor padrão (troca de gabinete).
  void reset() => state = AppColors.defaultSeed;

  /// Busca o tema no servidor, persiste no config do tenant e aplica.
  /// Silencioso em caso de erro — o app segue com a última cor conhecida.
  Future<void> refreshFromServer(String subdomain) async {
    try {
      final client = ApiClient();
      client.updateBaseUrl(subdomain);
      final res = await client.get<Map<String, dynamic>>(
        '/api/mobile/tenant/theme',
        queryParameters: {'subdomain': subdomain},
      );
      final body = res.data;
      if (res.statusCode != 200 || body == null || body['success'] != true) {
        return;
      }
      final data = (body['data'] as Map?)?.cast<String, dynamic>();
      if (data == null) return;

      // Persiste junto da config do tenant (se ainda for o mesmo gabinete)
      final config =
          await StorageService.getTenantConfig() ?? <String, dynamic>{};
      if ((config['subdomain'] as String?) != subdomain) return;
      config['primary_color'] = data['primary_color'];
      config['logo_url'] = data['logo_url'];
      config['name'] = data['name'];
      await StorageService.saveTenantConfig(config);

      if (!mounted) return;
      state = parseHexColor(data['primary_color'] as String?) ??
          AppColors.defaultSeed;
      LoggerService.i(
          'Tema do gabinete aplicado: ${data['primary_color'] ?? 'padrão'}');
    } catch (e) {
      LoggerService.e('Tema do gabinete — falha ao atualizar', e);
    }
  }
}

final tenantSeedProvider = StateNotifierProvider<TenantSeedNotifier, Color>(
  (ref) => TenantSeedNotifier(AppColors.defaultSeed),
);
