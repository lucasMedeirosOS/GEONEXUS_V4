import 'package:equatable/equatable.dart';

/// Entidade de Chamado 1746
class Chamado1746 extends Equatable {
  final int id;
  final String numeroChamado;
  final String tipo;
  final String subtipo;
  final String descricao;
  final double latitude;
  final double longitude;
  final String bairro;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final String status;

  const Chamado1746({
    required this.id,
    required this.numeroChamado,
    required this.tipo,
    required this.subtipo,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    required this.bairro,
    required this.dataAbertura,
    this.dataFechamento,
    required this.status,
  });

  @override
  List<Object?> get props => [id, numeroChamado];
}
