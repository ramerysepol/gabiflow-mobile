/// Helpers de parsing defensivo para os modelos de Apuração ao vivo.
///
/// Os campos numéricos da API podem chegar como int, double ou null —
/// nunca devem derrubar a tela (um valor ausente é tratado como "sem dado",
/// não como erro).
library;

/// Converte qualquer valor numérico (int/double/String) em [num]; `null`
/// permanece `null`.
num? parseNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

/// Converte em [int], com fallback (padrão 0) quando ausente/invalido.
int parseInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    return int.tryParse(v) ?? (num.tryParse(v)?.toInt() ?? fallback);
  }
  return fallback;
}

/// Converte em `int?`, preservando `null` quando ausente/invalido.
int? parseIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// Converte em [bool], aceitando bool, "true"/"false" e 1/0.
bool parseBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return fallback;
}

/// Converte string ISO 8601 em [DateTime] local; `null` em caso de falha.
DateTime? parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v)?.toLocal();
  return null;
}

/// Converte em `String?`, nunca lança.
String? parseStringOrNull(dynamic v) => v?.toString();

/// Converte em [String] com fallback (padrão string vazia).
String parseString(dynamic v, [String fallback = '']) =>
    v?.toString() ?? fallback;

/// Converte uma lista dinâmica em `List<T>`, mapeando item a item e
/// ignorando o campo quando não é uma lista.
List<T> parseList<T>(
  dynamic v,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (v is! List) return const [];
  return v
      .whereType<Map<dynamic, dynamic>>()
      .map((e) => fromJson(Map<String, dynamic>.from(e)))
      .toList(growable: false);
}
