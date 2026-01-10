import 'package:equatable/equatable.dart';

/// Entidade de Local de Votação com geolocalização
class LocalVotacao extends Equatable {
  final int id;
  final String sgUf;
  final int cdMunicipio;
  final String nmMunicipio;
  final int nrZona;
  final int nrSecao;
  final int nrLocalVotacao;
  final String nmLocalVotacao;
  /// @deprecated Removido do banco em 2026-01-06
  final String dsEndereco;
  final String nmBairro;
  final String nrCep;
  final double latitude;
  final double longitude;
  final bool acessibilidade;
  final int qtEleitoresSecao;

  const LocalVotacao({
    required this.id,
    required this.sgUf,
    required this.cdMunicipio,
    required this.nmMunicipio,
    required this.nrZona,
    required this.nrSecao,
    required this.nrLocalVotacao,
    required this.nmLocalVotacao,
    this.dsEndereco = '', // Deprecated: removido do banco
    required this.nmBairro,
    required this.nrCep,
    required this.latitude,
    required this.longitude,
    required this.acessibilidade,
    required this.qtEleitoresSecao,
  });

  @override
  List<Object?> get props => [
        id,
        sgUf,
        cdMunicipio,
        nrZona,
        nrSecao,
        nrLocalVotacao,
      ];
}
