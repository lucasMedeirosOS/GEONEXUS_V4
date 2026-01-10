import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import 'register_page.dart';
import '../map_page.dart';

/// Página de login do GeoNexus
/// 
/// Permite ao usuário fazer login com email e senha.
/// Dark Tech Theme consistente com o resto do app.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _obscureSenha = true;
  bool _isLoading = false;

  // Cores Neon
  static const Color _purpleNeon = Color(0xFFBB86FC);
  static const Color _goldNeon = Color(0xFFFFD700);

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuta erros de autenticação
    ref.listen<AppAuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
        ref.read(authNotifierProvider.notifier).clearError();
      }
      if (next.user != null) {
        // Login bem-sucedido, navega para o mapa
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MapPage()),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo e título
                  _buildHeader(),
                  const SizedBox(height: 48),

                  // Campo Email
                  _buildEmailField(),
                  const SizedBox(height: 16),

                  // Campo Senha
                  _buildSenhaField(),
                  const SizedBox(height: 32),

                  // Botão Entrar
                  _buildLoginButton(),
                  const SizedBox(height: 24),

                  // Link para cadastro
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Ícone com glow
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [_purpleNeon, _purpleNeon.withOpacity(0.6)],
            ),
            boxShadow: [
              BoxShadow(
                color: _purpleNeon.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'GEONEXUS',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inteligência Eleitoral Geográfica',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Email',
        icon: Icons.email_outlined,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Informe seu email';
        }
        if (!value.contains('@')) {
          return 'Email inválido';
        }
        return null;
      },
    );
  }

  Widget _buildSenhaField() {
    return TextFormField(
      controller: _senhaController,
      obscureText: _obscureSenha,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Senha',
        icon: Icons.lock_outlined,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureSenha ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54,
          ),
          onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Informe sua senha';
        }
        if (value.length < 6) {
          return 'Senha deve ter no mínimo 6 caracteres';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: _purpleNeon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _purpleNeon, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: _purpleNeon,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login),
                SizedBox(width: 8),
                Text(
                  'ENTRAR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Não tem conta? ',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            );
          },
          child: const Text(
            'Criar conta',
            style: TextStyle(
              color: _goldNeon,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(authNotifierProvider.notifier).signIn(
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
