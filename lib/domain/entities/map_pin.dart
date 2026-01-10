/// Entidade que representa um ponto no mapa do GeoNexus
/// 
/// Dados da view_mapa_geral para plotagem de marcadores no Google Maps.
/// Agrega votos por candidato e local de votação.
/// 
/// Campos da view:
/// - ano_eleicao (int)
/// - nome_candidato (String)
/// - ds_cargo (String)
/// - nm_local_votacao (String)
/// - nr_latitude (double)
/// - nr_longitude (double)
/// - total_votos (int)
class MapPin {
  /// Nome do candidato
  final String nomeCandidato;
  
  /// Cargo do candidato (Prefeito, Vereador, etc)
  final String dsCargo;
  
  /// Nome do local de votação (título do marcador)
  final String nmLocalVotacao;
  
  /// Latitude do local de votação
  final double nrLatitude;
  
  /// Longitude do local de votação
  final double nrLongitude;
  
  /// Total de votos registrados no local para este candidato
  final int totalVotos;

  const MapPin({
    required this.nomeCandidato,
    required this.dsCargo,
    required this.nmLocalVotacao,
    required this.nrLatitude,
    required this.nrLongitude,
    required this.totalVotos,
  });

  /// Gera um ID único baseado no candidato, local e coordenadas
  String get uniqueId => '${nomeCandidato}_${nmLocalVotacao}_${nrLatitude}_$nrLongitude';

  @override
  String toString() {
    return 'MapPin(candidato: $nomeCandidato, local: $nmLocalVotacao, votos: $totalVotos)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapPin && 
           other.nomeCandidato == nomeCandidato &&
           other.nmLocalVotacao == nmLocalVotacao &&
           other.nrLatitude == nrLatitude &&
           other.nrLongitude == nrLongitude;
  }

  @override
  int get hashCode => Object.hash(nomeCandidato, nmLocalVotacao, nrLatitude, nrLongitude);
}
