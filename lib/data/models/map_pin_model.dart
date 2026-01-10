import '../../domain/entities/map_pin.dart';

/// Model/DTO para MapPin com serialização JSON
/// 
/// Mapeia a view_mapa_geral do Supabase para uso no Google Maps.
/// 
/// Colunas da view:
/// - ano_eleicao (int)
/// - nome_candidato (String)
/// - ds_cargo (String)
/// - nm_local_votacao (String)
/// - nr_latitude (Numeric)
/// - nr_longitude (Numeric)
/// - total_votos (Int8)
class MapPinModel extends MapPin {
  const MapPinModel({
    required super.nomeCandidato,
    required super.dsCargo,
    required super.nmLocalVotacao,
    required super.nrLatitude,
    required super.nrLongitude,
    required super.totalVotos,
  });

  /// Factory para criar instância a partir do JSON do Supabase
  /// 
  /// Retorna null se coordenadas forem inválidas.
  /// Suporta tanto 'total_votos' quanto 'total_votos_escola' como nome do campo
  /// para retrocompatibilidade.
  static MapPinModel? fromJson(Map<String, dynamic> json) {
    // Verifica se latitude e longitude são válidas
    final latValue = json['nr_latitude'];
    final lngValue = json['nr_longitude'];
    
    // Se latitude ou longitude forem nulos, retorna null
    if (latValue == null || lngValue == null) {
      return null;
    }

    // Converte para double de forma segura (banco envia Numeric)
    final double? latitude = _parseDouble(latValue);
    final double? longitude = _parseDouble(lngValue);

    if (latitude == null || longitude == null) {
      return null;
    }

    // Valida range de coordenadas
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return null;
    }

    // Novos campos da view
    final nomeCandidato = json['nome_candidato'] as String? ?? 'Candidato';
    final dsCargo = json['ds_cargo'] as String? ?? '';

    // Suporta ambos os nomes de campo para total de votos (retrocompatibilidade)
    // O campo pode vir como int8/BigInt dependendo do banco
    final votosValue = json['total_votos'] ?? json['total_votos_escola'];

    return MapPinModel(
      nomeCandidato: nomeCandidato,
      dsCargo: dsCargo,
      nmLocalVotacao: json['nm_local_votacao'] as String? ?? 'Local sem nome',
      nrLatitude: latitude,
      nrLongitude: longitude,
      totalVotos: _parseInt(votosValue) ?? 0,
    );
  }
  
  /// Converte valor para int de forma segura
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  /// Converte valor para double de forma segura
  /// 
  /// O banco envia nr_latitude e nr_longitude como Numeric (num).
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'nome_candidato': nomeCandidato,
      'ds_cargo': dsCargo,
      'nm_local_votacao': nmLocalVotacao,
      'nr_latitude': nrLatitude,
      'nr_longitude': nrLongitude,
      'total_votos': totalVotos,
    };
  }
}
