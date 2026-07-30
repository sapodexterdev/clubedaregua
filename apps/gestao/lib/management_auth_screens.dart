part of 'main.dart';

class _ProfessionalAccessDeniedScreen extends StatelessWidget {
  const _ProfessionalAccessDeniedScreen({
    this.onOpenClientMode = _ignoreClientModeNavigation,
  });

  final VoidCallback onOpenClientMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const _IconBadge(Icons.lock_person_outlined),
                  const SizedBox(height: 18),
                  Text(
                    'Acesso profissional não encontrado',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Esta conta pode continuar usando o Clube da Régua como cliente. Para acessar a área profissional, ela precisa estar vinculada como barbeiro ou responsável por uma barbearia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SharedAppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CDRButton.primary(
                    label: 'VOLTAR AO MODO CLIENTE',
                    onPressed: onOpenClientMode,
                    leading: const Icon(Icons.search_rounded),
                  ),
                  const SizedBox(height: 10),
                  CDRButton.ghost(
                    label: 'SAIR DA CONTA',
                    onPressed: context.read<ManagementSession>().signOut,
                    leading: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ManagementLoginScreen extends StatefulWidget {
  const ManagementLoginScreen({super.key});

  @override
  State<ManagementLoginScreen> createState() => _ManagementLoginScreenState();
}

class _ManagementLoginScreenState extends State<ManagementLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ManagementSession>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/splash_v3_loading_v3.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB8050505),
                  Color(0xE609090B),
                  Color(0xFA09090B),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                    decoration: BoxDecoration(
                      color: const Color(0xF2111114),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFF34343A)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 36,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: SvgPicture.asset(
                              'assets/images/brand_v3_logo_principal.svg',
                              width: 176,
                              height: 118,
                              fit: BoxFit.contain,
                              semanticsLabel: 'Clube da Régua',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1AF3B200),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0x73F3B200),
                                ),
                              ),
                              child: const Text(
                                'PORTAL DE GESTÃO',
                                style: TextStyle(
                                  color: SharedAppColors.orange,
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Sua barbearia, sob controle.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: SharedAppColors.text,
                              fontFamily: 'Barlow Condensed',
                              fontSize: 27,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Acesse pedidos, agenda, equipe e toda a operação em um só lugar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: SharedAppColors.muted,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 26),
                          CDRTextField(
                            controller: _emailController,
                            label: 'E-mail profissional',
                            leading: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                          ),
                          const SizedBox(height: 14),
                          CDRPasswordField(
                            controller: _passwordController,
                            onSubmitted: session.isLoading
                                ? null
                                : (_) => session.signIn(
                                      _emailController.text,
                                      _passwordController.text,
                                    ),
                          ),
                          const SizedBox(height: 18),
                          CDRButton.primary(
                            label: 'ENTRAR NO PORTAL',
                            onPressed: session.isLoading
                                ? null
                                : () => session.signIn(
                                      _emailController.text,
                                      _passwordController.text,
                                    ),
                            isLoading: session.isLoading,
                          ),
                          if (session.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0x1FEF4444),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0x66EF4444),
                                ),
                              ),
                              child: Text(
                                session.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFFA3A3),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 15,
                                color: SharedAppColors.muted,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Acesso seguro para profissionais autorizados',
                                style: TextStyle(
                                  color: SharedAppColors.muted,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key, required this.session});

  final PasswordRecoverySession session;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _isLoading = false;
  var _isDone = false;
  var _showLogin = false;
  String? _message;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.length < 6) {
      setState(() => _message = 'A senha precisa ter pelo menos 6 caracteres.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _message = 'As senhas digitadas não conferem.');
      return;
    }

    if (!SupabaseConfig.isConfigured) {
      setState(() => _message = 'Configure SUPABASE_URL e SUPABASE_ANON_KEY.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await _sendPasswordUpdate(
        accessToken: widget.session.accessToken,
        password: password,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final refreshedAccessToken = await _refreshRecoverySession();
        if (refreshedAccessToken == null) {
          throw StateError(_supabaseErrorMessage(response));
        }

        final retryResponse = await _sendPasswordUpdate(
          accessToken: refreshedAccessToken,
          password: password,
        );

        if (retryResponse.statusCode < 200 || retryResponse.statusCode >= 300) {
          throw StateError(_supabaseErrorMessage(retryResponse));
        }
      }

      setState(() {
        _isDone = true;
        _message = 'Senha redefinida com sucesso.';
      });
    } catch (error) {
      setState(() => _message = _cleanErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^\s*Bad state:\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^\s*Exception:\s*', caseSensitive: false), '');
  }

  Future<http.Response> _sendPasswordUpdate({
    required String accessToken,
    required String password,
  }) {
    return http.put(
      Uri.parse('${SupabaseConfig.url}/auth/v1/user'),
      headers: {
        'apikey': SupabaseConfig.anonKey,
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      },
      body: jsonEncode({'password': password}),
    );
  }

  Future<String?> _refreshRecoverySession() async {
    final refreshToken = widget.session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await http.post(
      Uri.parse('${SupabaseConfig.url}/auth/v1/token').replace(
        queryParameters: {'grant_type': 'refresh_token'},
      ),
      headers: {
        'apikey': SupabaseConfig.anonKey,
        'content-type': 'application/json',
      },
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['access_token']?.toString();
  }

  String _supabaseErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message =
          body['msg'] ?? body['message'] ?? body['error_description'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    } catch (_) {
      // Keep the fallback below when Supabase returns an empty or non-JSON body.
    }

    return 'Não foi possível redefinir a senha. Gere um novo link e tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return const ManagementLoginScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    _isDone
                        ? Icons.check_circle_rounded
                        : Icons.lock_reset_rounded,
                    color: _isDone
                        ? Colors.green.shade700
                        : SharedAppColors.orange,
                    size: 58,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _isDone ? 'Senha redefinida' : 'Redefinir senha',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isDone
                        ? 'Agora você já pode entrar com sua nova senha.'
                        : 'Digite sua nova senha para acessar a gestão.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: SharedAppColors.muted),
                  ),
                  const SizedBox(height: 28),
                  if (!_isDone) ...[
                    CDRPasswordField(
                      controller: _passwordController,
                      label: 'Nova senha',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    CDRPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar nova senha',
                      onSubmitted: _isLoading ? null : (_) => _updatePassword(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  CDRButton.primary(
                    label: _isDone ? 'ENTRAR' : 'SALVAR SENHA',
                    onPressed: _isLoading
                        ? null
                        : _isDone
                            ? () => setState(() => _showLogin = true)
                            : _updatePassword,
                    isLoading: _isLoading,
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isDone ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
