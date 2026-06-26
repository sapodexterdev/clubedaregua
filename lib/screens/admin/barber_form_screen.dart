import 'package:flutter/material.dart';

import '../../widgets/primary_button.dart';

class BarberFormScreen extends StatelessWidget {
  const BarberFormScreen({super.key});

  static const route = '/admin-barber-form';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Barbeiros')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const TextField(decoration: InputDecoration(hintText: 'Nome')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(hintText: 'Email')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(hintText: 'Comissão (%)')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(hintText: 'URL da foto')),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Salvar barbeiro', onPressed: () {}),
        ],
      ),
    );
  }
}
