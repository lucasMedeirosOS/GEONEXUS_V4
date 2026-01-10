import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_repository_impl.dart';
import '../../domain/entities/voto_secao.dart';
import '../../domain/entities/local_votacao.dart';
import '../../domain/entities/resumo_geonexus.dart';
import '../../domain/entities/map_pin.dart';

// ============================================
// PROVIDERS DE INFRAESTRUTURA
// ============================================

/// Provider do repositório Supabase
final repositoryProvider = Provider<SupabaseRepositoryImpl>((ref) {
  return SupabaseRepositoryImpl();
});

// ============================================
// MAP STATE - Estados da tela
// ============================================

/// Estado do mapa com Loading/Success/Error
sealed class MapState {
  const MapState();
}

class MapLoading extends MapState {
  const MapLoading();
}

class MapSuccess extends MapState {
  final List<VotoSecao> votos;
  final List<LocalVotacao> locais;
  final List<ResumoGeonexus> resumoGeonexus;
  final List<MapPin> mapPins;
  
  const MapSuccess({
    this.votos = const [],
    this.locais = const [],
    this.resumoGeonexus = const [],
    this.mapPins = const [],
  });

  /// Calcula total de votos (prioriza mapPins > resumoGeonexus)
  int get totalVotos {
    if (mapPins.isNotEmpty) {
      return mapPins.fold(0, (sum, p) => sum + p.totalVotos);
    }
    if (resumoGeonexus.isNotEmpty) {
      return resumoGeonexus.fold(0, (sum, r) => sum + r.totalVotos);
    }
    return votos.fold(0, (sum, v) => sum + v.qtVotos);
  }
  
  int get totalLocais {
    if (mapPins.isNotEmpty) return mapPins.length;
    if (resumoGeonexus.isNotEmpty) return resumoGeonexus.length;
    return locais.length;
  }
}

class MapError extends MapState {
  final String message;
  const MapError(this.message);
}

// ============================================
// MAP STATE NOTIFIER
// ============================================

/// StateNotifier para gerenciar estado do mapa
class MapStateNotifier extends StateNotifier<MapState> {
  final SupabaseRepositoryImpl _repository;

  MapStateNotifier(this._repository) : super(const MapLoading());

  /// Carrega votos do estado (RJ por padrão)
  Future<void> loadVotosPorEstado(String uf) async {
    state = const MapLoading();

    final result = await _repository.getVotosPorEstado(uf);

    result.fold(
      (error) => state = MapError(error),
      (votos) => state = MapSuccess(votos: votos),
    );
  }

  /// Carrega locais de votação do estado
  Future<void> loadLocaisPorEstado(String uf) async {
    state = const MapLoading();

    final result = await _repository.getLocaisVotacao(uf: uf);

    result.fold(
      (error) => state = MapError(error),
      (locais) => state = MapSuccess(locais: locais),
    );
  }

  /// Carrega votos e locais juntos
  Future<void> loadDadosCompletos(String uf) async {
    state = const MapLoading();

    final votosResult = await _repository.getVotosPorEstado(uf);
    final locaisResult = await _repository.getLocaisVotacao(uf: uf);

    // Verifica erros
    if (votosResult.isLeft()) {
      state = MapError(votosResult.fold((l) => l, (r) => ''));
      return;
    }
    if (locaisResult.isLeft()) {
      state = MapError(locaisResult.fold((l) => l, (r) => ''));
      return;
    }

    final votos = votosResult.getOrElse(() => []);
    final locais = locaisResult.getOrElse(() => []);

    state = MapSuccess(votos: votos, locais: locais);
  }

  /// Carrega dados da RPC search_dashboard_mapa
  /// 
  /// Esta é a forma recomendada para carregar dados para o mapa,
  /// usando a RPC otimizada com votos agregados e filtrados.
  /// 
  /// Parâmetros obrigatórios:
  /// - ano: Ano da eleição (ex: 2024, 2022)
  /// - cargo: Cargo eleitoral (ex: 'Prefeito', 'Vereador')
  /// 
  /// Parâmetros opcionais:
  /// - search: Nome do candidato para filtrar (ex: "Ronaldo")
  /// - bairro: Nome do bairro para filtrar (null = todos)
  Future<void> loadResumoGeonexus({
    required int ano,
    required String cargo,
    String? search,
    String? bairro,
  }) async {
    state = const MapLoading();

    print('');
    if (search != null && search.isNotEmpty) {
      print('🗺️ MapStateNotifier: Buscando "$search" para ANO=$ano, CARGO=$cargo${bairro != null ? ", BAIRRO=$bairro" : ""}');
    } else {
      print('🗺️ MapStateNotifier: Carregando dados para ANO=$ano, CARGO=$cargo${bairro != null ? ", BAIRRO=$bairro" : ""}');
    }
    print('');

    final result = await _repository.getMapPins(
      ano: ano,
      cargo: cargo,
      search: search,
      bairro: bairro,
    );

    result.fold(
      (error) => state = MapError(error),
      (pins) => state = MapSuccess(mapPins: pins),
    );
  }

  /// Recarrega dados
  void refresh(String uf) {
    loadDadosCompletos(uf);
  }

  /// Recarrega dados do mapa com filtros atuais
  /// Nota: Este método é deprecated. Use loadResumoGeonexus(ano, cargo).
  void refreshResumoGeonexus() {
    // Fallback para valores padrão - deve ser chamado com filtros explícitos
    loadResumoGeonexus(ano: 2024, cargo: 'PREFEITO');
  }

  /// Busca locais com filtros de ano/cargo + texto
  /// 
  /// Se [query] estiver vazia, retorna todos os registros filtrados.
  Future<void> searchResumoGeonexus({
    required int ano,
    required String cargo,
    String query = '',
  }) async {
    state = const MapLoading();

    print('');
    print('🔍 MapStateNotifier: Buscando "$query" para ANO=$ano, CARGO=$cargo');
    print('');

    final result = await _repository.searchMapPins(
      ano: ano,
      cargo: cargo,
      searchText: query,
    );

    result.fold(
      (error) => state = MapError(error),
      (pins) => state = MapSuccess(mapPins: pins),
    );
  }
}

// ============================================
// PROVIDERS
// ============================================

/// Provider do MapStateNotifier
final mapStateProvider = StateNotifierProvider<MapStateNotifier, MapState>((ref) {
  final repository = ref.watch(repositoryProvider);
  return MapStateNotifier(repository);
});

/// Camada ativa do mapa
enum MapLayer { obras, votos }

final activeLayerProvider = StateProvider<MapLayer>((ref) => MapLayer.votos);

/// Estado selecionado (UF)
final selectedUfProvider = StateProvider<String>((ref) => 'RJ');

/// Ano da eleição selecionado (padrão: 2024)
final selectedYearProvider = StateProvider<int>((ref) => 2024);

/// Cargo selecionado para o dashboard (padrão: Prefeito)
/// NOTA: O banco usa title case (Prefeito, Vereador) não uppercase
final selectedCargoProvider = StateProvider<String>((ref) => 'Prefeito');

/// Candidato selecionado para heatmap (número do candidato)
final selectedCandidatoProvider = StateProvider<int?>((ref) => null);

// ============================================
// FILTROS DINÂMICOS (carregados do banco)
// ============================================

/// Anos disponíveis no banco de dados
/// Carrega via RPC get_anos_disponiveis ou fallback para valores padrão
final anosDisponiveisProvider = FutureProvider<List<int>>((ref) async {
  final repository = ref.watch(repositoryProvider);
  final result = await repository.getAnosDisponiveis();
  return result.getOrElse(() => [2024, 2022, 2020, 2018]);
});

/// Cargos disponíveis para o ano selecionado
/// Recarrega automaticamente quando selectedYearProvider muda
final cargosDisponiveisProvider = FutureProvider<List<String>>((ref) async {
  final ano = ref.watch(selectedYearProvider);
  final repository = ref.watch(repositoryProvider);
  final result = await repository.getCargosPorAno(ano);
  return result.getOrElse(() => ['PREFEITO', 'VEREADOR']);
});

/// Bairro selecionado para filtro (null = todos os bairros)
final selectedBairroProvider = StateProvider<String?>((ref) => null);

/// Bairros disponíveis para o ano e cargo selecionados
/// Recarrega automaticamente quando selectedYearProvider ou selectedCargoProvider mudam
final bairrosDisponiveisProvider = FutureProvider<List<String>>((ref) async {
  final ano = ref.watch(selectedYearProvider);
  final cargo = ref.watch(selectedCargoProvider);
  final repository = ref.watch(repositoryProvider);
  final result = await repository.getBairrosDisponiveis(ano: ano, cargo: cargo);
  return result.getOrElse(() => []);
});

/// Termo de busca atual (para destacar candidato no Raio-X)
final searchQueryProvider = StateProvider<String>((ref) => '');

// ============================================
// WIDGETS DE LOADING
// ============================================

/// Circular Progress Indicator elegante
class ElegantLoadingIndicator extends StatelessWidget {
  final String? message;
  final Color color;

  const ElegantLoadingIndicator({
    super.key,
    this.message,
    this.color = const Color(0xFFBB86FC),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Spinner com glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Spinner
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        backgroundColor: color.withOpacity(0.15),
                      ),
                    ),
                    // Icon center
                    Icon(
                      Icons.hexagon_outlined,
                      color: color,
                      size: 20,
                    ),
                  ],
                ),
                if (message != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    message!,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
