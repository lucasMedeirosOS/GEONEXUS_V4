import '../../domain/entities/user_profile.dart';

/// Modelo para estatísticas de membro da equipe
class TeamMember {
  /// ID do usuário
  final String id;

  /// Nome do usuário
  final String nome;

  /// Email
  final String email;

  /// Plano atual
  final UserPlan plano;

  /// Quantidade de obras cadastradas
  final int obrasCadastradas;

  /// Data do último acesso
  final DateTime? ultimoAcesso;

  /// Data de criação do perfil
  final DateTime? criadoEm;

  const TeamMember({
    required this.id,
    required this.nome,
    required this.email,
    required this.plano,
    this.obrasCadastradas = 0,
    this.ultimoAcesso,
    this.criadoEm,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? 'Sem nome',
      email: json['email'] as String? ?? '',
      plano: parsePlano(json['plano'] as String?),
      obrasCadastradas: json['obras_cadastradas'] as int? ?? 0,
      ultimoAcesso: json['ultimo_acesso'] != null
          ? DateTime.tryParse(json['ultimo_acesso'] as String)
          : null,
      criadoEm: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  static UserPlan parsePlano(String? plano) {
    switch (plano?.toLowerCase()) {
      case 'premium':
        return UserPlan.premium;
      case 'standard':
        return UserPlan.standard;
      default:
        return UserPlan.free;
    }
  }

  /// Retorna tempo desde o último acesso formatado
  String get ultimoAcessoFormatado {
    if (ultimoAcesso == null) return 'Nunca acessou';

    final diff = DateTime.now().difference(ultimoAcesso!);

    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours} horas';
    if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
    return 'Há ${(diff.inDays / 7).floor()} semanas';
  }
}
