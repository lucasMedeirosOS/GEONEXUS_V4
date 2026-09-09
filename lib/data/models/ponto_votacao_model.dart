class PontoVotacao {
  final String local;
  final String bairro;
  final double latitude;
  final double longitude;
  final int votos;

  const PontoVotacao({
    required this.local,
    required this.bairro,
    required this.latitude,
    required this.longitude,
    required this.votos,
  });

  factory PontoVotacao.fromJson(Map<String, dynamic> json) {
    return PontoVotacao(
      local: json['local']?.toString() ?? 'Colégio Eleitoral',
      bairro: json['bairro']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      votos: (json['votos'] as num?)?.toInt() ?? 0,
    );
  }
}
