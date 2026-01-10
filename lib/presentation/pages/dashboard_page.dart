import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dashboard_stats.dart';
import '../core/theme/app_theme.dart';
import '../core/services/access_control_service.dart';
import '../providers/map_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import 'obras/cadastro_obra_page.dart';
import 'team/team_page.dart';

/// Página do Dashboard - Cérebro Analítico do GeoNexus
/// 
/// Exibe KPIs e estatísticas com base nos filtros globais.
class DashboardPage extends ConsumerWidget {
  /// Callback para navegar para outra aba
  final Function(int)? onNavigateToTab;

  const DashboardPage({super.key, this.onNavigateToTab});

  // Cores Neon
  static const Color _purpleNeon = Color(0xFFBB86FC);
  static const Color _goldNeon = Color(0xFFFFD700);
  static const Color _greenNeon = Color(0xFF10B981);
  static const Color _orangeNeon = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ano = ref.watch(selectedYearProvider);
    final cargo = ref.watch(selectedCargoProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final userPlan = ref.watch(userPlanProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
          },
          color: _purpleNeon,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(ano, cargo),
                const SizedBox(height: 24),

                // Stats Cards
                statsAsync.when(
                  loading: () => _buildLoadingState(),
                  error: (e, _) => _buildErrorState(e.toString()),
                  data: (stats) => _buildStatsContent(context, ref, stats, userPlan),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int ano, String cargo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_purpleNeon, _purpleNeon.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _purpleNeon.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.analytics, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VISÃO GERAL TÁTICA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _goldNeon.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _goldNeon.withOpacity(0.3)),
                    ),
                    child: Text(
                      '$cargo · $ano',
                      style: const TextStyle(
                        color: _goldNeon,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildShimmerCard(height: 120),
        const SizedBox(height: 16),
        _buildShimmerCard(height: 80),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildShimmerCard(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: _buildShimmerCard(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: _buildShimmerCard(height: 100)),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white24,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            'Erro ao carregar estatísticas',
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

  Widget _buildStatsContent(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
    dynamic userPlan,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seção 1: Votação
        _buildSectionTitle('Análise Eleitoral', Icons.how_to_vote),
        const SizedBox(height: 12),
        _buildVotosCard(stats),
        const SizedBox(height: 12),
        if (stats.melhorBairro != null)
          _buildBairroDestaqueCard(stats),
        const SizedBox(height: 24),

        // Seção 2: Gestão de Obras
        _buildSectionTitle('Gestão de Obras', Icons.construction),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildObraCard(
                'Total',
                stats.totalObras.toString(),
                Icons.folder,
                _purpleNeon,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildObraCard(
                'Pendentes',
                stats.obrasPendentes.toString(),
                Icons.pending_actions,
                _orangeNeon,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildObraCard(
                'Concluídas',
                stats.obrasConcluidas.toString(),
                Icons.check_circle,
                _greenNeon,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Seção 3: Atalhos
        _buildSectionTitle('Ações Rápidas', Icons.flash_on),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Ver no Mapa',
                Icons.map,
                _purpleNeon,
                () => onNavigateToTab?.call(0),
              ),
            ),
            if (AccessControlService.canCadastrarObra(userPlan)) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  'Nova Obra',
                  Icons.add_circle,
                  _goldNeon,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CadastroObraPage()),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        
        // Seção 4: Gestão (Premium)
        if (AccessControlService.canGerenciarEquipe(userPlan)) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Gestão de Equipe', Icons.people),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            'Gerenciar Equipe',
            Icons.group,
            _goldNeon,
            () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TeamPage()),
              );
            },
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _goldNeon, size: 20),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildVotosCard(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _purpleNeon.withOpacity(0.15),
            _purpleNeon.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purpleNeon.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _purpleNeon.withOpacity(0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total de Votos na Região',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatNumber(stats.totalVotos),
                style: const TextStyle(
                  color: _purpleNeon,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'votos',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBairroDestaqueCard(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _goldNeon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _goldNeon.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _goldNeon.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star, color: _goldNeon, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bairro Destaque',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  stats.melhorBairro ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (stats.votosMelhorBairro != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatNumber(stats.votosMelhorBairro!),
                  style: const TextStyle(
                    color: _goldNeon,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'votos',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildObraCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
