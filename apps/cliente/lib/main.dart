import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'providers/app_state.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    if (SupabaseConfig.canInitializeAuthSdk) {
      try {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        );
      } catch (_) {
        // Mantem o app navegavel com dados mockados se o backend falhar.
      }
    }

    runApp(
      ChangeNotifierProvider(
        create: (_) => AppState()..loadInitialData(),
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
        backgroundColor: const Color(0xFFF4F4F4),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFF6B2C),
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
                  style: const TextStyle(color: Color(0xFF8A8A8A)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
