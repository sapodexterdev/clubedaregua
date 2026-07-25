import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/app_state.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/owner_onboarding_screen.dart';
import '../../services/auth_service.dart';
import '../../services/app_mode_navigation.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_bottom_nav.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const route = '/profile';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Meu perfil',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: 3,
        onTap: (index) => _navigate(context, index),
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (!state.isSignedIn) return const _ProfileLoginRequired();
          return RefreshIndicator(
            color: AppColors.orange,
            onRefresh: state.refreshClientProfile,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: CDRSizeTokens.contentMaxWidth,
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                  children: [
                _IdentityCard(state: state),
                if (state.clientProfileError != null) ...[
                  const SizedBox(height: 12),
                  _ErrorMessage(message: state.clientProfileError!),
                ],
                const SizedBox(height: 24),
                if (!state.hasProfessionalAccess) ...[
                  const _SectionLabel('PARA BARBEARIAS'),
                  const SizedBox(height: 10),
                  _ActionGroup(
                    children: [
                      _ProfileAction(
                        icon: Icons.storefront_rounded,
                        title: 'Cadastrar minha barbearia',
                        subtitle:
                            'Experimente o Plano Pro gratuitamente por 14 dias',
                        onTap: () => Navigator.pushNamed(
                          context,
                          OwnerOnboardingScreen.route,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                if (state.hasProfessionalAccess) ...[
                  const _SectionLabel('MODOS DO APP'),
                  const SizedBox(height: 10),
                  _ActionGroup(
                    children: [
                      if (state.hasBarberAccess)
                        _ProfileAction(
                          icon: Icons.content_cut_rounded,
                          title: 'Modo barbeiro',
                          subtitle: 'Sua agenda, clientes e comissão',
                          onTap: () => _openProfessionalMode(
                            'barber',
                            openBarberMode,
                          ),
                        ),
                      if (state.hasOwnerAccess)
                        _ProfileAction(
                          icon: Icons.storefront_rounded,
                          title: 'Modo dono',
                          subtitle: 'Gestão completa da barbearia',
                          onTap: () => _openProfessionalMode(
                            'owner',
                            openOwnerMode,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                const _SectionLabel('CONTA'),
                const SizedBox(height: 10),
                _ActionGroup(
                  children: [
                    _ProfileAction(
                      icon: Icons.edit_outlined,
                      title: 'Editar dados pessoais',
                      subtitle: 'Nome e WhatsApp',
                      onTap: state.isLoadingClientProfile
                          ? null
                          : () => _showEditProfile(context, state),
                    ),
                    _ProfileAction(
                      icon: Icons.lock_reset_rounded,
                      title: 'Segurança',
                      subtitle: 'Receber link para redefinir a senha',
                      onTap: () => _sendPasswordRecovery(context, state),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionLabel('ATIVIDADE'),
                const SizedBox(height: 10),
                _ActionGroup(
                  children: [
                    _ProfileAction(
                      icon: Icons.calendar_month_outlined,
                      title: 'Meus agendamentos',
                      subtitle: 'Acompanhe seus pedidos e horários',
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        HistoryScreen.route,
                      ),
                    ),
                    _ProfileAction(
                      icon: Icons.favorite_border_rounded,
                      title: 'Barbearias favoritas',
                      subtitle: 'Veja as barbearias que você salvou',
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        FavoritesScreen.route,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context, state),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sair da conta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(color: AppColors.stroke),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static void _navigate(BuildContext context, int index) {
    final route = switch (index) {
      0 => HomeScreen.route,
      1 => FavoritesScreen.route,
      2 => HistoryScreen.route,
      3 => ProfileScreen.route,
      _ => HomeScreen.route,
    };
    if (route != ProfileScreen.route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  static Future<void> _openProfessionalMode(
    String mode,
    VoidCallback navigate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(appLastModeKey, mode);
    navigate();
  }

  static Future<void> _showEditProfile(
    BuildContext context,
    AppState state,
  ) async {
    final nameController = TextEditingController(text: state.currentUserName);
    final phoneController = TextEditingController(text: state.currentUserPhone);
    final formKey = GlobalKey<FormState>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.stroke,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Editar dados pessoais',
                style: Theme.of(sheetContext)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => value == null || value.trim().length < 3
                    ? 'Informe seu nome completo.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(
                  labelText: 'WhatsApp',
                  hintText: '(34) 99999-9999',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final success = await state.updateClientProfile(
                    fullName: nameController.text,
                    phone: phoneController.text,
                  );
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext, success);
                  }
                },
                child: const Text('Salvar alterações'),
              ),
            ],
          ),
        ),
      ),
    );
    nameController.dispose();
    phoneController.dispose();
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso.')),
      );
    }
  }

  static Future<void> _sendPasswordRecovery(
    BuildContext context,
    AppState state,
  ) async {
    final email = state.currentUserEmail?.trim();
    if (email == null || email.isEmpty) return;
    try {
      await AuthService().recoverPassword(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enviamos o link de segurança para $email.')),
        );
      }
    } on AuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível enviar o link.')),
        );
      }
    }
  }

  static Future<void> _confirmSignOut(
    BuildContext context,
    AppState state,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará entrar novamente para acessar agenda e favoritos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await state.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeScreen.route,
        (_) => false,
      );
    }
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final name = state.currentUserName?.trim();
    final displayName = name == null || name.isEmpty ? 'Cliente' : name;
    final initial = displayName.substring(0, 1).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.orange),
            ),
            child: Text(
              initial,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.orange,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  state.currentUserEmail ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                if (state.currentUserPhone?.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    state.currentUserPhone!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (state.isLoadingClientProfile)
            const CDRLoading.compact(size: 22),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.orange,
          fontSize: 12,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w800,
        ),
      );
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1)
                const Divider(height: 1, color: AppColors.stroke),
            ],
          ],
        ),
      );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        minVerticalPadding: 13,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.orange, size: 21),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.muted,
        ),
      );
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      );
}

class _ProfileLoginRequired extends StatelessWidget {
  const _ProfileLoginRequired();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.orange,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Seu espaço no Clube',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Entre para acessar seus dados, agenda e favoritos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  LoginScreen.route,
                  arguments: ProfileScreen.route,
                ),
                child: const Text('Entrar na minha conta'),
              ),
            ],
          ),
        ),
      );
}
