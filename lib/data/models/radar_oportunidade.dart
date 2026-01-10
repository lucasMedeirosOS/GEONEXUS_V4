/// Modelo para oportunidades do Radar
/// 
/// Representa locais onde o candidato tem baixa votação
/// comparado ao total, indicando oportunidade de crescimento.
class RadarOportunidade {
  /// ID único
  final String id;

  /// Nome do local de votação
  final String nmLocalVotacao;

  /// Bairro
  final String? nmBairro;

  /// Latitude
  final double nrLatitude;

  /// Longitude
  final double nrLongitude;

  /// Total de votos do candidato buscado neste local
  final int votosCandidato;

  /// Total de votos de TODOS neste local
  final int votosTotal;

  /// Percentual do candidato neste local
  final double percentual;

  /// Posição no ranking local
  final int? posicaoRanking;

  const RadarOportunidade({
    required this.id,
    required this.nmLocalVotacao,
    this.nmBairro,
    required this.nrLatitude,
    required this.nrLongitude,
    required this.votosCandidato,
    required this.votosTotal,
    required this.percentual,
    this.posicaoRanking,
  });

  factory RadarOportunidade.fromJson(Map<String, dynamic> json) {
    return RadarOportunidade(
      id: json['id']?.toString() ?? 
          '${json['nr_latitude']}_${json['nr_longitude']}',
      nmLocalVotacao: json['nm_local_votacao'] as String? ?? 'Local desconhecido',
      nmBairro: json['nm_bairro'] as String?,
      nrLatitude: (json['nr_latitude'] as num?)?.toDouble() ?? 0.0,
      nrLongitude: (json['nr_longitude'] as num?)?.toDouble() ?? 0.0,
      votosCandidato: json['votos_candidato'] as int? ?? 0,
      votosTotal: json['votos_total'] as int? ?? 0,
      percentual: (json['percentual'] as num?)?.toDouble() ?? 0.0,
      posicaoRanking: json['posicao_ranking'] as int?,
    );
  }

  /// Retorna true se tem coordenadas válidas
  bool get hasLocation => nrLatitude != 0.0 && nrLongitude != 0.0;

  /// Retorna percentual formatado
  String get percentualFormatado => '${percentual.toStringAsFixed(1)}%';

  /// Indica nível de oportunidade (quanto menor o percentual, maior a oportunidade)
  String get nivelOportunidade {
    if (percentual < 5) return 'ALTA';
    if (percentual < 15) return 'MÉDIA';
    return 'BAIXA';
  }
}
