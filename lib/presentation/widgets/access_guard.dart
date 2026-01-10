import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_profile.dart';
import '../providers/auth_providers.dart';

/// Widget de proteção de acesso baseado no plano do usuário
/// 
/// Exibe o [child] apenas se o usuário tiver o [requiredPlan] ou superior.
/// Caso contrário, exibe o [fallback] (ou o widget de upgrade padrão).
/// 
/// Exemplo:
/// ```dart
/// AccessGuard(
///   requiredPlan: UserPlan.standard,
///   child: CadastroObraPage(),
///   fallback: UpgradePromptWidget(),
/// )
/// ```
class AccessGuard extends ConsumerWidget {
  /// Plano mínimo necessário para acessar o conteúdo
  final UserPlan requiredPlan;
  
  /// Widget exibido quando o usuário tem acesso
  final Widget child;
  
  /// Widget exibido quando o usuário não tem acesso
  /// Se null, exibe o widget de upgrade padrão
  final Widget? fallback;
  
  /// Mensagem customizada para o upgrade
  final String? upgradeMessage;

  /// Se true, mostra loading enquanto carrega perfil
  final bool showLoading;

  const AccessGuard({
    super.key,
    required this.requiredPlan,
    required this.child,
    this.fallback,
    this.upgradeMessage,
    this.showLoading = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => showLoading
          ? const Center(child: CircularProgressIndicator())
          : child, // Se não mostrar loading, exibe child (otimista)
      error: (error, _) => _buildErrorWidget(context),
      data: (profile) {
        if (profile == null) {
          return _buildNotLoggedInWidget(context);
        }

        if (_hasAccess(profile.plano)) {
          return child;
        }

        return fallback ?? _buildUpgradeWidget(context, profile.plano);
      },
    );
  }

  /// Verifica se o plano do usuário tem acesso ao conteúdo
  bool _hasAccess(UserPlan userPlan) {
    switch (requiredPlan) {
      case UserPlan.free:
        return true; // Todos têm acesso
      case UserPlan.standard:
        return userPlan == UserPlan.standard || userPlan == UserPlan.premium;
      case UserPlan.premium:
        return userPlan == UserPlan.premium;
    }
  }

  Widget _buildNotLoggedInWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Faça login para acessar',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Erro ao verificar acesso',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeWidget(BuildContext context, UserPlan currentPlan) {
    const purpleNeon = Color(0xFFBB86FC);
    const goldNeon = Color(0xFFFFD700);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: purpleNeon.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone de cadeado com glow
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: purpleNeon.withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: purpleNeon.withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock,
                  size: 40,
                  color: purpleNeon,
                ),
              ),
              const SizedBox(height: 20),
              
              // Título
              const Text(
                'Conteúdo Exclusivo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Mensagem
              Text(
                upgradeMessage ?? 
                    'Este recurso está disponível a partir do plano ${requiredPlan.displayName}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              
              // Badges de plano
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPlanBadge(currentPlan, 'Seu plano', Colors.grey),
                  const SizedBox(width: 16),
                  const Icon(Icons.arrow_forward, color: Colors.white38),
                  const SizedBox(width: 16),
                  _buildPlanBadge(requiredPlan, 'Necessário', goldNeon),
                ],
              ),
              const SizedBox(height: 24),
              
              // Botão de upgrade
              ElevatedButton(
                onPressed: () {
                  // TODO: Implementar fluxo de upgrade
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidade de upgrade em breve!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldNeon,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'FAZER UPGRADE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanBadge(UserPlan plan, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(plan.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                plan.displayName,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Widget simplificado que esconde conteúdo baseado no plano
/// 
/// Diferente do AccessGuard, este widget simplesmente não renderiza
/// nada se o usuário não tiver acesso.
class HideIfNoAccess extends ConsumerWidget {
  final UserPlan requiredPlan;
  final Widget child;

  const HideIfNoAccess({
    super.key,
    required this.requiredPlan,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(userPlanProvider);

    switch (requiredPlan) {
      case UserPlan.free:
        return child;
      case UserPlan.standard:
        if (plan == UserPlan.standard || plan == UserPlan.premium) {
          return child;
        }
        return const SizedBox.shrink();
      case UserPlan.premium:
        if (plan == UserPlan.premium) {
          return child;
        }
        return const SizedBox.shrink();
    }
  }
}
