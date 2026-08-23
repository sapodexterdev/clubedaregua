import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/app_constants.dart';
import '../../core/auth_return_intent.dart';
import '../../providers/app_mode_controller.dart';
import '../../providers/app_state.dart';
import '../../screens/client/home_screen.dart';
import '../../screens/mode_selection_screen.dart';
import '../../screens/professional_mode_screen.dart';
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

  bool get _hasTeamInvitation =>
      Uri.base.queryParameters['team_invite']?.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    emailController.text =
        Uri.base.queryParameters['invite_email']?.trim() ?? '';
  }

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
        final state = context.read<AppState>()..requireSignedIn();
        final modeController = context.read<AppModeController>();
        await modeController.synchronizeAccess(
          isSignedIn: state.isSignedIn,
          userId: authService.currentUser?.id,
          professionalRoles: state.professionalRoles,
        );
        if (!mounted) return;
        final returnRoute = ModalRoute.of(context)?.settings.arguments;
        if (returnRoute is AuthReturnIntent &&
            returnRoute.onAuthenticated != null) {
          Navigator.pop(context);
          await returnRoute.onAuthenticated!();
          return;
        }
        Navigator.pushReplacementNamed(
          context,
          returnRoute is AuthReturnIntent
              ? returnRoute.route
              : returnRoute is String
                  ? returnRoute
                  : state.teamInvitationMessage != null ||
                          state.teamInvitationError != null
                      ? ModeSelectionScreen.route
                      : ProfessionalModeScreen.routeFor(
                          modeController.currentMode,
                        ),
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

  void _goBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(HomeScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Row(
                  children: [
                    CDRBackButton(onPressed: () => _goBack(context)),
                    Expanded(
                      child: Center(
                        child: SvgPicture.asset(
                          AppConstants.brandV3SecondaryLogo,
                          width: 132,
                          semanticsLabel: 'Clube da Régua',
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  _hasTeamInvitation
                      ? 'Acesse seu convite'
                      : 'Bem-vindo de volta',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _hasTeamInvitation
                      ? 'Entre com o e-mail convidado para liberar seu acesso profissional.'
                      : 'Entre para agendar, acompanhar seus horários e acessar seu perfil.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
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
                const SizedBox(height: 22),
                CDRButton.primary(
                  label: 'Entrar',
                  onPressed: isLoading ? null : _loginReal,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading ? null : _recoverPassword,
                  child: const Text('Esqueci minha senha'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Flexible(
                      child: Text(
                        'Ainda não faz parte do Clube?',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RegisterScreen.route,
                        arguments: ModalRoute.of(context)?.settings.arguments,
                      ),
                      child: const Text('Criar conta'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
