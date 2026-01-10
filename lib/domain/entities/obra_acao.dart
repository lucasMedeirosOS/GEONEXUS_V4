/// Status de uma obra/ação cadastrada
enum ObraStatus {
  pendente,
  emAndamento,
  concluida,
  cancelada;

  static ObraStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'em_andamento':
      case 'emandamento':
        return ObraStatus.emAndamento;
      case 'concluida':
        return ObraStatus.concluida;
      case 'cancelada':
        return ObraStatus.cancelada;
      default:
        return ObraStatus.pendente;
    }
  }

  String get toDbValue {
    switch (this) {
      case ObraStatus.pendente:
        return 'pendente';
      case ObraStatus.emAndamento:
        return 'em_andamento';
      case ObraStatus.concluida:
        return 'concluida';
      case ObraStatus.cancelada:
        return 'cancelada';
    }
  }

  String get displayName {
    switch (this) {
      case ObraStatus.pendente:
        return 'Pendente';
      case ObraStatus.emAndamento:
        return 'Em Andamento';
      case ObraStatus.concluida:
        return 'Concluída';
      case ObraStatus.cancelada:
        return 'Cancelada';
    }
  }
}

/// Entidade representando uma Obra/Ação cadastrada
/// 
/// Mapeada para a tabela `public.obras_acoes` no Supabase.
class ObraAcao {
  /// ID único da obra (UUID)
  final String? id;

  /// ID do usuário que cadastrou (FK para auth.users)
  final String? userId;

  /// Título da obra/ação (obrigatório)
  final String titulo;

  /// Descrição detalhada
  final String? descricao;

  /// Lista de ruas atendidas pela obra
  final List<String> ruasAtendidas;

  /// Nome do vereador autor/padrinho
  final String? padrinhoVereador;

  /// Nome do prefeito que apoiou
  final String? padrinhoPrefeito;

  /// Quantidade de famílias beneficiadas
  final int? familiasBeneficiadas;

  /// Quantidade de pessoas beneficiadas
  final int? pessoasBeneficiadas;

  /// Latitude da localização da obra
  final double? latitude;

  /// Longitude da localização da obra
  final double? longitude;

  /// Status atual da obra
  final ObraStatus status;

  /// Data de criação
  final DateTime? createdAt;

  const ObraAcao({
    this.id,
    this.userId,
    required this.titulo,
    this.descricao,
    this.ruasAtendidas = const [],
    this.padrinhoVereador,
    this.padrinhoPrefeito,
    this.familiasBeneficiadas,
    this.pessoasBeneficiadas,
    this.latitude,
    this.longitude,
    this.status = ObraStatus.pendente,
    this.createdAt,
  });

  /// Verifica se tem localização definida
  bool get hasLocation => latitude != null && longitude != null;

  /// Retorna total de beneficiados (famílias * ~3.5 pessoas ou pessoas direto)
  int get totalBeneficiados {
    if (pessoasBeneficiadas != null && pessoasBeneficiadas! > 0) {
      return pessoasBeneficiadas!;
    }
    if (familiasBeneficiadas != null) {
      return (familiasBeneficiadas! * 3.5).round();
    }
    return 0;
  }

  @override
  String toString() {
    return 'ObraAcao(titulo: $titulo, status: ${status.displayName})';
  }
}
