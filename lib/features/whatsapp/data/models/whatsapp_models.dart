/// Modelos do módulo de envio WhatsApp (paridade com o desktop).
library;

class WhatsAppConfig {
  final bool meta;
  final bool zapi;
  final String? providerDefault;

  const WhatsAppConfig({
    required this.meta,
    required this.zapi,
    this.providerDefault,
  });

  bool get algumAtivo => meta || zapi;

  factory WhatsAppConfig.fromJson(Map<String, dynamic> json) => WhatsAppConfig(
        meta: json['meta'] == true,
        zapi: json['zapi'] == true,
        providerDefault: json['provider_default'] as String?,
      );
}

/// Template Meta aprovado (variáveis numéricas {{1}}, {{2}}…).
class MetaTemplate {
  final int id;
  final String nome;
  final String templateName;
  final String language;
  final String? categoria;
  final String texto;
  final List<String> variaveis;
  final bool requerMidia;

  const MetaTemplate({
    required this.id,
    required this.nome,
    required this.templateName,
    required this.language,
    this.categoria,
    required this.texto,
    required this.variaveis,
    required this.requerMidia,
  });

  factory MetaTemplate.fromJson(Map<String, dynamic> json) => MetaTemplate(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nome: json['nome']?.toString() ?? '',
        templateName: json['template_name']?.toString() ?? '',
        language: json['language']?.toString() ?? 'pt_BR',
        categoria: json['categoria']?.toString(),
        texto: json['texto']?.toString() ?? '',
        variaveis: (json['variaveis'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        requerMidia: json['requer_midia'] == true,
      );
}

/// Template local/Z-API (variáveis nomeadas {{nome}}, {{cidade}}…).
class LocalTemplate {
  final int id;
  final String titulo;
  final String texto;
  final String? descricao;
  final List<String> variaveis;
  final bool temAnexo;

  const LocalTemplate({
    required this.id,
    required this.titulo,
    required this.texto,
    this.descricao,
    required this.variaveis,
    required this.temAnexo,
  });

  factory LocalTemplate.fromJson(Map<String, dynamic> json) => LocalTemplate(
        id: (json['id'] as num?)?.toInt() ?? 0,
        titulo: json['titulo']?.toString() ?? '',
        texto: json['texto']?.toString() ?? '',
        descricao: json['descricao']?.toString(),
        variaveis: (json['variaveis'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        temAnexo: json['tem_anexo'] == true,
      );
}

class WhatsAppTemplates {
  final List<MetaTemplate> meta;
  final List<LocalTemplate> local;

  const WhatsAppTemplates({required this.meta, required this.local});

  factory WhatsAppTemplates.fromJson(Map<String, dynamic> json) =>
      WhatsAppTemplates(
        meta: (json['meta'] as List? ?? [])
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => MetaTemplate.fromJson(e.cast<String, dynamic>()))
            .toList(),
        local: (json['local'] as List? ?? [])
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => LocalTemplate.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

/// Campos disponíveis para mapear variáveis (paridade com o desktop).
const camposVariavel = <(String, String)>[
  ('primeiro_nome', 'Primeiro nome'),
  ('nome_completo', 'Nome completo'),
  ('telefone', 'Telefone'),
  ('email', 'E-mail'),
  ('cidade', 'Cidade'),
  ('estado', 'Estado'),
  ('bairro', 'Bairro'),
  ('data_hoje', 'Data de hoje'),
  ('dia', 'Dia'),
  ('mes', 'Mês'),
  ('ano', 'Ano'),
];

/// Mapeamento de uma variável do template: campo do munícipe ou texto fixo.
class MapeamentoVariavel {
  final String tipo; // 'campo' | 'fixo'
  final String valor;

  const MapeamentoVariavel.campo(this.valor) : tipo = 'campo';
  const MapeamentoVariavel.fixo(this.valor) : tipo = 'fixo';

  Map<String, dynamic> toJson() => {'tipo': tipo, 'valor': valor};
}

/// Status/progresso de uma campanha de envio.
class CampanhaStatus {
  final int id;
  final String nome;
  final String status;
  final int totalDestinatarios;
  final int totalEnviados;
  final int totalErros;

  const CampanhaStatus({
    required this.id,
    required this.nome,
    required this.status,
    required this.totalDestinatarios,
    required this.totalEnviados,
    required this.totalErros,
  });

  bool get concluida => status != 'em_andamento';
  double get progresso => totalDestinatarios == 0
      ? 0
      : (totalEnviados + totalErros) / totalDestinatarios;

  factory CampanhaStatus.fromJson(Map<String, dynamic> json) => CampanhaStatus(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nome: json['nome']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        totalDestinatarios:
            (json['total_destinatarios'] as num?)?.toInt() ?? 0,
        totalEnviados: (json['total_enviados'] as num?)?.toInt() ?? 0,
        totalErros: (json['total_erros'] as num?)?.toInt() ?? 0,
      );
}
