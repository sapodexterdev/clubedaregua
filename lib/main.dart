import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'providers/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..loadInitialData(),
      child: const ClubeDaReguaApp(),
    ),
  );
}
