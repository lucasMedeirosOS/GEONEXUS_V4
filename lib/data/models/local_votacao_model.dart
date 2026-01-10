import '../../domain/entities/local_votacao.dart';

/// Model/DTO para LocalVotacao com serialização JSON
class LocalVotacaoModel extends LocalVotacao {
  const LocalVotacaoModel({
    required super.id,
    required super.sgUf,
    required super.cdMunicipio,
    required super.nmMunicipio,
    required super.nrZona,
    required super.nrSecao,
    required super.nrLocalVotacao,
    required super.nmLocalVotacao,
    super.dsEndereco, // Deprecated: removido do banco
    required super.nmBairro,
    required super.nrCep,
    required super.latitude,
    required super.longitude,
    required super.acessibilidade,
    required super.qtEleitoresSecao,
  });

  factory LocalVotacaoModel.fromJson(Map<String, dynamic> json) {
    return LocalVotacaoModel(
      id: json['id'] as int,
      sgUf: json['sg_uf'] as String,
      cdMunicipio: json['cd_municipio'] as int,
      nmMunicipio: json['nm_municipio'] as String,
      nrZona: json['nr_zona'] as int,
      nrSecao: json['nr_secao'] as int,
      nrLocalVotacao: json['nr_local_votacao'] as int,
      nmLocalVotacao: json['nm_local_votacao'] as String,
      dsEndereco: json['ds_endereco'] as String? ?? '',
      nmBairro: json['nm_bairro'] as String? ?? '',
      nrCep: json['nr_cep'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      acessibilidade: json['acessibilidade'] as bool? ?? false,
      qtEleitoresSecao: json['qt_eleitores_secao'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sg_uf': sgUf,
      'cd_municipio': cdMunicipio,
      'nm_municipio': nmMunicipio,
      'nr_zona': nrZona,
      'nr_secao': nrSecao,
      'nr_local_votacao': nrLocalVotacao,
      'nm_local_votacao': nmLocalVotacao,
      'ds_endereco': dsEndereco,
      'nm_bairro': nmBairro,
      'nr_cep': nrCep,
      'latitude': latitude,
      'longitude': longitude,
      'acessibilidade': acessibilidade,
      'qt_eleitores_secao': qtEleitoresSecao,
    };
  }
}
