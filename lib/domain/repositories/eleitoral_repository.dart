import 'package:dartz/dartz.dart';
import '../entities/local_votacao.dart';
import '../entities/voto_secao.dart';

/// Interface abstrata para acesso a dados eleitorais
abstract class EleitoralRepository {
  /// Busca locais de votação por UF
  Future<Either<String, List<LocalVotacao>>> getLocaisVotacao({
    required String uf,
    int? cdMunicipio,
  });

  /// Busca locais de votação dentro de um bounding box
  Future<Either<String, List<LocalVotacao>>> getLocaisVotacaoByBounds({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  });

  /// Busca votos por seção
  Future<Either<String, List<VotoSecao>>> getVotosSecao({
    required int anoEleicao,
    required String uf,
    int? cdMunicipio,
    int? nrZona,
    int? nrSecao,
    int? cdCargo,
  });

  /// Busca votos agregados por candidato num município
  Future<Either<String, Map<String, int>>> getVotosPorCandidato({
    required int anoEleicao,
    required int cdMunicipio,
    required int cdCargo,
  });

  /// Busca heatmap de votos por local
  Future<Either<String, List<Map<String, dynamic>>>> getHeatmapVotos({
    required int anoEleicao,
    required int cdMunicipio,
    required int nrVotavel,
  });
}
