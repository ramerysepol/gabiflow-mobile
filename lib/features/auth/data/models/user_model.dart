import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

// Helper function para converter id para int
int _parseId(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.parse(value);
  return 0;
}

@freezed
class UserModel with _$UserModel {
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
    Map<String, dynamic>? permissions,
    Map<String, dynamic>? preferences,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}