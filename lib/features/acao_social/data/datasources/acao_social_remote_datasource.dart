// Acao Social — consome as MESMAS rotas do painel (/api/expresso-saude/*),
// que aceitam Authorization: Bearer (lib/auth-jwt.ts do backend tenta o
// Bearer antes do cookie). Mesmo precedente da Central de Atendimento.
//
// Regras de negocio (reserva atomica de vaga, devolucao ao cancelar, upsert
// de municipe por telefone, template WhatsApp) ficam TODAS no servidor.

import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../models/acao_social_models.dart';

abstract class AcaoSocialRemoteDataSource {
  /// [status]: 'ativo' | 'finalizado' | 'cancelado' | null (todos).
  Future<List<EventoAcaoSocial>> listarEventos({String? status});
  Future<EventoAcaoSocial> obterEvento(String id);
  Future<List<EspecialidadeEvento>> listarEspecialidades(String eventoId);
  Future<List<Cadastrado>> listarCadastrados(String tag, {String? busca});
  Future<List<Atendimento>> listarAtendimentos(
    String eventoId, {
    int? eleitorId,
    String? status,
  });
  Future<Atendimento> criarAtendimento({
    required String eventoId,
    required String especialidadeId,
    required int eleitorId,
  });
  Future<Atendimento> atualizarAtendimento(
      String id, Map<String, dynamic> body);
  Future<CadastroPresencialResult> cadastroPresencial(
      Map<String, dynamic> body);
  Future<EnderecoCep?> buscarCep(String cep);

  /// PDF da ficha (GET /atendimentos/{id}/pdf). O servidor monta UMA ficha do
  /// paciente com todas as especialidades dele no evento — qualquer
  /// atendimento nao cancelado do paciente serve como id.
  Future<List<int>> baixarFichaPdf(String atendimentoId);
}

class AcaoSocialRemoteDataSourceImpl implements AcaoSocialRemoteDataSource {
  final ApiClient _apiClient;

  AcaoSocialRemoteDataSourceImpl(this._apiClient);

  Future<Options> _authOptions() async {
    final token = await StorageService.getAccessToken();
    final tenantConfig = await StorageService.getTenantConfig();
    final tenantId = tenantConfig?['subdomain'] as String? ?? '';
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
      'X-Tenant-ID': tenantId,
    });
  }

  /// Desembrulha {success, data} e converte falha em excecao com a mensagem
  /// do backend. Necessario porque o ApiClient nao lanca em 4xx (401/403/
  /// 404/409 chegam como resposta normal) — sem isto um "vagas esgotadas"
  /// viraria model vazio silencioso.
  dynamic _extract(Response<Map<String, dynamic>> response, String contexto) {
    final body = response.data;
    if (body == null) throw Exception('Resposta vazia ao $contexto');
    if (body['success'] != true) {
      throw Exception(body['error']?.toString() ?? 'Falha ao $contexto');
    }
    return body['data'];
  }

  Map<String, dynamic> _extractMap(
      Response<Map<String, dynamic>> response, String contexto) {
    final data = _extract(response, contexto);
    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inesperada ao $contexto');
    }
    return data;
  }

  List<Map<String, dynamic>> _extractList(
      Response<Map<String, dynamic>> response, String contexto) {
    final data = _extract(response, contexto);
    if (data is! List) throw Exception('Resposta inesperada ao $contexto');
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Future<List<EventoAcaoSocial>> listarEventos({String? status}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/expresso-saude/events',
      queryParameters: {if (status != null) 'status': status},
      options: await _authOptions(),
    );
    return _extractList(response, 'listar eventos')
        .map(EventoAcaoSocial.fromJson)
        .toList(growable: false);
  }

  @override
  Future<EventoAcaoSocial> obterEvento(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/expresso-saude/events/$id',
      options: await _authOptions(),
    );
    return EventoAcaoSocial.fromJson(_extractMap(response, 'carregar evento'));
  }

  @override
  Future<List<EspecialidadeEvento>> listarEspecialidades(
      String eventoId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/expresso-saude/events/$eventoId/specialties',
      options: await _authOptions(),
    );
    final data = _extractMap(response, 'listar especialidades');
    final lista = data['especialidades'];
    if (lista is! List) return const [];
    return lista
        .whereType<Map<String, dynamic>>()
        .map(EspecialidadeEvento.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<Cadastrado>> listarCadastrados(String tag,
      {String? busca}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/expresso-saude/cadastrados',
      queryParameters: {
        'tag': tag,
        if (busca != null && busca.trim().isNotEmpty) 'search': busca.trim(),
      },
      options: await _authOptions(),
    );
    return _extractList(response, 'listar cadastrados')
        .map(Cadastrado.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<Atendimento>> listarAtendimentos(
    String eventoId, {
    int? eleitorId,
    String? status,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/expresso-saude/atendimentos',
      queryParameters: {
        'evento_id': eventoId,
        if (eleitorId != null) 'eleitor_id': eleitorId,
        if (status != null) 'status': status,
      },
      options: await _authOptions(),
    );
    return _extractList(response, 'listar atendimentos')
        .map(Atendimento.fromJson)
        .toList(growable: false);
  }

  @override
  Future<Atendimento> criarAtendimento({
    required String eventoId,
    required String especialidadeId,
    required int eleitorId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/expresso-saude/atendimentos',
      data: {
        'evento_id': eventoId,
        'especialidade_id': especialidadeId,
        'eleitor_id': eleitorId,
      },
      options: await _authOptions(),
    );
    // 409 "Vagas esgotadas" chega aqui como {success:false,error} → Exception
    return Atendimento.fromJson(_extractMap(response, 'criar atendimento'));
  }

  @override
  Future<Atendimento> atualizarAtendimento(
      String id, Map<String, dynamic> body) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/api/expresso-saude/atendimentos/$id',
      data: body,
      options: await _authOptions(),
    );
    return Atendimento.fromJson(_extractMap(response, 'salvar ficha'));
  }

  @override
  Future<CadastroPresencialResult> cadastroPresencial(
      Map<String, dynamic> body) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/expresso-saude/cadastro-presencial',
      data: body,
      options: await _authOptions(),
    );
    return CadastroPresencialResult.fromJson(
        _extractMap(response, 'cadastrar municipe'));
  }

  @override
  Future<List<int>> baixarFichaPdf(String atendimentoId) async {
    final auth = await _authOptions();
    final response = await _apiClient.get<List<int>>(
      '/api/expresso-saude/atendimentos/$atendimentoId/pdf',
      options: auth.copyWith(
        responseType: ResponseType.bytes,
        headers: {...?auth.headers, 'Accept': 'application/pdf'},
      ),
    );
    final bytes = response.data;
    // 401/403/404 chegam como JSON em bytes (validateStatus < 500)
    if (response.statusCode != 200 || bytes == null || bytes.isEmpty) {
      String motivo = 'Falha ao gerar o PDF (HTTP ${response.statusCode})';
      if (bytes != null && bytes.isNotEmpty) {
        try {
          final json = jsonDecode(utf8.decode(bytes));
          if (json is Map && json['error'] is String) {
            motivo = json['error'] as String;
          }
        } catch (_) {
          // corpo nao e JSON: mantem a mensagem generica
        }
      }
      throw Exception(motivo);
    }
    return bytes;
  }

  @override
  Future<EnderecoCep?> buscarCep(String cep) async {
    final digitos = cep.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 8) return null;
    // Servico publico usado pelo painel; Dio "cru" (sem interceptors/tenant).
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      validateStatus: (s) => s != null && s < 500,
    ));
    final r = await dio.get<dynamic>('https://opencep.com/v1/$digitos.json');
    final data = r.data;
    if (r.statusCode != 200 || data is! Map) return null;
    String? campo(String k) {
      final v = data[k];
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return EnderecoCep(
      logradouro: campo('logradouro'),
      bairro: campo('bairro'),
      cidade: campo('localidade'),
      uf: campo('uf'),
    );
  }
}
