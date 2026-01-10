import 'package:dartz/dartz.dart';

/// Planos de usuário do GeoNexus
/// 
/// Cada plano oferece diferentes níveis de acesso:
/// - free: Cidadão (visualização limitada)
/// - standard: Assessor (operação tática)
/// - premium: Parlamentar (visão estratégica)
enum UserPlan {
  free,
  standard,
  premium;

  /// Converte string do banco para enum
  static UserPlan fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'standard':
        return UserPlan.standard;
      case 'premium':
        return UserPlan.premium;
      default:
        return UserPlan.free;
    }
  }

  /// Retorna nome amigável do plano
  String get displayName {
    switch (this) {
      case UserPlan.free:
        return 'Cidadão';
      case UserPlan.standard:
        return 'Assessor';
      case UserPlan.premium:
        return 'Parlamentar';
    }
  }

  /// Retorna ícone do plano
  String get emoji {
    switch (this) {
      case UserPlan.free:
        return '🥉';
      case UserPlan.standard:
        return '🥈';
      case UserPlan.premium:
        return '🥇';
    }
  }
}

/// Perfil do usuário no GeoNexus
/// 
/// Representa os dados do usuário armazenados na tabela `profiles`.
class UserProfile {
  /// ID do usuário (UUID do Supabase Auth)
  final String id;
  
  /// Nome completo do usuário
  final String nome;
  
  /// Email do usuário (do Auth)
  final String? email;
  
  /// CPF do usuário (opcional)
  final String? cpf;
  
  /// Telefone do usuário (opcional)
  final String? telefone;
  
  /// Plano do usuário (free, standard, premium)
  final UserPlan plano;
  
  /// Bairros permitidos para perfil Standard
  final List<String>? bairrosPermitidos;
  
  /// Data de criação do perfil
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.nome,
    this.email,
    this.cpf,
    this.telefone,
    this.plano = UserPlan.free,
    this.bairrosPermitidos,
    this.createdAt,
  });

  /// Verifica se é perfil Free
  bool get isFree => plano == UserPlan.free;
  
  /// Verifica se é perfil Standard ou superior
  bool get isStandardOrAbove => plano == UserPlan.standard || plano == UserPlan.premium;
  
  /// Verifica se é perfil Premium
  bool get isPremium => plano == UserPlan.premium;

  @override
  String toString() {
    return 'UserProfile(id: $id, nome: $nome, plano: ${plano.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
