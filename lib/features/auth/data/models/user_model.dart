import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

// Helper function para converter id para int
int _parseId(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.parse(value);
  return 0;
}

/// Permissoes efetivas vindas de /auth/login e /auth/me, no formato
/// `modulo:acao` (ex.: `schedule:create`). Sao as MESMAS que o servidor aplica
/// em cada rota — aqui servem so' para a tela nao oferecer o que vai ser
/// recusado.
///
/// Aceita Map por tolerancia: o campo existia tipado assim antes de a API
/// passar a devolver lista, e um app antigo lendo uma resposta nova (ou o
/// contrario) nao pode quebrar no login.
List<String> _parsePermissions(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  if (value is Map) {
    return value.keys.map((e) => e.toString()).toList();
  }
  return const <String>[];
}

/// A API pode devolver `preferences` como objeto, lista vazia (Postgres) ou
/// null — só interessa quando for objeto.
Map<String, dynamic>? _parsePreferences(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    @JsonKey(fromJson: _parseId) required int id,
    required String name,
    required String email,
    required String role,
    String? avatar,
    String? tenant,
    
    // Campos opcionais que podem vir da API
    String? telefone,
    String? cpf,
    @JsonKey(name: 'tenant_id') String? tenantId,
    @JsonKey(name: 'is_active') bool? isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(fromJson: _parsePermissions)
    @Default(<String>[])
    List<String> permissions,
    @JsonKey(fromJson: _parsePreferences) Map<String, dynamic>? preferences,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}