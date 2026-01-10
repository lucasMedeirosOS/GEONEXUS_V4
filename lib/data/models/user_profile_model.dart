import '../../domain/entities/user_profile.dart';

/// Model para converter dados do Supabase em UserProfile
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.nome,
    super.email,
    super.cpf,
    super.telefone,
    super.plano = UserPlan.free,
    super.bairrosPermitidos,
    super.createdAt,
  });

  /// Cria UserProfileModel a partir de JSON do Supabase
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Extrai bairros permitidos (pode ser array ou null)
    List<String>? bairros;
    if (json['bairros_permitidos'] != null) {
      bairros = (json['bairros_permitidos'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return UserProfileModel(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? 'Usuário',
      email: json['email'] as String?,
      cpf: json['cpf'] as String?,
      telefone: json['telefone'] as String?,
      plano: UserPlan.fromString(json['plano'] as String?),
      bairrosPermitidos: bairros,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Converte para JSON (para updates)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'telefone': telefone,
      'plano': plano.name,
      'bairros_permitidos': bairrosPermitidos,
    };
  }

  /// Cria uma cópia com campos alterados
  UserProfileModel copyWith({
    String? id,
    String? nome,
    String? email,
    String? cpf,
    String? telefone,
    UserPlan? plano,
    List<String>? bairrosPermitidos,
    DateTime? createdAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      cpf: cpf ?? this.cpf,
      telefone: telefone ?? this.telefone,
      plano: plano ?? this.plano,
      bairrosPermitidos: bairrosPermitidos ?? this.bairrosPermitidos,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
