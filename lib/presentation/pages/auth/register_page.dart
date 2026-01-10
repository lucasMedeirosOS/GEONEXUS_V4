import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../map_page.dart';

/// Página de cadastro do GeoNexus
/// 
/// Formulário de cadastro rico com:
/// - Nome completo
/// - Email
/// - Senha + confirmação
/// - Validações
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();
  
  bool _obscureSenha = true;
  bool _obscureConfirma = true;
  bool _isLoading = false;

  // Cores Neon
  static const Color _purpleNeon = Color(0xFFBB86FC);
  static const Color _goldNeon = Color(0xFFFFD700);

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
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
        // Cadastro bem-sucedido
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso! Bem-vindo ao GeoNexus.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MapPage()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 32),

                  // Campo Nome
                  _buildNomeField(),
                  const SizedBox(height: 16),

                  // Campo Email
                  _buildEmailField(),
                  const SizedBox(height: 16),

                  // Campo Senha
                  _buildSenhaField(),
                  const SizedBox(height: 16),

                  // Campo Confirmar Senha
                  _buildConfirmaSenhaField(),
                  const SizedBox(height: 8),

                  // Requisitos de senha
                  _buildPasswordRequirements(),
                  const SizedBox(height: 24),

                  // Botão Cadastrar
                  _buildRegisterButton(),
                  const SizedBox(height: 16),

                  // Link para login
                  _buildLoginLink(),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _purpleNeon.withOpacity(0.15),
            border: Border.all(color: _purpleNeon.withOpacity(0.3)),
          ),
          child: const Icon(
            Icons.person_add,
            size: 40,
            color: _purpleNeon,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Criar Conta',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Preencha seus dados para começar',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildNomeField() {
    return TextFormField(
      controller: _nomeController,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Nome Completo',
        icon: Icons.person_outlined,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Informe seu nome';
        }
        if (value.trim().split(' ').length < 2) {
          return 'Informe nome e sobrenome';
        }
        return null;
      },
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
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
      onChanged: (_) => setState(() {}), // Atualiza requisitos
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Informe uma senha';
        }
        if (value.length < 6) {
          return 'Senha deve ter no mínimo 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmaSenhaField() {
    return TextFormField(
      controller: _confirmaSenhaController,
      obscureText: _obscureConfirma,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Confirmar Senha',
        icon: Icons.lock_outlined,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirma ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54,
          ),
          onPressed: () => setState(() => _obscureConfirma = !_obscureConfirma),
        ),
      ),
      validator: (value) {
        if (value != _senhaController.text) {
          return 'As senhas não conferem';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordRequirements() {
    final senha = _senhaController.text;
    final hasMinLength = senha.length >= 6;
    final hasUppercase = senha.contains(RegExp(r'[A-Z]'));
    final hasNumber = senha.contains(RegExp(r'[0-9]'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequirement('Mínimo 6 caracteres', hasMinLength),
          const SizedBox(height: 4),
          _buildRequirement('Uma letra maiúscula', hasUppercase),
          const SizedBox(height: 4),
          _buildRequirement('Um número', hasNumber),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: met ? Colors.green : Colors.white38,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: met ? Colors.green : Colors.white54,
          ),
        ),
      ],
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

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleRegister,
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
                Icon(Icons.person_add),
                SizedBox(width: 8),
                Text(
                  'CRIAR CONTA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Já tem conta? ',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Fazer login',
            style: TextStyle(
              color: _goldNeon,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(authNotifierProvider.notifier).signUp(
      email: _emailController.text.trim(),
      senha: _senhaController.text,
      nome: _nomeController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
