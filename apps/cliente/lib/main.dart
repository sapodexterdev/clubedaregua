import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/app_mode_controller.dart';
import 'providers/app_state.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppModeController()),
          ChangeNotifierProvider(
            create: (_) => AppState()..loadInitialData(),
          ),
        ],
        child: const ClubeDaReguaApp(),
      ),
    );
  }, (error, stackTrace) {
    runApp(StartupErrorApp(error: error));
  });
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFF3B200),
                  size: 56,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Não foi possível iniciar o Clube da Régua',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFA1A1AA)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
