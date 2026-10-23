// Models da Mesa de Demandas 2.0 (Spec §4.1). Sem geração de código.

int _int(dynamic v, [int padrao = 0]) =>
    v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? padrao;

int? _intOrNull(dynamic v) =>
    v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _lista(dynamic v) => v is List
    ? v
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList()
    : const [];

/// "2026-11-07" ou "2026-11-07T00:00:00.000Z" -> data local (sem fuso).
DateTime? parseData(String? s) {
  if (s == null || s.length < 10) return null;
  final p = s.substring(0, 10).split('-');
  if (p.length != 3) return null;
  final a = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (a == null || m == null || d == null) return null;
  return DateTime(a, m, d);
}

class DemandaMunicipe {
  final int id;
  final String nome;
  final String? telefone;
  final String? bairro;

  const DemandaMunicipe({
    required this.id,
    required this.nome,
    this.telefone,
    this.bairro,
  });

  factory DemandaMunicipe.fromJson(Map<String, dynamic> j) => DemandaMunicipe(
    id: _int(j['id']),
    nome: _str(j['nome']) ?? 'Munícipe',
    telefone: _str(j['telefone']),
    bairro: _str(j['bairro']),
  );
}

class DemandaPessoa {
  final int id;
  final String nome;
  const DemandaPessoa({required this.id, required this.nome});

  factory DemandaPessoa.fromJson(Map<String, dynamic> j) =>
      DemandaPessoa(id: _int(j['id']), nome: _str(j['nome']) ?? '—');
}

class DemandaOrgao {
  final int? id;
  final String nome;
  const DemandaOrgao({this.id, required this.nome});

  factory DemandaOrgao.fromJson(Map<String, dynamic> j) =>
      DemandaOrgao(id: _intOrNull(j['id']), nome: _str(j['nome']) ?? '—');
}

class DemandaSaude {
  final String tipoPedido;
  final String? especialidade;
  final String urgenciaClinica;
  final String? pacienteNome;
  final String? pacienteParentesco;
  final String? pacienteNascimento;
  final String? cartaoSus;
  final String? unidadeSaude;
  final String? observacoesClinicas;

  const DemandaSaude({
    required this.tipoPedido,
    this.especialidade,
    required this.urgenciaClinica,
    this.pacienteNome,
    this.pacienteParentesco,
    this.pacienteNascimento,
    this.cartaoSus,
    this.unidadeSaude,
    this.observacoesClinicas,
  });

  factory DemandaSaude.fromJson(Map<String, dynamic> j) => DemandaSaude(
    tipoPedido: _str(j['tipoPedido']) ?? 'outro',
    especialidade: _str(j['especialidade']),
    urgenciaClinica: _str(j['urgenciaClinica']) ?? 'eletiva',
    pacienteNome: _str(j['pacienteNome']),
    pacienteParentesco: _str(j['pacienteParentesco']),
    pacienteNascimento: _str(j['pacienteNascimento']),
    cartaoSus: _str(j['cartaoSus']),
    unidadeSaude: _str(j['unidadeSaude']),
    observacoesClinicas: _str(j['observacoesClinicas']),
  );
}

class DemandaUltimoEvento {
  final String tipo;
  final String descricao;
  final String? em;
  const DemandaUltimoEvento({
    required this.tipo,
    required this.descricao,
    this.em,
  });
}

class DemandaResumo {
  final int id;
  final String protocolo;
  final String titulo;
  final String area;
  final String status;
  final String prioridade;
  final String canal;
  final String? prazo;
  final int? diasRestantes;
  final bool atrasada;
  final DemandaMunicipe? municipe;
  final DemandaPessoa? responsavel;
  final DemandaOrgao? orgao;
  final DemandaSaude? saude;
  final DemandaUltimoEvento? ultimoEvento;
  final List<String> tags;
  final String? createdAt;
  final String? updatedAt;

  const DemandaResumo({
    required this.id,
    required this.protocolo,
    required this.titulo,
    required this.area,
    required this.status,
    required this.prioridade,
    required this.canal,
    this.prazo,
    this.diasRestantes,
    this.atrasada = false,
    this.municipe,
    this.responsavel,
    this.orgao,
    this.saude,
    this.ultimoEvento,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get ehSaude => area == 'saude';
  bool get encerrada => status == 'concluida' || status == 'cancelada';

  factory DemandaResumo.fromJson(Map<String, dynamic> j) {
    final ue = j['ultimoEvento'];
    return DemandaResumo(
      id: _int(j['id']),
      protocolo: _str(j['protocolo']) ?? '#${_int(j['id'])}',
      titulo: _str(j['titulo']) ?? 'Sem título',
      area: _str(j['area']) ?? 'geral',
      status: _str(j['status']) ?? 'nova',
      prioridade: _str(j['prioridade']) ?? 'media',
      canal: _str(j['canal']) ?? 'outro',
      prazo: _str(j['prazo']),
      diasRestantes: _intOrNull(j['diasRestantes']),
      atrasada: j['atrasada'] == true,
      municipe: j['municipe'] is Map
          ? DemandaMunicipe.fromJson(_map(j['municipe']))
          : null,
      responsavel: j['responsavel'] is Map
          ? DemandaPessoa.fromJson(_map(j['responsavel']))
          : null,
      orgao: j['orgao'] is Map ? DemandaOrgao.fromJson(_map(j['orgao'])) : null,
      saude: j['saude'] is Map ? DemandaSaude.fromJson(_map(j['saude'])) : null,
      ultimoEvento: ue is Map
          ? DemandaUltimoEvento(
              tipo: _str(ue['tipo']) ?? '',
              descricao: _str(ue['descricao']) ?? '',
              em: _str(ue['em']),
            )
          : null,
      tags: (j['tags'] is List)
          ? (j['tags'] as List).map((e) => e.toString()).toList()
          : const [],
      createdAt: _str(j['createdAt']),
      updatedAt: _str(j['updatedAt']),
    );
  }
}

class DemandaEvento {
  final int id;
  final String tipo;
  final String descricao;
  final Map<String, dynamic> dados;
  final DemandaPessoa? user;
  final bool visivelMunicipe;
  final String? createdAt;

  const DemandaEvento({
    required this.id,
    required this.tipo,
    required this.descricao,
    this.dados = const {},
    this.user,
    this.visivelMunicipe = false,
    this.createdAt,
  });

  factory DemandaEvento.fromJson(Map<String, dynamic> j) => DemandaEvento(
    id: _int(j['id']),
    tipo: _str(j['tipo']) ?? '',
    descricao: _str(j['descricao']) ?? '',
    dados: _map(j['dados']),
    user: j['user'] is Map ? DemandaPessoa.fromJson(_map(j['user'])) : null,
    visivelMunicipe: j['visivelMunicipe'] == true,
    createdAt: _str(j['createdAt']),
  );
}

class DemandaAnexo {
  final int id;
  final String tipo;
  final String nomeOriginal;
  final String? mime;
  final int? tamanho;
  final DemandaPessoa? uploadedBy;
  final String? createdAt;

  const DemandaAnexo({
    required this.id,
    required this.tipo,
    required this.nomeOriginal,
    this.mime,
    this.tamanho,
    this.uploadedBy,
    this.createdAt,
  });

  bool get ehImagem => (mime ?? '').startsWith('image/');

  factory DemandaAnexo.fromJson(Map<String, dynamic> j) => DemandaAnexo(
    id: _int(j['id']),
    tipo: _str(j['tipo']) ?? 'anexo',
    nomeOriginal: _str(j['nomeOriginal']) ?? 'arquivo',
    mime: _str(j['mime']),
    tamanho: _intOrNull(j['tamanho']),
    uploadedBy: j['uploadedBy'] is Map
        ? DemandaPessoa.fromJson(_map(j['uploadedBy']))
        : null,
    createdAt: _str(j['createdAt']),
  );
}

class DemandaEncaminhamento {
  final int id;
  final DemandaOrgao orgao;
  final String? oficioNumero;
  final String? enviadoEm;
  final String? prazoResposta;
  final String? respostaEm;
  final String? respostaTexto;
  final String status;

  const DemandaEncaminhamento({
    required this.id,
    required this.orgao,
    this.oficioNumero,
    this.enviadoEm,
    this.prazoResposta,
    this.respostaEm,
    this.respostaTexto,
    required this.status,
  });

  factory DemandaEncaminhamento.fromJson(Map<String, dynamic> j) {
    final of = j['oficio'] is Map ? _map(j['oficio']) : null;
    return DemandaEncaminhamento(
      id: _int(j['id']),
      orgao: DemandaOrgao.fromJson(_map(j['orgao'])),
      oficioNumero: _str(of?['numero']),
      enviadoEm: _str(j['enviadoEm']),
      prazoResposta: _str(j['prazoResposta']),
      respostaEm: _str(j['respostaEm']),
      respostaTexto: _str(j['respostaTexto']),
      status: _str(j['status']) ?? 'enviado',
    );
  }
}

class DemandaDetalhe extends DemandaResumo {
  final String descricao;
  final String? observacoes;
  final String? resumoIa;
  final String? bairro;
  final String? dataSolicitacao;
  final String? dataConclusao;
  final int? conversationId;
  final List<DemandaEvento> eventos;
  final List<DemandaAnexo> anexos;
  final List<DemandaEncaminhamento> encaminhamentos;
  final List<String> vinculos;

  const DemandaDetalhe({
    required super.id,
    required super.protocolo,
    required super.titulo,
    required super.area,
    required super.status,
    required super.prioridade,
    required super.canal,
    super.prazo,
    super.diasRestantes,
    super.atrasada,
    super.municipe,
    super.responsavel,
    super.orgao,
    super.saude,
    super.ultimoEvento,
    super.tags,
    super.createdAt,
    super.updatedAt,
    required this.descricao,
    this.observacoes,
    this.resumoIa,
    this.bairro,
    this.dataSolicitacao,
    this.dataConclusao,
    this.conversationId,
    this.eventos = const [],
    this.anexos = const [],
    this.encaminhamentos = const [],
    this.vinculos = const [],
  });

  factory DemandaDetalhe.fromJson(Map<String, dynamic> j) {
    final b = DemandaResumo.fromJson(j);
    final v = _map(j['vinculos']);
    return DemandaDetalhe(
      id: b.id,
      protocolo: b.protocolo,
      titulo: b.titulo,
      area: b.area,
      status: b.status,
      prioridade: b.prioridade,
      canal: b.canal,
      prazo: b.prazo,
      diasRestantes: b.diasRestantes,
      atrasada: b.atrasada,
      municipe: b.municipe,
      responsavel: b.responsavel,
      orgao: b.orgao,
      saude: b.saude,
      ultimoEvento: b.ultimoEvento,
      tags: b.tags,
      createdAt: b.createdAt,
      updatedAt: b.updatedAt,
      descricao: _str(j['descricao']) ?? '',
      observacoes: _str(j['observacoes']),
      resumoIa: _str(j['resumoIa']),
      bairro: _str(j['bairro']),
      dataSolicitacao: _str(j['dataSolicitacao']),
      dataConclusao: _str(j['dataConclusao']),
      conversationId: _intOrNull(j['conversationId']),
      eventos: _lista(j['eventos']).map(DemandaEvento.fromJson).toList(),
      anexos: _lista(j['anexos']).map(DemandaAnexo.fromJson).toList(),
      encaminhamentos: _lista(
        j['encaminhamentos'],
      ).map(DemandaEncaminhamento.fromJson).toList(),
      vinculos: [
        for (final o in _lista(v['oficios']))
          'Ofício ${_str(o['numero']) ?? '#${o['id']}'}'
              '${_str(o['assunto']) != null ? ' — ${o['assunto']}' : ''}',
        for (final p in _lista(v['proposicoes']))
          'Proposição ${_str(p['titulo']) ?? '#${p['id']}'}',
      ],
    );
  }
}

class DemandaContadores {
  final Map<String, int> porStatus;
  final int atrasadas;
  final int venceHoje;
  final int saude;
  final int? saudeUrgentes;
  final int geral;

  const DemandaContadores({
    this.porStatus = const {},
    this.atrasadas = 0,
    this.venceHoje = 0,
    this.saude = 0,
    this.saudeUrgentes,
    this.geral = 0,
  });

  int status(String s) => porStatus[s] ?? 0;

  factory DemandaContadores.fromJson(Map<String, dynamic> j) {
    final ps = _map(j['porStatus']);
    return DemandaContadores(
      porStatus: {for (final e in ps.entries) e.key: _int(e.value)},
      atrasadas: _int(j['atrasadas']),
      venceHoje: _int(j['venceHoje']),
      saude: _int(j['saude']),
      saudeUrgentes: _intOrNull(j['saudeUrgentes']),
      geral: _int(j['geral']),
    );
  }
}

class DemandaListaResposta {
  final List<DemandaResumo> items;
  final int total;
  final int page;
  final int limit;
  final DemandaContadores contadores;

  const DemandaListaResposta({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.contadores,
  });

  bool get temMais => page * limit < total;

  factory DemandaListaResposta.fromJson(Map<String, dynamic> j) =>
      DemandaListaResposta(
        items: _lista(j['items']).map(DemandaResumo.fromJson).toList(),
        total: _int(j['total']),
        page: _int(j['page'], 1),
        limit: _int(j['limit'], 20),
        contadores: DemandaContadores.fromJson(_map(j['contadores'])),
      );
}
