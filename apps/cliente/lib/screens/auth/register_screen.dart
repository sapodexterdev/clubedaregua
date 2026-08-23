import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/app_constants.dart';
import '../../core/auth_return_intent.dart';
import '../../providers/app_mode_controller.dart';
import '../../providers/app_state.dart';
import '../../screens/mode_selection_screen.dart';
import '../../screens/professional_mode_screen.dart';
import '../../theme/app_colors.dart';
import 'login_screen.dart';

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
        final modeController = context.read<AppModeController>();
        await modeController.synchronizeAccess(
          isSignedIn: appState.isSignedIn,
          userId: authService.currentUser?.id,
          professionalRoles: appState.professionalRoles,
        );
        if (!mounted) return;
        final returnRoute = ModalRoute.of(context)?.settings.arguments;
        if (returnRoute is AuthReturnIntent &&
            returnRoute.onAuthenticated != null) {
          navigator.popUntil(
            (route) => route.settings.name == LoginScreen.route,
          );
          navigator.pop();
          await returnRoute.onAuthenticated!();
          return;
        }
        navigator.pushReplacementNamed(
          returnRoute is AuthReturnIntent
              ? returnRoute.route
              : returnRoute is String
                  ? returnRoute
                  : appState.teamInvitationMessage != null ||
                          appState.teamInvitationError != null
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 68,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: CDRBackButton(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Center(
                  child: SvgPicture.asset(
                    AppConstants.brandV3SecondaryLogo,
                    width: 104,
                    semanticsLabel: 'Clube da Régua',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _hasTeamInvitation
                      ? 'Crie sua conta profissional'
                      : 'Crie sua conta',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _hasTeamInvitation
                      ? 'Use o mesmo e-mail do convite. Após a confirmação, o acesso à equipe será liberado automaticamente.'
                      : 'Faça parte do Clube para encontrar barbearias e organizar seus agendamentos.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                    height: 1.5,
                  ),
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
                const SizedBox(height: 8),
                const Text(
                  'Use pelo menos 6 caracteres.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 22),
                CDRButton.primary(
                  label: 'Criar conta',
                  onPressed: isLoading ? null : _register,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
