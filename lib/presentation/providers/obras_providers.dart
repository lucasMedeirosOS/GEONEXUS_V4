import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/obra_acao.dart';
import 'map_providers.dart';

// ============================================
// PROVIDERS DE OBRAS
// ============================================

/// Provider que busca todas as obras com localização para exibir no mapa
/// 
/// Este provider é usado pela camada de obras do mapa.
final obrasPinsProvider = FutureProvider<List<ObraAcao>>((ref) async {
  final repository = ref.watch(repositoryProvider);
  final result = await repository.getObrasPins();
  
  return result.fold(
    (error) {
      print('❌ Erro ao carregar obras: $error');
      return [];
    },
    (obras) => obras,
  );
});

/// Provider para forçar refresh das obras
final obrasRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider que combina refresh com fetch
final obrasWithRefreshProvider = FutureProvider<List<ObraAcao>>((ref) async {
  // Observa o contador de refresh para invalidar quando necessário
  ref.watch(obrasRefreshProvider);
  
  final repository = ref.watch(repositoryProvider);
  final result = await repository.getObrasPins();
  
  return result.fold(
    (error) => [],
    (obras) => obras,
  );
});
