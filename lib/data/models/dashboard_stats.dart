/// Model para os KPIs do Dashboard
/// 
/// Dados retornados pela RPC `get_dashboard_kpis`.
class DashboardStats {
  /// Total de votos na região/período selecionado
  final int totalVotos;

  /// Nome do bairro com mais votos
  final String? melhorBairro;

  /// Total de votos no melhor bairro
  final int? votosMelhorBairro;

  /// Total de obras cadastradas
  final int totalObras;

  /// Obras com status pendente
  final int obrasPendentes;

  /// Obras com status em andamento
  final int obrasEmAndamento;

  /// Obras concluídas
  final int obrasConcluidas;

  /// Obras canceladas
  final int obrasCanceladas;

  const DashboardStats({
    this.totalVotos = 0,
    this.melhorBairro,
    this.votosMelhorBairro,
    this.totalObras = 0,
    this.obrasPendentes = 0,
    this.obrasEmAndamento = 0,
    this.obrasConcluidas = 0,
    this.obrasCanceladas = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalVotos: json['total_votos'] as int? ?? 0,
      melhorBairro: json['melhor_bairro'] as String?,
      votosMelhorBairro: json['votos_melhor_bairro'] as int?,
      totalObras: json['total_obras'] as int? ?? 0,
      obrasPendentes: json['obras_pendentes'] as int? ?? 0,
      obrasEmAndamento: json['obras_em_andamento'] as int? ?? 0,
      obrasConcluidas: json['obras_concluidas'] as int? ?? 0,
      obrasCanceladas: json['obras_canceladas'] as int? ?? 0,
    );
  }

  /// Retorna uma instância vazia (para loading/erro)
  factory DashboardStats.empty() => const DashboardStats();

  @override
  String toString() {
    return 'DashboardStats(votos: $totalVotos, obras: $totalObras)';
  }
}
