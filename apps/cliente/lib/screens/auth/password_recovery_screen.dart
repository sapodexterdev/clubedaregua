import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_mode.dart';
import '../../providers/app_mode_controller.dart';
import '../../theme/app_colors.dart';
import '../client/home_screen.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  static const route = '/auth/recover';

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isSaving = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await AuthService().updatePassword(_passwordController.text);
      if (!mounted) return;
      await context.read<AppModeController>().selectMode(AppMode.client);
      if (!mounted) return;
      CDRSnackbar.success(context, 'Senha atualizada com sucesso.');
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeScreen.route,
        (_) => false,
      );
    } on AuthException {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível atualizar a senha. Solicite um novo link e tente novamente.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível atualizar a senha.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: CDRSizeTokens.clientFrameMaxWidth,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                CDRSpacingTokens.xxl,
                CDRSpacingTokens.xxl,
                CDRSpacingTokens.xxl,
                CDRSpacingTokens.xxxl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (Navigator.of(context).canPop())
                          const CDRBackButton()
                        else
                          const SizedBox(width: 44),
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
                    const SizedBox(height: CDRSpacingTokens.xxxl),
                    Text(
                      'Crie uma nova senha',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Escolha uma nova senha com pelo menos 8 caracteres.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 28),
                    AutofillGroup(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isSaving,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Nova senha',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                tooltip: _hidePassword
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                onPressed: _isSaving
                                    ? null
                                    : () => setState(
                                          () => _hidePassword = !_hidePassword,
                                        ),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').length < 8) {
                                return 'Use pelo menos 8 caracteres.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: CDRSpacingTokens.lg),
                          TextFormField(
                            controller: _confirmationController,
                            enabled: !_isSaving,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: _isSaving ? null : (_) => _save(),
                            decoration: const InputDecoration(
                              labelText: 'Confirmar nova senha',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'As senhas não coincidem.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: CDRSpacingTokens.lg),
                      CDRStatePanel(
                        icon: Icons.error_outline_rounded,
                        iconColor: CDRColorTokens.error,
                        title: 'Não foi possível atualizar',
                        message: _error!,
                        liveRegion: true,
                        layout: CDRStatePanelLayout.inline,
                        backgroundColor: AppColors.card,
                        borderColor: CDRColorTokens.error,
                      ),
                    ],
                    const SizedBox(height: CDRSpacingTokens.xxl),
                    CDRButton.primary(
                      label: 'Atualizar senha',
                      onPressed: _isSaving ? null : _save,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
