import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/config/env.dart';
import 'core/storage/shared_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.isDevelopment) {
    debugPrint('🚀 The Guy app starting in development mode');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TheGuyApp(),
    ),
  );
}