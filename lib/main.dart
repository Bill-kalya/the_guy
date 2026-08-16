import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/config/env.dart';
import 'core/storage/shared_prefs.dart';

void main() async {
  final _now = DateTime.now();
  debugPrint(
      'BUILD: ${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}-001');
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.isDevelopment) {
    debugPrint('🚀 The Guy app starting in development mode');
  }

  if (Env.stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = Env.stripePublishableKey;
    await Stripe.instance.applySettings();
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