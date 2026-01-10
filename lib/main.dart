import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'presentation/core/theme/app_theme.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/main_navigation_page.dart';
import 'presentation/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega variáveis de ambiente
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✓ Variáveis de ambiente carregadas');
  } catch (e) {
    debugPrint('✗ Erro carregando .env: $e');
    debugPrint('  Certifique-se de que o arquivo .env existe na raiz do projeto');
  }

  // Valida chaves de API
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
  final mapsKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty || 
      supabaseUrl.contains('SEU_PROJETO')) {
    debugPrint('⚠ SUPABASE_URL não configurada no .env');
  }

  if (supabaseKey == null || supabaseKey.isEmpty ||
      supabaseKey.contains('SUA_ANON_KEY')) {
    debugPrint('⚠ SUPABASE_ANON_KEY não configurada no .env');
  }

  if (mapsKey == null || mapsKey.isEmpty ||
      mapsKey.contains('SUA_CHAVE')) {
    debugPrint('⚠ GOOGLE_MAPS_API_KEY não configurada no .env');
  }

  // Inicializa Supabase (mesmo com valores vazios para não crashar)
  try {
    await Supabase.initialize(
      url: supabaseUrl ?? 'https://placeholder.supabase.co',
      anonKey: supabaseKey ?? 'placeholder-key',
      debug: false,
    );
    debugPrint('✓ Supabase inicializado');
  } catch (e) {
    debugPrint('✗ Erro inicializando Supabase: $e');
  }

  runApp(
    const ProviderScope(
      child: GeonexusApp(),
    ),
  );
}

class GeonexusApp extends StatelessWidget {
  const GeonexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEONEXUS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTechTheme,
      home: const AuthWrapper(),
    );
  }
}

/// Widget que gerencia o fluxo de autenticação
/// 
/// Redireciona para LoginPage se não logado, ou MainNavigationPage se autenticado.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);

    return authState.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFBB86FC),
              ),
              SizedBox(height: 16),
              Text(
                'Carregando...',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
              const SizedBox(height: 16),
              Text(
                'Erro: $error',
                style: TextStyle(color: Colors.red.shade300),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(authSessionProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      data: (authState) {
        // Se não há sessão ou evento é de signOut, vai para login
        if (authState.session == null) {
          debugPrint('🔐 Usuário não autenticado -> LoginPage');
          return const LoginPage();
        }

        // Usuário autenticado -> MainNavigationPage
        debugPrint('🔐 Usuário autenticado: ${authState.session!.user.email}');
        return const MainNavigationPage();
      },
    );
  }
}
