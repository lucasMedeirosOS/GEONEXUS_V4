import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/team_member.dart';
import 'map_providers.dart';

// ============================================
// PROVIDERS DE GESTÃO DE EQUIPE (Premium)
// ============================================

/// Provider para lista de membros da equipe
final teamMembersProvider = FutureProvider<List<TeamMember>>((ref) async {
  final repository = ref.watch(repositoryProvider);
  final result = await repository.getEquipeStats();

  return result.fold(
    (error) {
      print('❌ Erro team: $error');
      return [];
    },
    (members) => members,
  );
});

/// Provider para forçar refresh da equipe
final teamRefreshProvider = StateProvider<int>((ref) => 0);
