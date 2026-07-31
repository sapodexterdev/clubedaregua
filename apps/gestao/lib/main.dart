import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'management.dart';

// Bootstrap exclusivo do build standalone de Gestão.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = ManagementSession();
  await session.restoreUnifiedSession();

  runApp(
    ChangeNotifierProvider.value(
      value: session,
      child: const ClubeDaReguaGestaoApp(),
    ),
  );
}
