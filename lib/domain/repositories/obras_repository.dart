import 'package:dartz/dartz.dart';
import '../entities/obra.dart';
import '../entities/chamado_1746.dart';

/// Interface abstrata para acesso a dados de obras e chamados
abstract class ObrasRepository {
  /// Busca obras por bounding box
  Future<Either<String, List<Obra>>> getObrasByBounds({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    StatusObra? status,
  });

  /// Busca obra por ID
  Future<Either<String, Obra>> getObraById(int id);

  /// Cria nova obra
  Future<Either<String, Obra>> createObra(Obra obra);

  /// Atualiza status de obra
  Future<Either<String, Obra>> updateObraStatus({
    required int id,
    required StatusObra status,
  });

  /// Busca chamados 1746 perto de uma localização
  Future<Either<String, List<Chamado1746>>> getChamadosProximos({
    required double latitude,
    required double longitude,
    required double raioKm,
  });

  /// Tenta fazer triangulação automática
  Future<Either<String, bool>> tentarTriangulacao({
    required int obraId,
  });
}
