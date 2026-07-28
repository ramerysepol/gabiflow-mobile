// Endpoints exclusivos mobile: /api/mobile/whatsapp/*
// config, templates, send (individual), send-bulk (filtros) e campaigns/{id}.

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../../../constituents/data/models/constituent_extras.dart';
import '../models/whatsapp_models.dart';

abstract class WhatsAppRemoteDataSource {
  Future<WhatsAppConfig> getConfig();
  Future<WhatsAppTemplates> getTemplates();

  /// Envio individual. [tipo]: 'meta' | 'local' | 'texto'.
  Future<void> sendIndividual({
    required String tipo,
    required String phone,
    String? templateName,
    String? language,
    int? templateId,
    Map<String, String>? variables,
    String? message,
    String? headerType,
    String? headerUrl,
  });

  /// Faz upload de mídia (imagem) e retorna a URL pública.
  Future<String> uploadMedia(String filePath, {String mediaType = 'image'});

  /// Envio em massa pelos filtros ativos. Retorna o id da campanha.
  Future<int> sendBulk({
    required String tipo,
    String? nome,
    String? templateName,
    String? language,
    List<int>? templateIds,
    Map<String, MapeamentoVariavel>? mapeamento,
    ConstituentFilters filtros = ConstituentFilters.vazios,
    String? search,
    int intervaloSegundos = 3,
    String? headerType,
    String? headerUrl,
  });

  Future<CampanhaStatus> getCampaign(int id);
}

class WhatsAppRemoteDataSourceImpl implements WhatsAppRemoteDataSource {
  final ApiClient _apiClient;

  WhatsAppRemoteDataSourceImpl(this._apiClient);

  Future<Options> _authOptions() async {
    final token = await StorageService.getAccessToken();
    final tenantConfig = await StorageService.getTenantConfig();
    final tenantId = tenantConfig?['subdomain'] as String? ?? '';
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
      'X-Tenant-ID': tenantId,
    });
  }

  Map<String, dynamic> _extractData(Map<String, dynamic>? body) {
    if (body == null) throw Exception('Resposta vazia do servidor');
    if (body['success'] == false) {
      throw Exception(body['error']?.toString() ?? 'Erro desconhecido');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inesperada do servidor');
    }
    return data;
  }

  @override
  Future<WhatsAppConfig> getConfig() async {
    final opts = await _authOptions();
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/whatsapp/config',
      options: opts,
    );
    return WhatsAppConfig.fromJson(_extractData(response.data));
  }

  @override
  Future<WhatsAppTemplates> getTemplates() async {
    final opts = await _authOptions();
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/whatsapp/templates',
      options: opts,
    );
    return WhatsAppTemplates.fromJson(_extractData(response.data));
  }

  @override
  Future<void> sendIndividual({
    required String tipo,
    required String phone,
    String? templateName,
    String? language,
    int? templateId,
    Map<String, String>? variables,
    String? message,
    String? headerType,
    String? headerUrl,
  }) async {
    final opts = await _authOptions();
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/mobile/whatsapp/send',
      data: {
        'tipo': tipo,
        'phone': phone,
        if (templateName != null) 'template_name': templateName,
        if (language != null) 'language': language,
        if (templateId != null) 'template_id': templateId,
        if (variables != null) 'variables': variables,
        if (message != null) 'message': message,
        if (headerType != null) 'header_type': headerType,
        if (headerUrl != null) 'header_url': headerUrl,
      },
      options: opts,
    );
    _extractData(response.data);
  }

  @override
  Future<String> uploadMedia(String filePath,
      {String mediaType = 'image'}) async {
    final opts = await _authOptions();
    // MIME pela extensão — sem isso o Dio envia octet-stream e o backend rejeita
    final ext = filePath.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'png' => DioMediaType('image', 'png'),
      'jpg' || 'jpeg' => DioMediaType('image', 'jpeg'),
      _ => DioMediaType('image', 'jpeg'),
    };
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, contentType: mime),
      'mediaType': mediaType,
    });
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/mobile/whatsapp/upload-media',
      data: formData,
      options: opts,
    );
    final data = _extractData(response.data);
    final url = data['url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('Upload não retornou a URL do arquivo');
    }
    return url;
  }

  @override
  Future<int> sendBulk({
    required String tipo,
    String? nome,
    String? templateName,
    String? language,
    List<int>? templateIds,
    Map<String, MapeamentoVariavel>? mapeamento,
    ConstituentFilters filtros = ConstituentFilters.vazios,
    String? search,
    int intervaloSegundos = 3,
    String? headerType,
    String? headerUrl,
  }) async {
    final opts = await _authOptions();
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/mobile/whatsapp/send-bulk',
      data: {
        'tipo': tipo,
        if (nome != null && nome.isNotEmpty) 'nome': nome,
        if (templateName != null) 'template_name': templateName,
        if (language != null) 'language': language,
        if (templateIds != null) 'template_ids': templateIds,
        if (headerType != null) 'header_type': headerType,
        if (headerUrl != null) 'header_url': headerUrl,
        if (mapeamento != null)
          'mapeamento':
              mapeamento.map((k, v) => MapEntry(k, v.toJson())),
        'filtros': {
          if (search != null && search.isNotEmpty) 'search': search,
          if (filtros.cidade != null) 'cidade': filtros.cidade,
          if (filtros.tag != null) 'tag': filtros.tag,
          if (filtros.nivelApoio != null) 'nivel_apoio': filtros.nivelApoio,
          if (filtros.aniversariantes != null)
            'aniversariantes': filtros.aniversariantes,
        },
        'intervalo_segundos': intervaloSegundos,
      },
      options: opts,
    );
    final data = _extractData(response.data);
    return (data['campaign_id'] as num).toInt();
  }

  @override
  Future<CampanhaStatus> getCampaign(int id) async {
    final opts = await _authOptions();
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/mobile/whatsapp/campaigns/$id',
      options: opts,
    );
    return CampanhaStatus.fromJson(_extractData(response.data));
  }
}
