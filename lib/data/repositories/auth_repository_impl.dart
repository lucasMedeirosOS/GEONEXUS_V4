import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_profile_model.dart';

/// Implementação do repositório de autenticação usando Supabase
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  AuthRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<Either<String, UserProfile>> signUp({
    required String email,
    required String senha,
    required String nome,
  }) async {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════╗');
    debugPrint('║  🔐 GEONEXUS AUTH - CADASTRO                                 ║');
    debugPrint('╠══════════════════════════════════════════════════════════════╣');
    debugPrint('║  EMAIL: ${email.padRight(51)}║');
    debugPrint('║  NOME: ${nome.padRight(52)}║');
    debugPrint('╚══════════════════════════════════════════════════════════════╝');
    debugPrint('');

    try {
      // Registra usuário no Supabase Auth
      // O trigger do banco criará automaticamente o perfil na tabela profiles
      final response = await _client.auth.signUp(
        email: email,
        password: senha,
        data: {
          'nome': nome,  // Passado para o trigger via user_metadata
        },
      );

      if (response.user == null) {
        return const Left('Erro ao criar usuário. Tente novamente.');
      }

      debugPrint('✅ Usuário criado: ${response.user!.id}');

      // Aguarda um momento para o trigger criar o perfil
      await Future.delayed(const Duration(milliseconds: 500));

      // Busca o perfil criado pelo trigger
      final profileResult = await getUserProfile(response.user!.id);

      return profileResult.fold(
        (error) {
          // Se não conseguiu buscar perfil, retorna perfil básico
          debugPrint('⚠️ Perfil não encontrado, criando básico: $error');
          return Right(UserProfileModel(
            id: response.user!.id,
            nome: nome,
            email: email,
            plano: UserPlan.free,
          ));
        },
        (profile) => Right(profile),
      );
    } on AuthException catch (e) {
      debugPrint('❌ Erro Auth: ${e.message}');
      return Left(_translateAuthError(e.message));
    } catch (e) {
      debugPrint('❌ Erro ao cadastrar: $e');
      return Left('Erro ao cadastrar: $e');
    }
  }

  @override
  Future<Either<String, UserProfile>> signIn({
    required String email,
    required String senha,
  }) async {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════╗');
    debugPrint('║  🔐 GEONEXUS AUTH - LOGIN                                    ║');
    debugPrint('╠══════════════════════════════════════════════════════════════╣');
    debugPrint('║  EMAIL: ${email.padRight(51)}║');
    debugPrint('╚══════════════════════════════════════════════════════════════╝');
    debugPrint('');

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: senha,
      );

      if (response.user == null) {
        return const Left('Credenciais inválidas');
      }

      debugPrint('✅ Login bem-sucedido: ${response.user!.id}');

      // Busca perfil completo
      final profileResult = await getUserProfile(response.user!.id);

      return profileResult.fold(
        (error) {
          // Se não conseguiu buscar perfil, retorna básico
          return Right(UserProfileModel(
            id: response.user!.id,
            nome: response.user!.userMetadata?['nome'] as String? ?? 'Usuário',
            email: email,
            plano: UserPlan.free,
          ));
        },
        (profile) => Right(profile),
      );
    } on AuthException catch (e) {
      debugPrint('❌ Erro Auth: ${e.message}');
      return Left(_translateAuthError(e.message));
    } catch (e) {
      debugPrint('❌ Erro ao fazer login: $e');
      return Left('Erro ao fazer login: $e');
    }
  }

  @override
  Future<Either<String, void>> signOut() async {
    debugPrint('🔐 GEONEXUS AUTH - LOGOUT');

    try {
      await _client.auth.signOut();
      debugPrint('✅ Logout realizado');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ Erro ao fazer logout: $e');
      return Left('Erro ao fazer logout: $e');
    }
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final result = await getUserProfile(user.id);
    return result.fold(
      (error) => UserProfileModel(
        id: user.id,
        nome: user.userMetadata?['nome'] as String? ?? 'Usuário',
        email: user.email,
        plano: UserPlan.free,
      ),
      (profile) => profile,
    );
  }

  @override
  Future<Either<String, UserProfile>> getUserProfile(String userId) async {
    debugPrint('🔍 Buscando perfil: $userId');

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ Perfil não encontrado para: $userId');
        return const Left('Perfil não encontrado');
      }

      final profile = UserProfileModel.fromJson(response);
      debugPrint('✅ Perfil carregado: ${profile.nome} (${profile.plano.displayName})');

      return Right(profile);
    } on PostgrestException catch (e) {
      debugPrint('❌ Erro Postgrest: ${e.message}');
      return Left('Erro ao buscar perfil: ${e.message}');
    } catch (e) {
      debugPrint('❌ Erro ao buscar perfil: $e');
      return Left('Erro ao buscar perfil: $e');
    }
  }

  @override
  Stream<UserProfile?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session?.user == null) {
        return null;
      }
      return await getCurrentUser();
    });
  }

  @override
  bool get isLoggedIn => _client.auth.currentUser != null;

  /// Traduz mensagens de erro do Supabase Auth
  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email ou senha incorretos';
    }
    if (message.contains('Email not confirmed')) {
      return 'Confirme seu email antes de fazer login';
    }
    if (message.contains('User already registered')) {
      return 'Este email já está cadastrado';
    }
    if (message.contains('Password should be at least')) {
      return 'A senha deve ter no mínimo 6 caracteres';
    }
    if (message.contains('Invalid email')) {
      return 'Email inválido';
    }
    return message;
  }
}
