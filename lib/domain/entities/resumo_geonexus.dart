/// Entidade que representa dados do mapa geral do GeoNexus
/// 
/// Dados otimizados da tabela resumo_geonexus_rj para
/// plotagem de marcadores no Google Maps.
/// Agrega votos por local de votação para melhor performance.
/// 
/// NOTA (2026-01-06): Colunas sg_uf e nm_bairro foram removidas do banco.
class ResumoGeonexus {
  /// ID único do registro (id do local_votacao)
  final int id;
  
  /// Latitude do local de votação
  final double nrLatitude;
  
  /// Longitude do local de votação
  final double nrLongitude;
  
  /// Nome do local de votação (título do marcador)
  final String nmLocalVotacao;
  
  /// Nome do município
  final String? nmMunicipio;
  
  /// Total de votos registrados no local
  final int totalVotos;
  
  /// Quantidade de seções eleitorais no local
  final int totalSecoes;

  const ResumoGeonexus({
    required this.id,
    required this.nrLatitude,
    required this.nrLongitude,
    required this.nmLocalVotacao,
    this.nmMunicipio,
    required this.totalVotos,
    this.totalSecoes = 0,
  });

  @override
  String toString() {
    return 'ResumoGeonexus(id: $id, local: $nmLocalVotacao, votos: $totalVotos)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResumoGeonexus && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
