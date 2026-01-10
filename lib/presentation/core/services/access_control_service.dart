import '../../../domain/entities/user_profile.dart';

/// Serviço de controle de acesso baseado no plano do usuário
/// 
/// Define as regras de acesso para cada perfil:
/// - 🥉 Free (Cidadão): Visão limitada
/// - 🥈 Standard (Assessor): Operação tática
/// - 🥇 Premium (Parlamentar): Visão estratégica
class AccessControlService {
  // ============================================
  // REGRAS DE VISUALIZAÇÃO DO MAPA
  // ============================================

  /// Retorna o raio máximo de visualização do mapa (em km)
  /// 
  /// Free: Limitado a 4km do GPS
  /// Standard/Premium: Sem limite
  static double getMapRadiusKm(UserPlan plan) {
    return plan == UserPlan.free ? 4.0 : double.infinity;
  }

  /// Verifica se pode ver números absolutos de votos
  /// 
  /// Free: Vê apenas ranking (sem números)
  /// Standard/Premium: Vê números completos
  static bool canSeeAbsoluteVotes(UserPlan plan) {
    return plan != UserPlan.free;
  }

  /// Verifica se pode ver o "padrinho político" das obras
  /// 
  /// Free: Informação borrada/bloqueada
  /// Standard/Premium: Vê quem é o padrinho
  static bool canSeePadrinhoPolitico(UserPlan plan) {
    return plan != UserPlan.free;
  }

  // ============================================
  // REGRAS DE CADASTRO E EDIÇÃO
  // ============================================

  /// Verifica se pode cadastrar obras/ações
  /// 
  /// Free: Não pode
  /// Standard/Premium: Pode cadastrar
  static bool canCadastrarObra(UserPlan plan) {
    return plan == UserPlan.standard || plan == UserPlan.premium;
  }

  /// Verifica se pode gerenciar equipe (promover/rebaixar usuários)
  /// 
  /// Free/Standard: Não pode
  /// Premium: Pode gerenciar equipe
  static bool canGerenciarEquipe(UserPlan plan) {
    return plan == UserPlan.premium;
  }

  /// Verifica se pode reportar problemas (buracos, luz, etc)
  /// 
  /// Todos os perfis podem reportar
  static bool canReportarProblema(UserPlan plan) {
    return true; // Todos podem reportar
  }

  // ============================================
  // REGRAS DE VISUALIZAÇÃO REGIONAL
  // ============================================

  /// Verifica se tem acesso a todas as regiões
  /// 
  /// Free: Limitado ao raio de 4km
  /// Standard: Limitado aos bairros/zonas definidos
  /// Premium: Acesso total
  static bool canSeeAllRegions(UserPlan plan) {
    return plan == UserPlan.premium;
  }

  /// Verifica se pode ver uma região específica
  /// 
  /// Para Standard, verifica se o bairro está na lista permitida
  static bool canSeeRegion(UserProfile profile, String bairro) {
    switch (profile.plano) {
      case UserPlan.free:
        return false; // Free usa raio GPS, não bairro
      case UserPlan.standard:
        // Standard: verifica lista de bairros permitidos
        if (profile.bairrosPermitidos == null) return false;
        return profile.bairrosPermitidos!.contains(bairro);
      case UserPlan.premium:
        return true; // Premium vê tudo
    }
  }

  // ============================================
  // REGRAS DE GESTÃO
  // ============================================

  /// Verifica se pode ver relatórios dos assessores
  /// 
  /// Apenas Premium pode gerenciar equipe
  static bool canManageTeam(UserPlan plan) {
    return plan == UserPlan.premium;
  }

  /// Verifica se pode ver o "Radar de Oportunidades"
  /// (reportes de problemas feitos por usuários Free)
  /// 
  /// Free: Não vê
  /// Standard/Premium: Vê os reportes da região
  static bool canSeeRadarOportunidades(UserPlan plan) {
    return plan == UserPlan.standard || plan == UserPlan.premium;
  }

  /// Verifica se pode usar filtros avançados
  /// (ano, partido, cargo, comparação de adversários)
  /// 
  /// Apenas Premium tem filtros avançados
  static bool canUseFiltrosAvancados(UserPlan plan) {
    return plan == UserPlan.premium;
  }

  // ============================================
  // FORMATAÇÃO CONDICIONAL
  // ============================================

  /// Formata número de votos baseado no plano
  /// 
  /// Free: Retorna apenas posição (ex: "1º", "2º")
  /// Standard/Premium: Retorna número completo
  static String formatVotos(UserPlan plan, int votos, int posicao) {
    if (plan == UserPlan.free) {
      return '$posicaoº lugar';
    }
    return '$votos votos';
  }

  /// Retorna texto do padrinho ou placeholder
  static String getPadrinhoText(UserPlan plan, String? padrinho) {
    if (plan == UserPlan.free) {
      return '🔒 Disponível no plano Standard';
    }
    return padrinho ?? 'Não informado';
  }

  // ============================================
  // MENSAGENS DE UPGRADE
  // ============================================

  /// Retorna mensagem para upgrade baseado na feature tentada
  static String getUpgradeMessage(String feature) {
    return 'Para acessar "$feature", faça upgrade do seu plano.';
  }

  /// Retorna o plano mínimo necessário para uma feature
  static UserPlan getMinimumPlan(String feature) {
    switch (feature) {
      case 'votos_absolutos':
      case 'cadastrar_obra':
      case 'radar_oportunidades':
      case 'padrinho_politico':
        return UserPlan.standard;
      case 'filtros_avancados':
      case 'gestao_equipe':
      case 'todas_regioes':
        return UserPlan.premium;
      default:
        return UserPlan.free;
    }
  }
}
