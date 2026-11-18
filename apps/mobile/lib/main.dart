import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/theme.dart';
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with placeholders or local configs
  try {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://placeholder.supabase.co'),
      // ignore: deprecated_member_use
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'placeholder-anon-key'),
    );
  } catch (_) {
    // Allows previewing and development testing even in standalone mode
  }

  runApp(const ProviderScope(child: OMRScanApp()));
}

class OMRScanApp extends StatelessWidget {
  const OMRScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OMR Scan System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
