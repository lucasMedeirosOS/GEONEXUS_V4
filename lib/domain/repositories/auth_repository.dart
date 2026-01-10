import 'package:dartz/dartz.dart';
import '../entities/user_profile.dart';

/// Interface do repositório de autenticação
/// 
/// Define o contrato para operações de autenticação e perfil de usuário.
abstract class AuthRepository {
  /// Realiza cadastro de novo usuário
  /// 
  /// O Supabase criará o usuário no Auth e o trigger do banco
  /// criará automaticamente o perfil na tabela `profiles`.
  /// 
  /// Parâmetros:
  /// - email: Email do usuário (obrigatório)
  /// - senha: Senha forte (obrigatório)
  /// - nome: Nome completo (passado como metadata para o trigger)
  Future<Either<String, UserProfile>> signUp({
    required String email,
    required String senha,
    required String nome,
  });

  /// Realiza login do usuário
  /// 
  /// Retorna o perfil completo após autenticação bem-sucedida.
  Future<Either<String, UserProfile>> signIn({
    required String email,
    required String senha,
  });

  /// Realiza logout do usuário atual
  Future<Either<String, void>> signOut();

  /// Obtém o usuário atualmente autenticado
  /// 
  /// Retorna null se não houver usuário logado.
  Future<UserProfile?> getCurrentUser();

  /// Obtém o perfil completo de um usuário pelo ID
  /// 
  /// Busca na tabela `profiles` os dados do usuário.
  Future<Either<String, UserProfile>> getUserProfile(String userId);

  /// Stream de mudanças no estado de autenticação
  Stream<UserProfile?> get authStateChanges;
  
  /// Verifica se há usuário logado
  bool get isLoggedIn;
}
