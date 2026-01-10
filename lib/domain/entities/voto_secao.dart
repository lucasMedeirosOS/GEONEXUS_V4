import 'package:equatable/equatable.dart';

/// Entidade de Voto agregado por seção
class VotoSecao extends Equatable {
  final int id;
  final int anoEleicao;
  final String sgUf;
  final int cdMunicipio;
  final String nmMunicipio;
  final int nrZona;
  final int nrSecao;
  final int cdCargo;
  final String dsCargo;
  final int nrVotavel;
  final String nmVotavel;
  final int qtVotos;
  final int nrLocalVotacao;

  const VotoSecao({
    required this.id,
    required this.anoEleicao,
    required this.sgUf,
    required this.cdMunicipio,
    required this.nmMunicipio,
    required this.nrZona,
    required this.nrSecao,
    required this.cdCargo,
    required this.dsCargo,
    required this.nrVotavel,
    required this.nmVotavel,
    required this.qtVotos,
    required this.nrLocalVotacao,
  });

  @override
  List<Object?> get props => [
        id,
        anoEleicao,
        sgUf,
        cdMunicipio,
        nrZona,
        nrSecao,
        cdCargo,
        nrVotavel,
      ];
}
