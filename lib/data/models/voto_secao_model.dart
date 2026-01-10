import '../../domain/entities/voto_secao.dart';

/// Model/DTO para VotoSecao com serialização JSON
class VotoSecaoModel extends VotoSecao {
  const VotoSecaoModel({
    required super.id,
    required super.anoEleicao,
    required super.sgUf,
    required super.cdMunicipio,
    required super.nmMunicipio,
    required super.nrZona,
    required super.nrSecao,
    required super.cdCargo,
    required super.dsCargo,
    required super.nrVotavel,
    required super.nmVotavel,
    required super.qtVotos,
    required super.nrLocalVotacao,
  });

  factory VotoSecaoModel.fromJson(Map<String, dynamic> json) {
    return VotoSecaoModel(
      id: json['id'] as int,
      anoEleicao: json['ano_eleicao'] as int,
      sgUf: json['sg_uf'] as String,
      cdMunicipio: json['cd_municipio'] as int,
      nmMunicipio: json['nm_municipio'] as String,
      nrZona: json['nr_zona'] as int,
      nrSecao: json['nr_secao'] as int,
      cdCargo: json['cd_cargo'] as int,
      dsCargo: json['ds_cargo'] as String,
      nrVotavel: json['nr_votavel'] as int,
      nmVotavel: json['nm_votavel'] as String,
      qtVotos: json['qt_votos'] as int,
      nrLocalVotacao: json['nr_local_votacao'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ano_eleicao': anoEleicao,
      'sg_uf': sgUf,
      'cd_municipio': cdMunicipio,
      'nm_municipio': nmMunicipio,
      'nr_zona': nrZona,
      'nr_secao': nrSecao,
      'cd_cargo': cdCargo,
      'ds_cargo': dsCargo,
      'nr_votavel': nrVotavel,
      'nm_votavel': nmVotavel,
      'qt_votos': qtVotos,
      'nr_local_votacao': nrLocalVotacao,
    };
  }
}
