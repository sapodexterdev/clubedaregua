import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_constants.dart';
import '../providers/app_state.dart';
import '../services/app_mode_navigation.dart';
import '../theme/app_colors.dart';
import 'client/home_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  static const route = '/choose-mode';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  AppConstants.brandV3SecondaryLogo,
                  width: 112,
                  semanticsLabel: 'Clube da Régua',
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Como você quer entrar?',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Olá, ${state.currentUserName?.trim().isNotEmpty == true ? state.currentUserName!.trim() : 'profissional'}. Escolha sua experiência no Clube da Régua.',
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
              if (state.teamInvitationMessage != null) ...[
                const SizedBox(height: 18),
                _AccessNotice(
                  icon: Icons.verified_rounded,
                  message: state.teamInvitationMessage!,
                  isSuccess: true,
                ),
              ],
              if (state.teamInvitationError != null) ...[
                const SizedBox(height: 18),
                _AccessNotice(
                  icon: Icons.error_outline_rounded,
                  message: state.teamInvitationError!,
                ),
              ],
              const SizedBox(height: 30),
              _ModeCard(
                icon: Icons.search_rounded,
                title: 'Entrar como cliente',
                description: 'Descobrir barbearias, agendar e acompanhar seus horários.',
                onTap: () => _openClientMode(context),
              ),
              if (state.hasBarberAccess) ...[
                const SizedBox(height: 14),
                _ModeCard(
                  icon: Icons.content_cut_rounded,
                  title: 'Entrar como barbeiro',
                  description:
                      'Acessar sua agenda, solicitações, clientes e comissão.',
                  highlighted: true,
                  onTap: () => _openProfessionalMode(
                    'barber',
                    openBarberMode,
                  ),
                ),
              ],
              if (state.hasOwnerAccess) ...[
                const SizedBox(height: 14),
                _ModeCard(
                  icon: Icons.storefront_rounded,
                  title: 'Entrar como dono',
                  description:
                      'Gerenciar equipe, serviços e operação da barbearia.',
                  highlighted: true,
                  onTap: () => _openProfessionalMode(
                    'owner',
                    openOwnerMode,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              const Text(
                'Você poderá trocar de modo novamente pelo seu perfil.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openClientMode(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(appLastModeKey, 'client');
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      HomeScreen.route,
      (_) => false,
    );
  }

  Future<void> _openProfessionalMode(
    String mode,
    VoidCallback navigate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(appLastModeKey, mode);
    navigate();
  }
}

class _AccessNotice extends StatelessWidget {
  const _AccessNotice({
    required this.icon,
    required this.message,
    this.isSuccess = false,
  });

  final IconData icon;
  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSuccess
              ? AppColors.orange.withOpacity(.10)
              : const Color(0x1FEF4444),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSuccess ? AppColors.orange : const Color(0x66EF4444),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSuccess ? AppColors.orange : const Color(0xFFFF8A8A),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: highlighted ? AppColors.orange.withOpacity(.10) : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlighted ? AppColors.orange : AppColors.stroke,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.orange),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.orange, size: 16),
            ],
          ),
        ),
      );
}
