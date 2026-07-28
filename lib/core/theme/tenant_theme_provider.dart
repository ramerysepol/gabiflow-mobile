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
  /// Cor efetiva: preferência do usuário logado (user_preferences) →
  /// senão a cor oficial do gabinete (system_tenants) → senão padrão.
  /// Silencioso em caso de erro — o app segue com a última cor conhecida.
  Future<void> refreshFromServer(String subdomain) async {
    try {
      final client = ApiClient();
      client.updateBaseUrl(subdomain);

      // 1) Cor oficial do gabinete (público)
      String? corGabinete;
      String? logoUrl;
      String? nome;
      final res = await client.get<Map<String, dynamic>>(
        '/api/mobile/tenant/theme',
        queryParameters: {'subdomain': subdomain},
      );
      final body = res.data;
      if (res.statusCode == 200 && body != null && body['success'] == true) {
        final data = (body['data'] as Map?)?.cast<String, dynamic>();
        corGabinete = data?['primary_color'] as String?;
        logoUrl = data?['logo_url'] as String?;
        nome = data?['name'] as String?;
      }

      // 2) Preferência do usuário logado (se houver sessão)
      final corUsuario = await _buscarCorDoUsuario(client);

      final corEfetiva = corUsuario ?? corGabinete;

      // Persiste junto da config do tenant (se ainda for o mesmo gabinete)
      final config =
          await StorageService.getTenantConfig() ?? <String, dynamic>{};
      if ((config['subdomain'] as String?) != subdomain) return;
      config['primary_color'] = corEfetiva;
      config['logo_url'] = logoUrl;
      if (nome != null) config['name'] = nome;
      await StorageService.saveTenantConfig(config);

      if (!mounted) return;
      state = parseHexColor(corEfetiva) ?? AppColors.defaultSeed;
      LoggerService.i(
          'Tema aplicado: ${corEfetiva ?? 'padrão'} (usuário: ${corUsuario != null})');
    } catch (e) {
      LoggerService.e('Tema do gabinete — falha ao atualizar', e);
    }
  }

  /// Preferência de cor do usuário logado; null se sem sessão ou sem
  /// preferência salva.
  Future<String?> _buscarCorDoUsuario(ApiClient client) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) return null;
      final res = await client.get<Map<String, dynamic>>(
        '/api/mobile/settings/appearance',
      );
      final body = res.data;
      if (res.statusCode != 200 || body == null || body['success'] != true) {
        return null;
      }
      final appearance =
          ((body['data'] as Map?)?['appearance'] as Map?)?.cast<String, dynamic>();
      final cor = appearance?['primaryColor'] as String?;
      return parseHexColor(cor) != null ? cor : null;
    } catch (_) {
      return null;
    }
  }
}

final tenantSeedProvider = StateNotifierProvider<TenantSeedNotifier, Color>(
  (ref) => TenantSeedNotifier(AppColors.defaultSeed),
);
