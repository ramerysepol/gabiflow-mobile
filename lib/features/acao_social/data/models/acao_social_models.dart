// Models do modulo Acao Social — sem geracao de codigo.
//
// No backend o modulo se chama `expresso-saude` (rotas, tabelas e
// permissoes); "Acao Social" e' so o rotulo de interface. Um EVENTO
// (mutirao) tem N ESPECIALIDADES com controle de vagas; municipes
// (eleitores) cadastrados recebem a TAG do evento e viram pacientes de
// ATENDIMENTOS (paciente x especialidade) com ficha de anamnese.

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _bool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == 'true' || v == 't' || v == '1';
  return false;
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// Nivel de ocupacao das vagas — mesma regra do `SlotStatusBadge` do painel.
enum NivelVagas { semVagas, esgotado, critico, alto, ok }

NivelVagas nivelVagas(int total, int utilizadas) {
  if (total <= 0) return NivelVagas.semVagas;
  if (utilizadas >= total) return NivelVagas.esgotado;
  final p = utilizadas / total;
  if (p >= 0.9) return NivelVagas.critico;
  if (p >= 0.7) return NivelVagas.alto;
  return NivelVagas.ok;
}

class EspecialidadeEvento {
  final String id;
  final String eventoId;
  final String nome;
  final String slug;
  final int totalVagas;
  final int vagasUtilizadas;
  final bool ativo;

  const EspecialidadeEvento({
    required this.id,
    required this.eventoId,
    required this.nome,
    required this.slug,
    required this.totalVagas,
    required this.vagasUtilizadas,
    required this.ativo,
  });

  int get vagasDisponiveis => totalVagas - vagasUtilizadas;
  bool get esgotada => totalVagas > 0 && vagasUtilizadas >= totalVagas;
  NivelVagas get nivel => nivelVagas(totalVagas, vagasUtilizadas);

  factory EspecialidadeEvento.fromJson(Map<String, dynamic> json) =>
      EspecialidadeEvento(
        id: json['id']?.toString() ?? '',
        eventoId: json['evento_id']?.toString() ?? '',
        nome: json['nome']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        totalVagas: _int(json['total_vagas']),
        vagasUtilizadas: _int(json['vagas_utilizadas']),
        ativo: json['ativo'] == null ? true : _bool(json['ativo']),
      );
}

class EventoAcaoSocial {
  final String id;
  final String nome;
  final String tag;
  final String? descricao;
  final DateTime? dataEvento;
  final String? localEvento;

  /// 'ativo' | 'finalizado' | 'cancelado'
  final String status;
  final int totalVagas;
  final int totalUtilizadas;
  final int totalEspecialidades;
  final String? registrationUrl;

  /// So' o detalhe (GET /events/{id}) traz a lista; na listagem fica vazia.
  final List<EspecialidadeEvento> especialidades;

  const EventoAcaoSocial({
    required this.id,
    required this.nome,
    required this.tag,
    this.descricao,
    this.dataEvento,
    this.localEvento,
    this.status = 'ativo',
    this.totalVagas = 0,
    this.totalUtilizadas = 0,
    this.totalEspecialidades = 0,
    this.registrationUrl,
    this.especialidades = const [],
  });

  bool get ativo => status == 'ativo';
  NivelVagas get nivel => nivelVagas(totalVagas, totalUtilizadas);

  factory EventoAcaoSocial.fromJson(Map<String, dynamic> json) {
    final rawEsp = json['especialidades'];
    final esp = rawEsp is List
        ? rawEsp
            .whereType<Map<String, dynamic>>()
            .map(EspecialidadeEvento.fromJson)
            .toList(growable: false)
        : const <EspecialidadeEvento>[];

    // No detalhe os totais podem nao vir agregados: soma das especialidades.
    final totalVagas = json['total_vagas'] != null
        ? _int(json['total_vagas'])
        : esp.fold<int>(0, (s, e) => s + e.totalVagas);
    final totalUtilizadas = json['total_utilizadas'] != null
        ? _int(json['total_utilizadas'])
        : esp.fold<int>(0, (s, e) => s + e.vagasUtilizadas);

    final dataStr = _str(json['data_evento']);
    return EventoAcaoSocial(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      tag: json['tag']?.toString() ?? '',
      descricao: _str(json['descricao']),
      dataEvento: dataStr != null ? DateTime.tryParse(dataStr)?.toLocal() : null,
      localEvento: _str(json['local_evento']),
      status: _str(json['status']) ?? 'ativo',
      totalVagas: totalVagas,
      totalUtilizadas: totalUtilizadas,
      totalEspecialidades: json['total_especialidades'] != null
          ? _int(json['total_especialidades'])
          : esp.length,
      registrationUrl: _str(json['registration_url']),
      especialidades: esp,
    );
  }
}

/// Municipe com a tag do evento (GET /cadastrados?tag=).
class Cadastrado {
  final int id;
  final String nome;
  final String? telefone;
  final String? email;
  final String? cidade;
  final String? estado;
  final DateTime? createdAt;

  const Cadastrado({
    required this.id,
    required this.nome,
    this.telefone,
    this.email,
    this.cidade,
    this.estado,
    this.createdAt,
  });

  String get localizacao =>
      [cidade, estado].where((e) => e != null && e.isNotEmpty).join('/');

  factory Cadastrado.fromJson(Map<String, dynamic> json) => Cadastrado(
        id: _int(json['id']),
        nome: json['nome']?.toString() ?? '',
        telefone: _str(json['telefone']),
        email: _str(json['email']),
        cidade: _str(json['cidade']),
        estado: _str(json['estado']),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
            : null,
      );
}

/// Atendimento = paciente x especialidade, com a ficha de anamnese.
class Atendimento {
  final String id;
  final String eventoId;
  final String especialidadeId;
  final int eleitorId;

  // Sinais vitais (texto livre no banco, VARCHAR(20))
  final String? pressaoArterial;
  final String? frequenciaCardiaca;
  final String? hgt;
  final String? peso;
  final String? altura;

  // Condicoes de saude
  final bool diabetes;
  final bool hipertensaoArterial;
  final bool tabagismo;
  final bool varizes;
  final bool epilepsia;
  final bool hipotensaoArterial;
  final bool protesesDentaria;
  final bool lesoes;
  final String? cirurgias;
  final String? observacoes;

  final bool lgpdConsentimento;
  final String? localAtendimento;
  final DateTime? dataAtendimento;
  final String? atendenteNome;

  /// 'em_atendimento' | 'concluido' | 'cancelado'
  final String status;

  // Joins
  final String? pacienteNome;
  final String? pacienteTelefone;
  final String? especialidadeNome;
  final String? especialidadeSlug;

  const Atendimento({
    required this.id,
    required this.eventoId,
    required this.especialidadeId,
    required this.eleitorId,
    this.pressaoArterial,
    this.frequenciaCardiaca,
    this.hgt,
    this.peso,
    this.altura,
    this.diabetes = false,
    this.hipertensaoArterial = false,
    this.tabagismo = false,
    this.varizes = false,
    this.epilepsia = false,
    this.hipotensaoArterial = false,
    this.protesesDentaria = false,
    this.lesoes = false,
    this.cirurgias,
    this.observacoes,
    this.lgpdConsentimento = false,
    this.localAtendimento,
    this.dataAtendimento,
    this.atendenteNome,
    this.status = 'em_atendimento',
    this.pacienteNome,
    this.pacienteTelefone,
    this.especialidadeNome,
    this.especialidadeSlug,
  });

  bool get emAtendimento => status == 'em_atendimento';
  bool get concluido => status == 'concluido';
  bool get cancelado => status == 'cancelado';

  /// Ficha ja tem algum dado clinico preenchido?
  bool get temAnamnese =>
      (pressaoArterial ?? '').isNotEmpty ||
      (frequenciaCardiaca ?? '').isNotEmpty ||
      (peso ?? '').isNotEmpty ||
      diabetes ||
      hipertensaoArterial ||
      (observacoes ?? '').isNotEmpty;

  factory Atendimento.fromJson(Map<String, dynamic> json) => Atendimento(
        id: json['id']?.toString() ?? '',
        eventoId: json['evento_id']?.toString() ?? '',
        especialidadeId: json['especialidade_id']?.toString() ?? '',
        eleitorId: _int(json['eleitor_id']),
        pressaoArterial: _str(json['pressao_arterial']),
        frequenciaCardiaca: _str(json['frequencia_cardiaca']),
        hgt: _str(json['hgt']),
        peso: _str(json['peso']),
        altura: _str(json['altura']),
        diabetes: _bool(json['diabetes']),
        hipertensaoArterial: _bool(json['hipertensao_arterial']),
        tabagismo: _bool(json['tabagismo']),
        varizes: _bool(json['varizes']),
        epilepsia: _bool(json['epilepsia']),
        hipotensaoArterial: _bool(json['hipotensao_arterial']),
        protesesDentaria: _bool(json['proteses_dentaria']),
        lesoes: _bool(json['lesoes']),
        cirurgias: _str(json['cirurgias']),
        observacoes: _str(json['observacoes']),
        lgpdConsentimento: _bool(json['lgpd_consentimento']),
        localAtendimento: _str(json['local_atendimento']),
        dataAtendimento: json['data_atendimento'] != null
            ? DateTime.tryParse(json['data_atendimento'].toString())?.toLocal()
            : null,
        atendenteNome: _str(json['atendente_nome']),
        status: _str(json['status']) ?? 'em_atendimento',
        pacienteNome: _str(json['paciente_nome']),
        pacienteTelefone: _str(json['paciente_telefone']),
        especialidadeNome: _str(json['especialidade_nome']),
        especialidadeSlug: _str(json['especialidade_slug']),
      );
}

/// Atendimentos de um mesmo paciente no evento (agrupamento da aba
/// "Atendimentos", como no painel).
class PacienteAtendimentos {
  final int eleitorId;
  final String nome;
  final String? telefone;
  final List<Atendimento> atendimentos;

  const PacienteAtendimentos({
    required this.eleitorId,
    required this.nome,
    required this.telefone,
    required this.atendimentos,
  });

  DateTime? get primeiroAtendimento => atendimentos
      .map((a) => a.dataAtendimento)
      .whereType<DateTime>()
      .fold<DateTime?>(null, (m, d) => m == null || d.isBefore(m) ? d : m);

  bool get temPendente => atendimentos.any((a) => a.emAtendimento);
  bool get todosConcluidos =>
      atendimentos.where((a) => !a.cancelado).isNotEmpty &&
      atendimentos.where((a) => !a.cancelado).every((a) => a.concluido);

  static List<PacienteAtendimentos> agrupar(List<Atendimento> lista) {
    final mapa = <int, List<Atendimento>>{};
    final ordem = <int>[];
    for (final a in lista) {
      if (!mapa.containsKey(a.eleitorId)) ordem.add(a.eleitorId);
      mapa.putIfAbsent(a.eleitorId, () => []).add(a);
    }
    return ordem.map((id) {
      final itens = mapa[id]!;
      return PacienteAtendimentos(
        eleitorId: id,
        nome: itens.first.pacienteNome ?? 'Paciente #$id',
        telefone: itens.first.pacienteTelefone,
        atendimentos: itens,
      );
    }).toList(growable: false);
  }
}

/// Retorno do POST /cadastro-presencial.
class CadastroPresencialResult {
  final int id;
  final String nome;
  final String? telefone;
  final bool isUpdate;
  final bool templateSent;

  const CadastroPresencialResult({
    required this.id,
    required this.nome,
    this.telefone,
    this.isUpdate = false,
    this.templateSent = false,
  });

  factory CadastroPresencialResult.fromJson(Map<String, dynamic> json) =>
      CadastroPresencialResult(
        id: _int(json['id']),
        nome: json['nome']?.toString() ?? '',
        telefone: _str(json['telefone']),
        isUpdate: _bool(json['isUpdate']),
        templateSent: _bool(json['templateSent']),
      );
}

/// Endereco devolvido pela consulta de CEP.
class EnderecoCep {
  final String? logradouro;
  final String? bairro;
  final String? cidade;
  final String? uf;

  const EnderecoCep({this.logradouro, this.bairro, this.cidade, this.uf});
}
