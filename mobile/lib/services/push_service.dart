import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushService {
  static String? currentToken;
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      currentToken = await messaging.getToken();

      messaging.onTokenRefresh.listen((newToken) {
        currentToken = newToken;
      });

      // Show a snackbar when a notification arrives while the app is open
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title;
        final body = message.notification?.body;
        if (title != null || body != null) {
          messengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text([title, body].where((e) => e != null).join(" — ")),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint("Push notification setup failed: $e");
    }
  }
}
