import 'package:clubedaregua_gestao/management.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../../core/app_mode.dart';
import '../../providers/app_mode_controller.dart';
import '../../providers/app_state.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/owner_onboarding_screen.dart';
import '../../screens/professional_mode_screen.dart';
import '../../theme/app_colors.dart';
import '../../utils/whatsapp_input_formatter.dart';
import '../../widgets/premium_bottom_nav.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    this.onTabSelected,
    this.showBottomNavigation = true,
    this.showBackButton = false,
    super.key,
  });

  static const route = '/profile';
  final ValueChanged<int>? onTabSelected;
  final bool showBottomNavigation;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final activeMode = context.watch<AppModeController>().currentMode;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: showBackButton ? 68 : null,
        leading: showBackButton
            ? const Padding(
                padding: EdgeInsets.only(left: 16),
                child: CDRBackButton(),
              )
            : null,
        title: Text(
          'Meu perfil',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      bottomNavigationBar: showBottomNavigation && onTabSelected == null
          ? PremiumBottomNav(
              currentIndex: 3,
              onTap: (index) => _navigate(context, index),
            )
          : null,
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (!state.isSignedIn) return const _ProfileLoginRequired();
          return RefreshIndicator(
            color: AppColors.orange,
            onRefresh: state.refreshClientProfile,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: CDRSizeTokens.clientFrameMaxWidth,
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    CDRSpacingTokens.xxl,
                    CDRSpacingTokens.sm,
                    CDRSpacingTokens.xxl,
                    CDRSpacingTokens.xxxl,
                  ),
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
                          _ProfileAction(
                            icon: Icons.search_rounded,
                            title: 'Cliente',
                            subtitle: 'Descobrir barbearias e agendar horários',
                            selected: activeMode == AppMode.client,
                            onTap: () => _openMode(context, AppMode.client),
                          ),
                          if (state.hasBarberAccess)
                            _ProfileAction(
                              icon: Icons.content_cut_rounded,
                              title: 'Barbeiro',
                              subtitle: 'Sua agenda, clientes e comissão',
                              selected: activeMode == AppMode.barber,
                              onTap: () => _openMode(
                                context,
                                AppMode.barber,
                              ),
                            ),
                          if (state.hasOwnerAccess)
                            _ProfileAction(
                              icon: Icons.storefront_rounded,
                              title: 'Dono',
                              subtitle: 'Gestão completa da barbearia',
                              selected: activeMode == AppMode.owner,
                              onTap: () => _openMode(
                                context,
                                AppMode.owner,
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
                    if (!showBackButton) ...[
                      const _SectionLabel('ATIVIDADE'),
                      const SizedBox(height: 10),
                      _ActionGroup(
                        children: [
                          _ProfileAction(
                            icon: Icons.calendar_month_outlined,
                            title: 'Meus agendamentos',
                            subtitle: 'Acompanhe seus pedidos e horários',
                            onTap: () => _navigate(context, 2),
                          ),
                          _ProfileAction(
                            icon: Icons.favorite_border_rounded,
                            title: 'Barbearias favoritas',
                            subtitle: 'Veja as barbearias que você salvou',
                            onTap: () => _navigate(context, 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context, state),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sair da conta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        minimumSize: const Size.fromHeight(54),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(CDRRadiusTokens.medium),
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

  Future<void> _navigate(BuildContext context, int index) async {
    final shellSelection = onTabSelected;
    if (shellSelection != null) {
      shellSelection(index);
      return;
    }
    final route = switch (index) {
      0 => HomeScreen.route,
      1 => FavoritesScreen.route,
      2 => HistoryScreen.route,
      3 => ProfileScreen.route,
      _ => HomeScreen.route,
    };
    if (route != ProfileScreen.route) {
      await context.read<AppModeController>().selectMode(AppMode.client);
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, route);
    }
  }

  static Future<void> _openMode(BuildContext context, AppMode mode) async {
    final controller = context.read<AppModeController>();
    final activeMode = controller.currentMode;
    final returnMode = ModalRoute.of(context)?.settings.arguments;
    if (mode == activeMode) {
      if (returnMode == activeMode && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }

    final selected = await controller.selectMode(mode);
    if (!selected || !context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      ProfessionalModeScreen.routeFor(mode),
      (_) => false,
    );
  }

  static Future<void> _showEditProfile(
    BuildContext context,
    AppState state,
  ) async {
    final nameController = TextEditingController(text: state.currentUserName);
    final phoneController = TextEditingController(
      text: formatWhatsapp(state.currentUserPhone),
    );
    final formKey = GlobalKey<FormState>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          CDRSpacingTokens.xl,
          CDRSpacingTokens.sm,
          CDRSpacingTokens.xl,
          MediaQuery.viewInsetsOf(sheetContext).bottom + CDRSpacingTokens.xxl,
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
                style: Theme.of(sheetContext).textTheme.headlineSmall,
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
                inputFormatters: const [WhatsappInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'WhatsApp',
                  hintText: '(00)00000-0000',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.isEmpty) return null;
                  return digits.length == 11
                      ? null
                      : 'Use o formato (00)00000-0000.';
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
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
              ),
            ],
          ),
        ),
      ),
    );
    nameController.dispose();
    phoneController.dispose();
    if (saved == true && context.mounted) {
      CDRSnackbar.success(context, 'Dados atualizados com sucesso.');
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
        CDRSnackbar.success(
          context,
          'Enviamos o link de segurança para $email.',
        );
      }
    } on AuthException {
      if (context.mounted) {
        CDRSnackbar.error(
          context,
          'Não foi possível enviar o link de segurança. Tente novamente.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        CDRSnackbar.error(
          context,
          'Não foi possível enviar o link de segurança. Tente novamente.',
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
    if (!context.mounted) return;
    final modeController = context.read<AppModeController>();
    final managementSession = context.read<ManagementSession>();
    await state.signOut();
    managementSession.clearUnifiedSession();
    await modeController.resetToClient();
    if (!context.mounted) return;
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
    return CDRCard(
      padding: const EdgeInsets.all(CDRSpacingTokens.lg),
      child: Row(
        children: [
          CDRAvatar(
            name: displayName,
            size: 62,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: CDRSpacingTokens.lg),
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
                    formatWhatsapp(state.currentUserPhone),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (state.isLoadingClientProfile) const CDRLoading.compact(size: 22),
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
        style: CDRTypographyTokens.overline.copyWith(
          color: AppColors.orange,
        ),
      );
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
          side: const BorderSide(color: AppColors.stroke),
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
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        child: ListTile(
          onTap: onTap,
          selected: selected,
          selectedTileColor: AppColors.orange,
          minVerticalPadding: CDRSpacingTokens.md,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.onGold.withOpacity(.12)
                  : AppColors.orange.withOpacity(.1),
              borderRadius: BorderRadius.circular(CDRRadiusTokens.medium),
            ),
            child: Icon(
              icon,
              color: selected ? AppColors.onGold : AppColors.orange,
              size: CDRSizeTokens.icon,
            ),
          ),
          title: Text(
            title,
            style: CDRTypographyTokens.label.copyWith(
              color: selected ? AppColors.onGold : AppColors.text,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: CDRTypographyTokens.bodySmall.copyWith(
              color: selected ? AppColors.onGold : AppColors.muted,
            ),
          ),
          trailing: Icon(
            selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
            color: selected ? AppColors.onGold : AppColors.muted,
          ),
        ),
      );
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => CDRStatePanel(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
        title: 'Dados temporariamente indisponíveis',
        message: message,
        layout: CDRStatePanelLayout.inline,
        liveRegion: true,
        backgroundColor: AppColors.elevated,
        borderColor: AppColors.error.withOpacity(.45),
      );
}

class _ProfileLoginRequired extends StatelessWidget {
  const _ProfileLoginRequired();

  @override
  Widget build(BuildContext context) => CDREmptyState(
        icon: Icons.person_outline_rounded,
        title: 'Seu espaço no Clube',
        message: 'Entre para acessar seus dados, agenda e favoritos.',
        actionLabel: 'Entrar na minha conta',
        onAction: () => Navigator.pushNamed(
          context,
          LoginScreen.route,
          arguments: ProfileScreen.route,
        ),
      );
}
