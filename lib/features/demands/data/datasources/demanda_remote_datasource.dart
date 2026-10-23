// Contrato: Spec Demandas 2.0 §4 — rotas /api/mobile/demandas/**, envelope
// {success, data} / {success:false, error}. Mesmos shapes da web.

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../models/demanda_extras.dart';
import '../models/demanda_model.dart';

class DemandaRemoteDataSource {
  DemandaRemoteDataSource(this._api);

  final ApiClient _api;
  static const _base = '/api/mobile/demandas';

  Future<Options> _auth({ResponseType? tipo}) async {
    final token = await StorageService.getAccessToken();
    final tenant = await StorageService.getTenantConfig();
    return Options(
      responseType: tipo,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'X-Tenant-ID': tenant?['subdomain'] as String? ?? '',
      },
    );
  }

  /// Desembrulha {success, data}; falha vira exceção com a mensagem do backend.
  dynamic _data(Map<String, dynamic>? body) {
    if (body == null) throw Exception('Resposta vazia do servidor');
    if (body['success'] == false) {
      throw Exception(body['error']?.toString() ?? 'Erro desconhecido');
    }
    return body['data'];
  }

  Map<String, dynamic> _obj(Map<String, dynamic>? body) {
    final d = _data(body);
    if (d is! Map) throw Exception('Resposta inesperada do servidor');
    return Map<String, dynamic>.from(d);
  }

  Future<Map<String, dynamic>> _post(String path, Object? corpo) async {
    final r = await _api.post<Map<String, dynamic>>(
      '$_base$path',
      data: corpo,
      options: await _auth(),
    );
    return _obj(r.data);
  }

  // ── Leitura ──────────────────────────────────────────────────────────────

  Future<DemandaListaResposta> listar(
    DemandaFiltros filtros, {
    int page = 1,
    int limit = 20,
  }) async {
    final r = await _api.get<Map<String, dynamic>>(
      _base,
      queryParameters: {
        ...filtros.toQuery(),
        'page': page,
        'limit': limit,
        'ordem': 'prazo',
      },
      options: await _auth(),
    );
    return DemandaListaResposta.fromJson(_obj(r.data));
  }

  Future<DemandaListaResposta> listarDoMunicipe(
    int eleitorId, {
    int limit = 20,
  }) async {
    final r = await _api.get<Map<String, dynamic>>(
      _base,
      queryParameters: {
        'municipe': eleitorId,
        'limit': limit,
        'ordem': '-createdAt',
      },
      options: await _auth(),
    );
    return DemandaListaResposta.fromJson(_obj(r.data));
  }

  Future<DemandaDetalhe> detalhe(int id) async {
    final r = await _api.get<Map<String, dynamic>>(
      '$_base/$id',
      options: await _auth(),
    );
    return DemandaDetalhe.fromJson(_obj(r.data));
  }

  Future<DemandaOpcoes> opcoes() async {
    final r = await _api.get<Map<String, dynamic>>(
      '$_base/opcoes',
      options: await _auth(),
    );
    return DemandaOpcoes.fromJson(_obj(r.data));
  }

  Future<DemandaConfig> config() async {
    final r = await _api.get<Map<String, dynamic>>(
      '$_base/config',
      options: await _auth(),
    );
    return DemandaConfig.fromJson(_obj(r.data));
  }

  // ── Escrita ──────────────────────────────────────────────────────────────

  Future<DemandaDetalhe> criar(Map<String, dynamic> corpo) async =>
      DemandaDetalhe.fromJson(await _post('', corpo));

  Future<DemandaDetalhe> editar(int id, Map<String, dynamic> corpo) async {
    final r = await _api.patch<Map<String, dynamic>>(
      '$_base/$id',
      data: corpo,
      options: await _auth(),
    );
    return DemandaDetalhe.fromJson(_obj(r.data));
  }

  Future<DemandaDetalhe> mudarStatus(
    int id,
    String status, {
    String? comentario,
    bool notificarMunicipe = false,
    String? mensagem,
  }) async => DemandaDetalhe.fromJson(
    await _post('/$id/status', {
      'status': status,
      if (comentario != null && comentario.trim().isNotEmpty)
        'comentario': comentario.trim(),
      'notificarMunicipe': notificarMunicipe,
      if (notificarMunicipe && mensagem != null && mensagem.trim().isNotEmpty)
        'mensagem': mensagem.trim(),
    }),
  );

  Future<DemandaDetalhe> atribuir(int id, int? responsavelUserId) async =>
      DemandaDetalhe.fromJson(
        await _post('/$id/atribuir', {'responsavelUserId': responsavelUserId}),
      );

  Future<DemandaEvento> comentar(
    int id,
    String texto, {
    bool visivelMunicipe = false,
  }) async => DemandaEvento.fromJson(
    await _post('/$id/comentarios', {
      'texto': texto.trim(),
      'visivelMunicipe': visivelMunicipe,
    }),
  );

  Future<DemandaDetalhe> encaminhar(
    int id, {
    int? orgaoId,
    String? orgaoNome,
    String? prazoResposta,
    bool gerarOficio = false,
  }) async {
    final m = await _post('/$id/encaminhar', {
      if (orgaoId != null) 'orgaoId': orgaoId,
      if (orgaoId == null && orgaoNome != null) 'orgaoNome': orgaoNome,
      if (prazoResposta != null) 'prazoResposta': prazoResposta,
      'gerarOficio': gerarOficio,
    });
    return DemandaDetalhe.fromJson(
      m['demanda'] is Map ? Map<String, dynamic>.from(m['demanda'] as Map) : m,
    );
  }

  Future<String> previaRetorno(int id, {String? status}) async {
    final r = await _api.get<Map<String, dynamic>>(
      '$_base/$id/retorno/previa',
      queryParameters: {if (status != null) 'status': status},
      options: await _auth(),
    );
    return _obj(r.data)['mensagem']?.toString() ?? '';
  }

  Future<void> enviarRetorno(int id, String mensagem) async {
    await _post('/$id/retorno', {'mensagem': mensagem.trim()});
  }

  Future<DemandaSugestaoIa> sugerirIa({
    String? texto,
    int? conversationId,
    int? eleitorId,
  }) async => DemandaSugestaoIa.fromJson(
    await _post('/ia/sugerir', {
      if (texto != null && texto.trim().isNotEmpty) 'texto': texto.trim(),
      if (conversationId != null) 'conversationId': conversationId,
      if (eleitorId != null) 'eleitorId': eleitorId,
    }),
  );

  Future<void> excluir(int id) async {
    await _api.delete<Map<String, dynamic>>(
      '$_base/$id',
      options: await _auth(),
    );
  }

  // ── Anexos ───────────────────────────────────────────────────────────────

  Future<DemandaAnexo> enviarAnexo(
    int id,
    String caminho, {
    String tipo = 'anexo',
  }) async {
    final nome = caminho.split('/').last;
    final ext = nome.contains('.') ? nome.split('.').last.toLowerCase() : '';
    // MIME explícito: sem isto o Dio manda octet-stream e o servidor recusa.
    final mime = switch (ext) {
      'png' => DioMediaType('image', 'png'),
      'heic' => DioMediaType('image', 'heic'),
      'heif' => DioMediaType('image', 'heif'),
      'webp' => DioMediaType('image', 'webp'),
      'jpg' || 'jpeg' => DioMediaType('image', 'jpeg'),
      'pdf' => DioMediaType('application', 'pdf'),
      'doc' => DioMediaType('application', 'msword'),
      'docx' => DioMediaType(
        'application',
        'vnd.openxmlformats-officedocument.wordprocessingml.document',
      ),
      _ => DioMediaType('application', 'octet-stream'),
    };
    final form = FormData.fromMap({
      'arquivo': await MultipartFile.fromFile(
        caminho,
        filename: nome,
        contentType: mime,
      ),
      'tipo': tipo,
    });
    return DemandaAnexo.fromJson(await _post('/$id/anexos', form));
  }

  /// Download autenticado (o arquivo é privado no servidor).
  Future<List<int>> baixarAnexo(int id, int anexoId) async {
    final r = await _api.get<List<int>>(
      '$_base/$id/anexos/$anexoId',
      options: await _auth(tipo: ResponseType.bytes),
    );
    return r.data ?? const [];
  }

  Future<void> removerAnexo(int id, int anexoId) async {
    await _api.delete<Map<String, dynamic>>(
      '$_base/$id/anexos/$anexoId',
      options: await _auth(),
    );
  }
}
