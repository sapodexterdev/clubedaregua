import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../../providers/app_state.dart';
import '../../screens/client/home_screen.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

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
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final appState = context.read<AppState>();
    final navigator = Navigator.of(context);

    setState(() => isLoading = true);
    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text;
      if (name.length < 3 || email.isEmpty || password.length < 6) {
        throw const AuthException(
          'Informe nome, e-mail e uma senha com pelo menos 6 caracteres.',
        );
      }

      final session = await authService.signUp(
        email,
        password,
        name,
      );
      if (session == null) {
        if (mounted) {
          _showMessage('Cadastro criado. Confirme seu e-mail para entrar.');
        }
        return;
      }

      if (mounted) {
        await appState.loadInitialData();
        if (!mounted) return;
        appState.requireSignedIn();
        final returnRoute = ModalRoute.of(context)?.settings.arguments;
        navigator.pushReplacementNamed(
          returnRoute is String ? returnRoute : HomeScreen.route,
        );
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          CDRTextField(
            controller: nameController,
            label: 'Nome completo',
            leading: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 14),
          CDRTextField(
            controller: emailController,
            label: 'E-mail',
            leading: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 14),
          CDRPasswordField(
            controller: passwordController,
            onSubmitted: isLoading ? null : (_) => _register(),
          ),
          const SizedBox(height: 24),
          CDRButton.primary(
            label: 'CRIAR CONTA',
            onPressed: isLoading ? null : _register,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}
