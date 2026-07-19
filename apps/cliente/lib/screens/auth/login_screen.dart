import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../screens/client/home_screen.dart';
import '../../screens/mode_selection_screen.dart';
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
        _sho
