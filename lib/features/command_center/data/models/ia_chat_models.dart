/// Modelos do chat streaming do Command Center IA.
/// Espelham os ChatEvent do backend (lib/ai/eleitoral-ia/types.ts):
/// thinking | tool_use | tool_result | text_delta | visualization | done | error
library;

/// Evento bruto recebido via SSE.
class IaChatEvent {
  final String type;
  final Map<String, dynamic> raw;

  const IaChatEvent({required this.type, required this.raw});

  factory IaChatEvent.fromJson(Map<String, dynamic> json) {
    return IaChatEvent(type: json['type'] as String? ?? '', raw: json);
  }

  String get message => raw['message'] as String? ?? '';
  String get text => raw['text'] as String? ?? '';
  String get tool => raw['tool'] as String? ?? '';
  String get toolUseId => raw['tool_use_id'] as String? ?? '';
  int? get rowsCount => (raw['rows_count'] as num?)?.toInt();
  String get vizKind => raw['kind'] as String? ?? '';
  dynamic get vizData => raw['data'];
}

/// Atividade de tool exibida no chat ("Consultando votos por município...").
class IaToolActivity {
  final String toolUseId;
  final String tool;
  final bool done;
  final int? rowsCount;

  const IaToolActivity({
    required this.toolUseId,
    required this.tool,
    this.done = false,
    this.rowsCount,
  });

  IaToolActivity complete({int? rowsCount}) => IaToolActivity(
        toolUseId: toolUseId,
        tool: tool,
        done: true,
        rowsCount: rowsCount,
      );

  /// Nome amigável da tool para exibição.
  String get label {
    switch (tool) {
      case 'info_candidato':
        return 'Consultando dados do candidato';
      case 'votos_por_municipio':
        return 'Levantando votos por município';
      case 'municipios_sem_voto':
        return 'Verificando municípios sem voto';
      case 'ranking_adversarios':
        return 'Comparando com adversários';
      case 'votos_em_municipio':
        return 'Analisando município específico';
      case 'buscar_candidatos_por_nome':
        return 'Buscando candidatos';
      case 'dados_ibge_municipio':
        return 'Consultando dados IBGE';
      case 'agregar_votos_por_mesorregiao':
        return 'Agregando por mesorregião';
      case 'resumo_gabinete':
        return 'Consultando dados do gabinete';
      case 'cruzar_votos_com_gabinete':
        return 'Cruzando votos × gabinete';
      case 'sentimento_whatsapp':
        return 'Analisando WhatsApp';
      default:
        return tool.replaceAll('_', ' ');
    }
  }
}

/// Visualização inline gerada por uma tool.
class IaVisualization {
  final String kind;
  final dynamic data;

  const IaVisualization({required this.kind, required this.data});
}

/// Uma mensagem da conversa (usuário ou assistente).
class IaChatMessage {
  final String role; // user | assistant
  final String text;
  final List<IaToolActivity> tools;
  final List<IaVisualization> visualizations;
  final bool isStreaming;
  final String? thinkingLabel;
  final String? error;

  const IaChatMessage({
    required this.role,
    this.text = '',
    this.tools = const [],
    this.visualizations = const [],
    this.isStreaming = false,
    this.thinkingLabel,
    this.error,
  });

  IaChatMessage copyWith({
    String? text,
    List<IaToolActivity>? tools,
    List<IaVisualization>? visualizations,
    bool? isStreaming,
    String? thinkingLabel,
    bool clearThinking = false,
    String? error,
  }) {
    return IaChatMessage(
      role: role,
      text: text ?? this.text,
      tools: tools ?? this.tools,
      visualizations: visualizations ?? this.visualizations,
      isStreaming: isStreaming ?? this.isStreaming,
      thinkingLabel: clearThinking ? null : (thinkingLabel ?? this.thinkingLabel),
      error: error ?? this.error,
    );
  }
}
