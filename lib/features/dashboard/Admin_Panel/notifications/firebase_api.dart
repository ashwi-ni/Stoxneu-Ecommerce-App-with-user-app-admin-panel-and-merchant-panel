  import 'dart:convert';
  import 'package:firebase_messaging/firebase_messaging.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:flutter/foundation.dart';
  import 'package:flutter_local_notifications/flutter_local_notifications.dart';
  import '../../../../config/api_config.dart';
import '../../../../core/network/api_client.dart'; // Ensure this path is correct
  import 'package:universal_html/html.dart' as html;
  @pragma('vm:entry-point')
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await Firebase.initializeApp();
    print("Background Msg: ${message.notification?.title}");
  }

  class FirebaseApi {
    final _firebaseMessaging = FirebaseMessaging.instance;
    final _localNotifications = FlutterLocalNotificationsPlugin();

    final _androidChannel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    // CALL THIS AT APP STARTUP INSIDE main.dart
    Future<void> initNotifications() async {
     // if (kIsWeb) return;

      // 1. Request Local System Permissions
      await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

      // 2. Initialize Local Notifications Framework
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      final platform = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await platform?.createNotificationChannel(_androidChannel);

      // 3. Register Global Handlers
      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Foreground Msg Received: ${message.notification?.title}");
        final notification = message.notification;
        if (notification == null) return;

        // 🌐 WEB POP-UP LOGIC
        if (kIsWeb) {
          if (html.Notification.permission == 'granted') {
            // Fix: Native HTML Notification takes title, body, and icon directly
            html.Notification(
              notification.title ?? 'New Alert',
              body: notification.body ?? '',
              icon: 'icons/Icon-192.png',
            );
          } else {
            print("WARNING: Browser notification permissions are blocked.");
          }
          return; // Stop execution so mobile code doesn't execute on Web
        }

        // 📱 MOBILE POP-UP LOGIC (Android/iOS)
        // Fix: Converted all positional parameters to named parameters as required by the SDK
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      });


    }

    // MOVE THIS CODE BLOCK TO RUN POST-LOGIN
    static Future<void> syncDeviceTokenWithIdentity() async {
      try {
        String? token;

        if (kIsWeb) {
          print("INFO: Processing authentication within Browser. Extracting Web FCM Token...");

          // 🔴 ADD THIS: Request browser notification permissions explicitly
          NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
            alert: true, badge: true, sound: true,
          );

          if (settings.authorizationStatus != AuthorizationStatus.authorized) {
            print("WARNING: Merchant denied browser notification permissions.");
            return;
          }

          token = await FirebaseMessaging.instance.getToken(
              vapidKey: "BKXKassXObbd8BAiKEhfUDZhmSXij-ZhsRjPYlyFP-mJ0FW2eAX5XA5S8SBK0nYaa_u2544vGpmsBj8ACRjb2cc"
          );
          print("MERCHANT TOKEN => $token");
        } else {
          print("INFO: Processing authentication within Emulator. Extracting Mobile FCM Token...");
          token = await FirebaseMessaging.instance.getToken();
        }

        if (token == null) {
          print("WARNING: FCM Framework returned a null token string value.");
          return;
        }

        print("DEBUG: Final Token Extracted -> $token");

        // Transmit the token string up to your Node.js MySQL backend API
        final response = await ApiClient.post(
          Uri.parse('${ApiConfig.baseUrl}/api/save-token'), // Ensure valid path
          body: jsonEncode({"fcmToken": token}),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          print("SUCCESS: Token successfully saved into your MySQL user account row.");
        } else {
          print("ERROR: Backend rejected sync payload with Status Code: ${response.statusCode}");
        }

      } catch (e) {
        print("CRITICAL: Token delivery operation failed inside catch block: $e");
      }
    }
  }

