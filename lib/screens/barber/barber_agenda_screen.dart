import 'package:flutter/material.dart';

import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/time_selector.dart';

class BarberAgendaScreen extends StatefulWidget {
  const BarberAgendaScreen({super.key});

  static const route = '/barber-agenda';

  @override
  State<BarberAgendaScreen> createState() => _BarberAgendaScreenState();
}

class _BarberAgendaScreenState extends State<BarberAgendaScreen> {
  final blocked = <String>{'13:00'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda Barbeiro')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Horarios disponiveis',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TimeSelector(
            times: MockData.times,
            selectedTime: blocked.isEmpty ? '' : blocked.first,
            onSelected: (time) {
              setState(() {
                blocked.contains(time) ? blocked.remove(time) : blocked.add(time);
              });
            },
          ),
          const SizedBox(height: 22),
          const Text(
            'Bloqueados',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...blocked.map(
            (time) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block_rounded, color: AppColors.orange),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Horario bloqueado: $time')),
                  TextButton(
                    onPressed: () => setState(() => blocked.remove(time)),
                    child: const Text('Liberar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
