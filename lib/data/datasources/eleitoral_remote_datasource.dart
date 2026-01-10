import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/local_votacao_model.dart';
import '../models/voto_secao_model.dart';

/// Datasource remoto para dados eleitorais via Supabase
class EleitoralRemoteDatasource {
  final SupabaseClient _client;

  EleitoralRemoteDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Busca locais de votação por UF
  Future<List<LocalVotacaoModel>> getLocaisVotacao({
    required String uf,
    int? cdMunicipio,
  }) async {
    var query = _client
        .from('locais_votacao')
        .select()
        .eq('sg_uf', uf);

    if (cdMunicipio != null) {
      query = query.eq('cd_municipio', cdMunicipio);
    }

    final response = await query;
    return (response as List)
        .map((json) => LocalVotacaoModel.fromJson(json))
        .toList();
  }

  /// Busca locais dentro de bounding box
  Future<List<LocalVotacaoModel>> getLocaisVotacaoByBounds({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {
    final response = await _client
        .from('locais_votacao')
        .select()
        .gte('latitude', swLat)
        .lte('latitude', neLat)
        .gte('longitude', swLng)
        .lte('longitude', neLng);

    return (response as List)
        .map((json) => LocalVotacaoModel.fromJson(json))
        .toList();
  }

  /// Busca votos por seção
  Future<List<VotoSecaoModel>> getVotosSecao({
    required int anoEleicao,
    required String uf,
    int? cdMunicipio,
    int? nrZona,
    int? nrSecao,
    int? cdCargo,
  }) async {
    var query = _client
        .from('votos_secao')
        .select()
        .eq('ano_eleicao', anoEleicao)
        .eq('sg_uf', uf);

    if (cdMunicipio != null) {
      query = query.eq('cd_municipio', cdMunicipio);
    }
    if (nrZona != null) {
      query = query.eq('nr_zona', nrZona);
    }
    if (nrSecao != null) {
      query = query.eq('nr_secao', nrSecao);
    }
    if (cdCargo != null) {
      query = query.eq('cd_cargo', cdCargo);
    }

    final response = await query;
    return (response as List)
        .map((json) => VotoSecaoModel.fromJson(json))
        .toList();
  }

  /// Busca votos agregados por candidato num município
  Future<Map<String, int>> getVotosPorCandidato({
    required int anoEleicao,
    required int cdMunicipio,
    required int cdCargo,
  }) async {
    final response = await _client.rpc(
      'votos_agregados_por_candidato',
      params: {
        'p_ano_eleicao': anoEleicao,
        'p_cd_municipio': cdMunicipio,
        'p_cd_cargo': cdCargo,
      },
    );

    final Map<String, int> result = {};
    for (final row in response as List) {
      result[row['nm_votavel'] as String] = row['total_votos'] as int;
    }
    return result;
  }

  /// Busca dados para heatmap de votos
  Future<List<Map<String, dynamic>>> getHeatmapVotos({
    required int anoEleicao,
    required int cdMunicipio,
    required int nrVotavel,
  }) async {
    final response = await _client.rpc(
      'heatmap_votos_candidato',
      params: {
        'p_ano_eleicao': anoEleicao,
        'p_cd_municipio': cdMunicipio,
        'p_nr_votavel': nrVotavel,
      },
    );

    return List<Map<String, dynamic>>.from(response);
  }
}
