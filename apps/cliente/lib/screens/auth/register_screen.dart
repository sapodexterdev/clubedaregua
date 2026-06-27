import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../screens/client/home_screen.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const route = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    try {
      await authService.signUp(
        emailController.text,
        passwordController.text,
        nameController.text,
      );
      if (mounted) {
        await context.read<AppState>().loadInitialData();
      }
    } catch (_) {}
    if (mounted) Navigator.pushReplacementNamed(context, HomeScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'Criar conta',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Entre para o clube e acumule pontos a cada corte.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Nome completo'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(hintText: 'Email'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Senha'),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Cadastrar', onPressed: _register),
        ],
      ),
    );
  }
}
