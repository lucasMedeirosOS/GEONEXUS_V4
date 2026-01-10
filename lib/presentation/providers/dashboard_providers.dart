import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dashboard_stats.dart';
import 'map_providers.dart';

// ============================================
// PROVIDERS DO DASHBOARD
// ============================================

/// Provider de estatísticas do dashboard
/// 
/// Observa os filtros globais (ano, cargo) e recarrega automaticamente.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final ano = ref.watch(selectedYearProvider);
  final cargo = ref.watch(selectedCargoProvider);
  final bairro = ref.watch(selectedBairroProvider);

  final repository = ref.watch(repositoryProvider);
  final result = await repository.getDashboardStats(
    ano: ano,
    cargo: cargo,
    bairro: bairro,
  );

  return result.fold(
    (error) {
      print('❌ Erro dashboard: $error');
      return DashboardStats.empty();
    },
    (stats) => stats,
  );
});

/// Provider para forçar refresh do dashboard
final dashboardRefreshProvider = StateProvider<int>((ref) => 0);
