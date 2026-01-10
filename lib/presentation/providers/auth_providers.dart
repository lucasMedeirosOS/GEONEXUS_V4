import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

// ============================================
// PROVIDERS DE AUTENTICAÇÃO
// ============================================

/// Provider do repositório de autenticação
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Provider do estado de autenticação (sessão atual)
/// 
/// Retorna a Session atual do Supabase ou null se não logado.
final authSessionProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Provider do usuário atual autenticado
/// 
/// Retorna o User do Supabase Auth ou null.
final currentAuthUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Provider que indica se o usuário está logado
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentAuthUserProvider);
  return user != null;
});

/// Provider do perfil completo do usuário
/// 
/// Busca na tabela `profiles` os dados do usuário logado.
/// Retorna null se não houver usuário ou perfil.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return null;

  final repository = ref.read(authRepositoryProvider);
  final result = await repository.getUserProfile(user.id);

  return result.fold(
    (error) {
      // Fallback: retorna perfil básico se não encontrar na tabela
      return UserProfile(
        id: user.id,
        nome: user.userMetadata?['nome'] as String? ?? 'Usuário',
        email: user.email,
        plano: UserPlan.free,
      );
    },
    (profile) => profile,
  );
});

/// Provider do plano atual do usuário
/// 
/// Retorna o plano ou `free` como fallback.
final userPlanProvider = Provider<UserPlan>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile?.plano ?? UserPlan.free,
    orElse: () => UserPlan.free,
  );
});

// ============================================
// ESTADO DE AUTENTICAÇÃO (STATEFUL)
// ============================================

/// Estado de autenticação para operações assíncronas
class AppAuthState {
  final bool isLoading;
  final String? error;
  final UserProfile? user;

  const AppAuthState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  AppAuthState copyWith({
    bool? isLoading,
    String? error,
    UserProfile? user,
  }) {
    return AppAuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }

  factory AppAuthState.initial() => const AppAuthState();
  factory AppAuthState.loading() => const AppAuthState(isLoading: true);
  factory AppAuthState.error(String message) => AppAuthState(error: message);
  factory AppAuthState.authenticated(UserProfile user) => AppAuthState(user: user);
}

/// Notifier para gerenciar operações de autenticação
class AuthNotifier extends StateNotifier<AppAuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AppAuthState.initial());

  /// Realiza cadastro
  Future<bool> signUp({
    required String email,
    required String senha,
    required String nome,
  }) async {
    state = AppAuthState.loading();

    final result = await _repository.signUp(
      email: email,
      senha: senha,
      nome: nome,
    );

    return result.fold(
      (error) {
        state = AppAuthState.error(error);
        return false;
      },
      (user) {
        state = AppAuthState.authenticated(user);
        return true;
      },
    );
  }

  /// Realiza login
  Future<bool> signIn({
    required String email,
    required String senha,
  }) async {
    state = AppAuthState.loading();

    final result = await _repository.signIn(
      email: email,
      senha: senha,
    );

    return result.fold(
      (error) {
        state = AppAuthState.error(error);
        return false;
      },
      (user) {
        state = AppAuthState.authenticated(user);
        return true;
      },
    );
  }

  /// Realiza logout
  Future<void> signOut() async {
    await _repository.signOut();
    state = AppAuthState.initial();
  }

  /// Limpa erro
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider do notifier de autenticação
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
