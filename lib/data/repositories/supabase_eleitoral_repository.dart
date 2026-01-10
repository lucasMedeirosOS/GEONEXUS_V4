import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/local_votacao.dart';
import '../../domain/entities/voto_secao.dart';
import '../../domain/repositories/eleitoral_repository.dart';
import '../models/local_votacao_model.dart';
import '../models/voto_secao_model.dart';

/// Implementação concreta do repositório eleitoral usando Supabase
class SupabaseEleitoralRepository implements EleitoralRepository {
  final SupabaseClient _client;

  SupabaseEleitoralRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<Either<String, List<LocalVotacao>>> getLocaisVotacao({
    required String uf,
    int? cdMunicipio,
  }) async {
    try {
      var query = _client
          .from('locais_votacao')
          .select()
          .eq('sg_uf', uf.toUpperCase());

      if (cdMunicipio != null) {
        query = query.eq('cd_municipio', cdMunicipio);
      }

      final response = await query.limit(1000);

      final locais = (response as List)
          .map((json) => LocalVotacaoModel.fromJson(json))
          .toList();

      return Right(locais);
    } on PostgrestException catch (e) {
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      return Left('Erro ao buscar locais: $e');
    }
  }

  @override
  Future<Either<String, List<LocalVotacao>>> getLocaisVotacaoByBounds({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {
    try {
      final response = await _client
          .from('locais_votacao')
          .select()
          .gte('latitude', swLat)
          .lte('latitude', neLat)
          .gte('longitude', swLng)
          .lte('longitude', neLng)
          .limit(500);

      final locais = (response as List)
          .map((json) => LocalVotacaoModel.fromJson(json))
          .toList();

      return Right(locais);
    } on PostgrestException catch (e) {
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      return Left('Erro ao buscar locais por bounds: $e');
    }
  }

  @override
  Future<Either<String, List<VotoSecao>>> getVotosSecao({
    required int anoEleicao,
    required String uf,
    int? cdMunicipio,
    int? nrZona,
    int? nrSecao,
    int? cdCargo,
  }) async {
    try {
      var query = _client
          .from('votos_secao')
          .select()
          .eq('ano_eleicao', anoEleicao)
          .eq('sg_uf', uf.toUpperCase());

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

      // Limite para teste de performance inicial
      final response = await query.limit(500);

      final votos = (response as List)
          .map((json) => VotoSecaoModel.fromJson(json))
          .toList();

      return Right(votos);
    } on PostgrestException catch (e) {
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      return Left('Erro ao buscar votos: $e');
    }
  }

  @override
  Future<Either<String, Map<String, int>>> getVotosPorCandidato({
    required int anoEleicao,
    required int cdMunicipio,
    required int cdCargo,
  }) async {
    try {
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
      return Right(result);
    } on PostgrestException catch (e) {
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      return Left('Erro ao agregar votos: $e');
    }
  }

  @override
  Future<Either<String, List<Map<String, dynamic>>>> getHeatmapVotos({
    required int anoEleicao,
    required int cdMunicipio,
    required int nrVotavel,
  }) async {
    try {
      final response = await _client.rpc(
        'heatmap_votos_candidato',
        params: {
          'p_ano_eleicao': anoEleicao,
          'p_cd_municipio': cdMunicipio,
          'p_nr_votavel': nrVotavel,
        },
      );

      return Right(List<Map<String, dynamic>>.from(response));
    } on PostgrestException catch (e) {
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      return Left('Erro ao gerar heatmap: $e');
    }
  }
}
