import 'package:flutter/material.dart';

import '../../widgets/primary_button.dart';

class ServiceFormScreen extends StatelessWidget {
  const ServiceFormScreen({super.key});

  static const route = '/admin-service-form';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Serviços')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const TextField(decoration: InputDecoration(hintText: 'Nome do serviço')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(hintText: 'Preço')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(hintText: 'Duração em minutos')),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Salvar serviço', onPressed: () {}),
        ],
      ),
    );
  }
}
