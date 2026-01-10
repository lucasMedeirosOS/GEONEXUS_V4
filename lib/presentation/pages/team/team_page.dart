import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/access_control_service.dart';
import '../../providers/map_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/team_providers.dart';
import '../../../data/models/team_member.dart';
import '../../../domain/entities/user_profile.dart';

/// Página de Gestão de Equipe (Premium)
/// 
/// Permite ao administrador visualizar e gerenciar membros da equipe.
class TeamPage extends ConsumerStatefulWidget {
  const TeamPage({super.key});

  @override
  ConsumerState<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends ConsumerState<TeamPage> {
  // Cores Neon
  static const Color _purpleNeon = Color(0xFFBB86FC);
  static const Color _goldNeon = Color(0xFFFFD700);
  static const Color _greenNeon = Color(0xFF10B981);
  static const Color _orangeNeon = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    final userPlan = ref.watch(userPlanProvider);

    // Verifica acesso Premium
    if (!AccessControlService.canGerenciarEquipe(userPlan)) {
      return _buildAccessDenied();
    }

    final teamAsync = ref.watch(teamMembersProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'GESTÃO DE EQUIPE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _goldNeon),
            onPressed: () => ref.invalidate(teamMembersProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: teamAsync.when(
          loading: () => _buildLoadingState(),
          error: (e, _) => _buildErrorState(e.toString()),
          data: (members) => _buildMembersList(members),
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Acesso Restrito',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta funcionalidade está disponível\napenas para usuários Premium.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purpleNeon,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _purpleNeon),
          const SizedBox(height: 16),
          Text(
            'Carregando equipe...',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar equipe',
            style: TextStyle(color: Colors.red.shade300),
          ),
          Text(
            error,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(List<TeamMember> members) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_off, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              'Nenhum membro encontrado',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header com estatísticas
        _buildStatsHeader(members),
        const SizedBox(height: 16),

        // Lista de membros
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: members.length,
            itemBuilder: (context, index) => _buildMemberCard(members[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(List<TeamMember> members) {
    final premium = members.where((m) => m.plano == UserPlan.premium).length;
    final standard = members.where((m) => m.plano == UserPlan.standard).length;
    final free = members.where((m) => m.plano == UserPlan.free).length;
    final totalObras = members.fold<int>(0, (sum, m) => sum + m.obrasCadastradas);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_purpleNeon.withOpacity(0.15), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purpleNeon.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', members.length.toString(), Icons.people),
          _buildStatItem('Premium', premium.toString(), Icons.star, color: _goldNeon),
          _buildStatItem('Standard', standard.toString(), Icons.verified_user, color: _greenNeon),
          _buildStatItem('Obras', totalObras.toString(), Icons.construction, color: _orangeNeon),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? Colors.white54, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(TeamMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_purpleNeon, _purpleNeon.withOpacity(0.5)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                member.nome.isNotEmpty ? member.nome[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildPlanBadge(member.plano),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _orangeNeon.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.construction, color: _orangeNeon, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${member.obrasCadastradas} obras',
                            style: const TextStyle(
                              color: _orangeNeon,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      member.ultimoAcessoFormatado,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu de ações
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.5)),
            color: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (action) => _handleAction(action, member),
            itemBuilder: (context) => [
              if (member.plano != UserPlan.standard)
                const PopupMenuItem(
                  value: 'standard',
                  child: ListTile(
                    leading: Icon(Icons.verified_user, color: _greenNeon),
                    title: Text('Promover a Assessor', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Plano Standard', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ),
                ),
              if (member.plano != UserPlan.premium)
                const PopupMenuItem(
                  value: 'premium',
                  child: ListTile(
                    leading: Icon(Icons.star, color: _goldNeon),
                    title: Text('Promover a Admin', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Plano Premium', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ),
                ),
              if (member.plano != UserPlan.free)
                const PopupMenuItem(
                  value: 'free',
                  child: ListTile(
                    leading: Icon(Icons.person_outline, color: Colors.grey),
                    title: Text('Rebaixar a Cidadão', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Plano Free', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanBadge(UserPlan plan) {
    Color color;
    String label;
    IconData icon;

    switch (plan) {
      case UserPlan.premium:
        color = _goldNeon;
        label = 'Admin';
        icon = Icons.star;
        break;
      case UserPlan.standard:
        color = _greenNeon;
        label = 'Assessor';
        icon = Icons.verified_user;
        break;
      case UserPlan.free:
      default:
        color = Colors.grey;
        label = 'Cidadão';
        icon = Icons.person_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, TeamMember member) async {
    final repository = ref.read(repositoryProvider);

    String newPlan;
    String planLabel;

    switch (action) {
      case 'premium':
        newPlan = 'premium';
        planLabel = 'Admin (Premium)';
        break;
      case 'standard':
        newPlan = 'standard';
        planLabel = 'Assessor (Standard)';
        break;
      case 'free':
      default:
        newPlan = 'free';
        planLabel = 'Cidadão (Free)';
        break;
    }

    // Confirmação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Alterar plano de ${member.nome}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'O plano será alterado para: $planLabel',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purpleNeon,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await repository.updateUserPlan(member.id, newPlan);

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        ref.invalidate(teamMembersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Plano de ${member.nome} alterado para $planLabel'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }
}
