import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';
import 'map_page.dart';
import 'dashboard_page.dart';
import 'auth/login_page.dart';

/// Página principal com navegação por abas
/// 
/// Contém:
/// - Aba 0: Mapa (MapPage)
/// - Aba 1: Dashboard (DashboardPage)
/// - Aba 2: Perfil
class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int _currentIndex = 0;

  // Cores Neon
  static const Color _purpleNeon = Color(0xFFBB86FC);
  static const Color _goldNeon = Color(0xFFFFD700);

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const MapPage(),
          DashboardPage(onNavigateToTab: _navigateToTab),
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.map, 'Mapa'),
              _buildNavItem(1, Icons.analytics, 'Dashboard'),
              _buildNavItem(2, Icons.person, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    final color = isActive ? _purpleNeon : Colors.white38;

    return InkWell(
      onTap: () => _navigateToTab(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: isActive
            ? BoxDecoration(
                color: _purpleNeon.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_purpleNeon, _purpleNeon.withOpacity(0.5)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryBlack,
                  child: profile.when(
                    loading: () => const CircularProgressIndicator(color: _purpleNeon),
                    error: (_, __) => const Icon(Icons.person, size: 48, color: Colors.white38),
                    data: (p) => Text(
                      p?.nome.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: _purpleNeon,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nome
              profile.when(
                loading: () => const Text('Carregando...', style: TextStyle(color: Colors.white54)),
                error: (_, __) => const Text('Erro', style: TextStyle(color: Colors.red)),
                data: (p) => Column(
                  children: [
                    Text(
                      p?.nome ?? 'Usuário',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p?.email ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 12),
                    // Plano Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _goldNeon.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _goldNeon.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p?.plano.emoji ?? '🥉',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Plano ${p?.plano.displayName ?? "Free"}',
                            style: const TextStyle(
                              color: _goldNeon,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Botão de Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Sair da conta', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
