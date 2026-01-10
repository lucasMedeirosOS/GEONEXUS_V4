import '../../domain/entities/resumo_geonexus.dart';

/// Model/DTO para ResumoGeonexus com serialização JSON
/// 
/// Mapeia a tabela resumo_geonexus_rj do Supabase para
/// uso no Google Maps como marcadores.
/// 
/// NOTA (2026-01-06): Colunas sg_uf e nm_bairro foram removidas.
/// A view view_mapa_geral foi recriada sem esses campos.
class ResumoGeonexusModel extends ResumoGeonexus {
  const ResumoGeonexusModel({
    required super.id,
    required super.nrLatitude,
    required super.nrLongitude,
    required super.nmLocalVotacao,
    super.nmMunicipio,
    required super.totalVotos,
    super.totalSecoes,
  });

  /// Factory para criar instância a partir do JSON do Supabase
  /// 
  /// Lê diretamente da tabela resumo_geonexus_rj.
  /// Trata casos onde nr_latitude ou nr_longitude podem vir nulos,
  /// retornando null se não for possível criar o objeto válido.
  static ResumoGeonexusModel? fromJson(Map<String, dynamic> json) {
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

    return ResumoGeonexusModel(
      id: _parseInt(json['id']) ?? 0,
      nrLatitude: latitude,
      nrLongitude: longitude,
      nmLocalVotacao: json['nm_local_votacao'] as String? ?? 'Local sem nome',
      nmMunicipio: json['nm_municipio'] as String?,
      totalVotos: _parseInt(json['total_votos']) ?? 0,
      totalSecoes: _parseInt(json['total_secoes']) ?? 0,
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
      'id': id,
      'nr_latitude': nrLatitude,
      'nr_longitude': nrLongitude,
      'nm_local_votacao': nmLocalVotacao,
      'total_votos': totalVotos,
    };
  }
}
