import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../../providers/app_state.dart';
import '../../screens/client/home_screen.dart';
import '../../screens/mode_selection_screen.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
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

  Future<void> _loginReal() async {
    setState(() => isLoading = true);
    try {
      final email = emailController.text.trim();
      final password = passwordController.text;
      if (email.isEmpty || password.isEmpty) {
        throw const AuthException('Informe e-mail e senha.');
      }

      await authService.signIn(email, password);
      if (mounted) await context.read<AppState>().loadInitialData();
      if (mounted) {
        context.read<AppState>().requireSignedIn();
        final returnRoute = ModalRoute.of(context)?.settings.arguments;
        Navigator.pushReplacementNamed(
          context,
          returnRoute is String
              ? returnRoute
              : context.read<AppState>().hasProfessionalAccess
                  ? ModeSelectionScreen.route
                  : HomeScreen.route,
        );
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _recoverPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Informe seu e-mail para recuperar a senha.');
      return;
    }

    setState(() => isLoading = true);
    try {
      await authService.recoverPassword(email);
      if (mounted) {
        _showMessage('Enviamos as instruções de recuperação para seu e-mail.');
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
              onSubmitted: isLoading ? null : (_) => _loginReal(),
            ),
            const SizedBox(height: 24),
            CDRButton.primary(
              label: 'ENTRAR',
              onPressed: isLoading ? null : _loginReal,
              isLoading: isLoading,
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                RegisterScreen.route,
                arguments: ModalRoute.of(context)?.settings.arguments,
              ),
              child: const Text('Criar conta'),
            ),
            TextButton(
              onPressed: isLoading ? null : _recoverPassword,
              child: const Text('Esqueci minha senha'),
            ),
          ],
        ),
      ),
    );
  }
}
