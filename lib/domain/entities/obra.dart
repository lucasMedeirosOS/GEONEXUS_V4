import 'package:equatable/equatable.dart';

/// Status de triangulação/validação da obra
enum StatusObra {
  pendente,
  validado, // Match encontrado (Ofício + 1746 + DO)
  apadrinhado, // Confirmado como apadrinhado
  refutado,
}

/// Entidade de Obra pública
class Obra extends Equatable {
  final int id;
  final String titulo;
  final String descricao;
  final double latitude;
  final double longitude;
  final String bairro;
  final String? fotoOficioUrl;
  final String? numeroChamado1746;
  final String? diarioOficialRef;
  final DateTime? dataOficio;
  final DateTime? dataChamado1746;
  final DateTime? dataDiarioOficial;
  final StatusObra status;
  final String? politicoAssociado;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Obra({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    required this.bairro,
    this.fotoOficioUrl,
    this.numeroChamado1746,
    this.diarioOficialRef,
    this.dataOficio,
    this.dataChamado1746,
    this.dataDiarioOficial,
    required this.status,
    this.politicoAssociado,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Verifica se há triangulação completa
  bool get temTriangulacaoCompleta =>
      fotoOficioUrl != null &&
      numeroChamado1746 != null &&
      diarioOficialRef != null;

  /// Contagem de evidências
  int get numeroEvidencias {
    int count = 0;
    if (fotoOficioUrl != null) count++;
    if (numeroChamado1746 != null) count++;
    if (diarioOficialRef != null) count++;
    return count;
  }

  @override
  List<Object?> get props => [id, latitude, longitude, status];
}
