import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_providers.dart';
import '../../data/datasources/whatsapp_remote_datasource.dart';
import '../../data/models/whatsapp_models.dart';

final whatsappDataSourceProvider = Provider<WhatsAppRemoteDataSource>((ref) {
  return WhatsAppRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final whatsappConfigProvider =
    FutureProvider.autoDispose<WhatsAppConfig>((ref) async {
  final ds = ref.watch(whatsappDataSourceProvider);
  return ds.getConfig();
});

final whatsappTemplatesProvider =
    FutureProvider.autoDispose<WhatsAppTemplates>((ref) async {
  final ds = ref.watch(whatsappDataSourceProvider);
  return ds.getTemplates();
});

final campanhaStatusProvider = FutureProvider.autoDispose
    .family<CampanhaStatus, int>((ref, id) async {
  final ds = ref.watch(whatsappDataSourceProvider);
  return ds.getCampaign(id);
});
