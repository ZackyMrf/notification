import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'local_notification_service.dart';

/// Background message handler for Firebase messaging
Future<void> backgroundHandler(RemoteMessage message) async {
  print('Background message title: ${message.notification?.title}');
  print('Background message data: ${message.data.toString()}');
  
  // Show notification in background
  await LocalNotificationService.createAndDisplayNotification(message);
}

void main() async {
  // Inisialisasi widget binding PERTAMA
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Initializing Firebase...');
    // Initialize Firebase
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(backgroundHandler);
    
    print('Initializing LocalNotificationService...');
    // Initialize local notification service
    await LocalNotificationService.initialize();
    print('LocalNotificationService initialized successfully');
    
    // Request notification permission dengan error handling
    await _requestNotificationPermission();
    
    // Get FCM token dengan graceful error handling
    await _getFCMTokenSafely();
    
    // Subscribe to Firebase topic dengan error handling
    await _subscribeToTopicSafely();
    
    runApp(MyApp());
    
  } catch (e, stackTrace) {
    print('Error initializing app: $e');
    print('Stack trace: $stackTrace');
    runApp(MyApp()); // Tetap jalankan app meskipun Firebase gagal
  }
}

Future<void> _requestNotificationPermission() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    ).timeout(Duration(seconds: 10));
    
    print('User granted permission: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  } catch (e) {
    print('Error requesting notification permission: $e');
    // Continue without Firebase messaging
  }
}

Future<void> _getFCMTokenSafely() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken().timeout(
      Duration(seconds: 15),
      onTimeout: () {
        print('FCM token request timeout - SERVICE_NOT_AVAILABLE');
        return null;
      },
    );
    
    if (token != null) {
      print('FCM Token: $token');
      
      // Listen for token refresh
      messaging.onTokenRefresh.listen((String token) {
        print('FCM Token refreshed: $token');
      }).onError((error) {
        print('Token refresh error: $error');
      });
    } else {
      print('FCM Token is null - Push notifications not available');
    }
  } catch (e) {
    print('Error getting FCM token: $e');
    if (e.toString().contains('SERVICE_NOT_AVAILABLE')) {
      print('Google Play Services not available - FCM disabled');
    }
  }
}

Future<void> _subscribeToTopicSafely() async {
  try {
    await FirebaseMessaging.instance.subscribeToTopic('myTopic').timeout(
      Duration(seconds: 10),
      onTimeout: () {
        print('Topic subscription timeout - continuing without topic');
        return;
      },
    );
    print('Subscribed to Firebase topic successfully');
  } catch (e) {
    print('Topic subscription failed: $e');
    if (e.toString().contains('SERVICE_NOT_AVAILABLE')) {
      print('Cannot subscribe to topic - Google Play Services unavailable');
    }
    // App continues to work without topic subscription
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification App',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Initialization Error')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'App Initialization Failed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                error,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  main();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}