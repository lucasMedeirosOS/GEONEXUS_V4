import '../../domain/entities/obra_acao.dart';

/// Model para converter dados do Supabase em ObraAcao
class ObraAcaoModel extends ObraAcao {
  const ObraAcaoModel({
    super.id,
    super.userId,
    required super.titulo,
    super.descricao,
    super.ruasAtendidas = const [],
    super.padrinhoVereador,
    super.padrinhoPrefeito,
    super.familiasBeneficiadas,
    super.pessoasBeneficiadas,
    super.latitude,
    super.longitude,
    super.status = ObraStatus.pendente,
    super.createdAt,
  });

  /// Cria ObraAcaoModel a partir de JSON do Supabase
  factory ObraAcaoModel.fromJson(Map<String, dynamic> json) {
    // Extrai ruas atendidas (pode ser array ou null)
    List<String> ruas = [];
    if (json['ruas_atendidas'] != null) {
      ruas = (json['ruas_atendidas'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return ObraAcaoModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      titulo: json['titulo'] as String? ?? 'Sem título',
      descricao: json['descricao'] as String?,
      ruasAtendidas: ruas,
      padrinhoVereador: json['padrinho_vereador'] as String?,
      padrinhoPrefeito: json['padrinho_prefeito'] as String?,
      familiasBeneficiadas: json['familias_beneficiadas'] as int?,
      pessoasBeneficiadas: json['pessoas_beneficiadas'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: ObraStatus.fromString(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Converte para Map para inserção no Supabase
  /// 
  /// Não inclui id e created_at (gerados pelo banco).
  /// O user_id é adicionado separadamente no repositório.
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'ruas_atendidas': ruasAtendidas,
      'padrinho_vereador': padrinhoVereador,
      'padrinho_prefeito': padrinhoPrefeito,
      'familias_beneficiadas': familiasBeneficiadas,
      'pessoas_beneficiadas': pessoasBeneficiadas,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.toDbValue,
    };
  }

  /// Cria uma cópia com campos alterados
  ObraAcaoModel copyWith({
    String? id,
    String? userId,
    String? titulo,
    String? descricao,
    List<String>? ruasAtendidas,
    String? padrinhoVereador,
    String? padrinhoPrefeito,
    int? familiasBeneficiadas,
    int? pessoasBeneficiadas,
    double? latitude,
    double? longitude,
    ObraStatus? status,
    DateTime? createdAt,
  }) {
    return ObraAcaoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      ruasAtendidas: ruasAtendidas ?? this.ruasAtendidas,
      padrinhoVereador: padrinhoVereador ?? this.padrinhoVereador,
      padrinhoPrefeito: padrinhoPrefeito ?? this.padrinhoPrefeito,
      familiasBeneficiadas: familiasBeneficiadas ?? this.familiasBeneficiadas,
      pessoasBeneficiadas: pessoasBeneficiadas ?? this.pessoasBeneficiadas,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
