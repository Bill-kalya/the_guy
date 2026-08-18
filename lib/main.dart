import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/config/env.dart';
import 'core/network/fcm_service.dart';
import 'core/storage/shared_prefs.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('[FCM] Background message: ${message.messageId}');
}

void main() async {
  final _now = DateTime.now();
  print(
      'BUILD: ${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}-002');
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.isDevelopment) {
    print('🚀 The Guy app starting in development mode');
  }

  try {
    await Firebase.initializeApp();
    print('[FCM] Firebase initialized successfully');
  } catch (e, st) {
    print('[FCM] Firebase init error: $e');
    print('[FCM] Stack trace: $st');
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  if (Env.stripePublishableKey.isNotEmpty) {
    try {
      Stripe.publishableKey = Env.stripePublishableKey;
      await Stripe.instance.applySettings();
      print('[Stripe] Initialized successfully');
    } catch (e, st) {
      print('[Stripe] Init error: $e');
      print('[Stripe] Stack trace: $st');
    }
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
