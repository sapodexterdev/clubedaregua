import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'home_screen.dart';

class AppointmentConfirmationScreen extends StatelessWidget {
  const AppointmentConfirmationScreen({super.key});

  static const route = '/appointment-confirmation';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 62,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Solicitacao enviada',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Recebemos seu pedido. A barbearia vai confirmar o horario pelo WhatsApp.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 16),
              ),
              const SizedBox(height: 34),
              PrimaryButton(
                label: 'Voltar para home',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  HomeScreen.route,
                  (_) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
