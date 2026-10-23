/// Models auxiliares: sugestão da IA, opções e configuração.
library;

import 'demanda_model.dart';

Map<String, dynamic> _m(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

String? _s(dynamic v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

class DemandaSugestaoIa {
  final String titulo;
  final String resumo;
  final String area;
  final String prioridade;
  final String? canal;
  final DemandaOrgao? orgaoSugerido;
  final DemandaSaude? saude;
  final List<String> tags;

  const DemandaSugestaoIa({
    required this.titulo,
    required this.resumo,
    required this.area,
    required this.prioridade,
    this.canal,
    this.orgaoSugerido,
    this.saude,
    this.tags = const [],
  });

  factory DemandaSugestaoIa.fromJson(Map<String, dynamic> j) =>
      DemandaSugestaoIa(
        titulo: _s(j['titulo']) ?? '',
        resumo: _s(j['resumo']) ?? '',
        area: _s(j['area']) ?? 'geral',
        prioridade: _s(j['prioridade']) ?? 'media',
        canal: _s(j['canal']),
        orgaoSugerido: j['orgaoSugerido'] is Map
            ? DemandaOrgao.fromJson(_m(j['orgaoSugerido']))
            : null,
        saude: j['saude'] is Map ? DemandaSaude.fromJson(_m(j['saude'])) : null,
        tags: j['tags'] is List
            ? (j['tags'] as List).map((e) => e.toString()).toList()
            : const [],
      );
}

class DemandaOpcoes {
  final List<DemandaOrgao> orgaos;
  final List<String> especialidades;
  final List<DemandaPessoa> responsaveis;
  final List<String> bairros;

  const DemandaOpcoes({
    this.orgaos = const [],
    this.especialidades = const [],
    this.responsaveis = const [],
    this.bairros = const [],
  });

  factory DemandaOpcoes.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> l(dynamic v) => v is List
        ? v.whereType<Map<dynamic, dynamic>>().map(_m).toList()
        : const [];
    return DemandaOpcoes(
      orgaos: l(j['orgaos']).map(DemandaOrgao.fromJson).toList(),
      especialidades: j['especialidades'] is List
          ? (j['especialidades'] as List).map((e) => e.toString()).toList()
          : const [],
      responsaveis: l(j['responsaveis']).map(DemandaPessoa.fromJson).toList(),
      bairros: j['bairros'] is List
          ? (j['bairros'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }
}

/// Prazos (SLA) em dias, vindos de `demanda_config`. Aceita snake_case ou
/// camelCase (o contrato só diz "config").
class DemandaConfig {
  final Map<String, int> slaDias;
  final Map<String, int> slaSaudeDias;

  const DemandaConfig({
    this.slaDias = const {'baixa': 30, 'media': 15, 'alta': 7, 'urgente': 2},
    this.slaSaudeDias = const {'eletiva': 20, 'prioritaria': 7, 'urgente': 1},
  });

  factory DemandaConfig.fromJson(Map<String, dynamic> j) {
    Map<String, int> mi(dynamic v, Map<String, int> padrao) {
      final m = _m(v);
      if (m.isEmpty) return padrao;
      return {
        for (final e in m.entries)
          e.key: (e.value is num)
              ? (e.value as num).toInt()
              : int.tryParse('${e.value}') ?? 0,
      };
    }

    const d = DemandaConfig();
    return DemandaConfig(
      slaDias: mi(j['sla_dias'] ?? j['slaDias'], d.slaDias),
      slaSaudeDias: mi(
        j['sla_saude_dias'] ?? j['slaSaudeDias'],
        d.slaSaudeDias,
      ),
    );
  }

  /// Dias de prazo para a combinação área/prioridade/urgência.
  int diasPara({
    required String area,
    required String prioridade,
    required String urgenciaClinica,
  }) => area == 'saude'
      ? (slaSaudeDias[urgenciaClinica] ?? 20)
      : (slaDias[prioridade] ?? 15);
}

/// Filtros da Mesa.
class DemandaFiltros {
  final String? status;
  final String? prioridade;
  final String? area;
  final bool minhas;
  final bool atrasadas;
  final bool venceHoje;
  final int? aguardandoHa;
  final String busca;

  const DemandaFiltros({
    this.status,
    this.prioridade,
    this.area,
    this.minhas = false,
    this.atrasadas = false,
    this.venceHoje = false,
    this.aguardandoHa,
    this.busca = '',
  });

  /// Quantos filtros além de status/busca estão ativos (badge do botão).
  int get ativos =>
      (prioridade != null ? 1 : 0) +
      (area != null ? 1 : 0) +
      (minhas ? 1 : 0) +
      (atrasadas ? 1 : 0) +
      (venceHoje ? 1 : 0) +
      (aguardandoHa != null ? 1 : 0);

  DemandaFiltros copyWith({
    String? Function()? status,
    String? Function()? prioridade,
    String? Function()? area,
    bool? minhas,
    bool? atrasadas,
    bool? venceHoje,
    int? Function()? aguardandoHa,
    String? busca,
  }) => DemandaFiltros(
    status: status != null ? status() : this.status,
    prioridade: prioridade != null ? prioridade() : this.prioridade,
    area: area != null ? area() : this.area,
    minhas: minhas ?? this.minhas,
    atrasadas: atrasadas ?? this.atrasadas,
    venceHoje: venceHoje ?? this.venceHoje,
    aguardandoHa: aguardandoHa != null ? aguardandoHa() : this.aguardandoHa,
    busca: busca ?? this.busca,
  );

  /// Limpa tudo menos a aba (status) e a busca.
  DemandaFiltros semRapidos() => DemandaFiltros(status: status, busca: busca);

  Map<String, dynamic> toQuery() => {
    if (status != null) ...{
      'status': status,
      'status[]': [status],
    },
    if (prioridade != null) ...{
      'prioridade': prioridade,
      'prioridade[]': [prioridade],
    },
    if (area != null) 'area': area,
    if (minhas) 'responsavel': 'me',
    if (atrasadas) 'atrasadas': 1,
    if (venceHoje) 'venceHoje': 1,
    if (aguardandoHa != null) 'aguardandoHa': aguardandoHa,
    if (busca.trim().isNotEmpty) 'q': busca.trim(),
  };
}
