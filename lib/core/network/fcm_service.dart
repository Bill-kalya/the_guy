import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/network/endpoints.dart';
import '../core/storage/secure_storage.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref);
});

class FcmService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  FcmService(this._ref);

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      _messaging.onTokenRefresh.listen(_registerToken);

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(
        Endpoints.notificationsFcmToken,
        data: {'token': token, 'platform': _getPlatform()},
      );
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.messageId}');
    final data = message.data;
    final type = data['type'] ?? 'UNKNOWN';

    // Show local notification banner
    _showLocalBanner(
      message.notification?.title ?? _defaultTitle(type),
      message.notification?.body ?? _defaultBody(type),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Message opened app: ${message.messageId}');
    final data = message.data;
    final jobId = data['jobId'];
    if (jobId != null && jobId.toString().isNotEmpty) {
      // Navigation would be handled by a navigator key
    }
  }

  void _showLocalBanner(String title, String body) {
    // Handled via overlay in the app widget
  }

  String _getPlatform() {
    return Theme.of(Widgets.platformDispatcher.views.first).platform ==
            TargetPlatform.iOS
        ? 'ios'
        : 'android';
  }

  String _defaultTitle(String type) {
    return switch (type) {
      'JOB_CREATED' => 'Job Requested',
      'JOB_ACCEPTED' => 'Job Accepted',
      'JOB_ACCEPTED_SUCCESS' => 'Job Confirmed',
      'JOB_STARTED' => 'Job In Progress',
      'JOB_AWAITING_CONFIRMATION' => 'Job Completed — Confirm?',
      'JOB_COMPLETED' => 'Job Completed',
      'JOB_CANCELLED' => 'Job Cancelled',
      _ => 'Notification',
    };
  }

  String _defaultBody(String type) {
    return switch (type) {
      'JOB_CREATED' => 'Your service request is being matched.',
      'JOB_ACCEPTED' => 'A provider has accepted your job.',
      'JOB_ACCEPTED_SUCCESS' => 'You\'ve been assigned this job.',
      'JOB_STARTED' => 'Your provider has started working.',
      'JOB_AWAITING_CONFIRMATION' => 'Please confirm the work is done.',
      'JOB_COMPLETED' => 'The job has been completed successfully.',
      'JOB_CANCELLED' => 'The job has been cancelled.',
      _ => '',
    };
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}
