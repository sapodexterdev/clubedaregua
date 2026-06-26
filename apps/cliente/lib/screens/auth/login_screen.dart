import 'package:flutter/material.dart';

import '../../screens/client/home_screen.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => isLoading = true);
    try {
      if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
        await authService.signIn(emailController.text, passwordController.text);
      }
    } catch (_) {
      // Mantém o app navegável com dados mockados durante o desenvolvimento.
    }
    setState(() => isLoading = false);

    if (mounted) Navigator.pushReplacementNamed(context, HomeScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 28),
            const Text(
              'Entrar',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Acesse sua agenda premium.',
              style: TextStyle(color: AppColors.muted, fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Email'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Senha'),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: isLoading ? 'Entrando...' : 'Entrar',
              onPressed: isLoading ? null : _login,
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, RegisterScreen.route),
              child: const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
