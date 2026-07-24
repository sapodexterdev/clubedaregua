import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.orange, size: 42),
              const SizedBox(height: 22),
              const Text(
                'Como você quer entrar?',
                style: TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Olá, ${state.currentUserName?.trim().isNotEmpty == true ? state.currentUserName!.trim() : 'profissional'}. Escolha sua experiência no Clube da Régua.',
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
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
              const Spacer(),
              const Text(
                'Você poderá trocar de modo novamente pelo seu perfil.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
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
                    Text(description,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35)),
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
