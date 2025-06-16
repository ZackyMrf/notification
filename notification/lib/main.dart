import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'local_notification_service.dart';

/// Background message handler for Firebase messaging
Future<void> backgroundHandler(RemoteMessage message) async {
  print('Background message title: ${message.notification?.title}');
  print('Background message data: ${message.data.toString()}');
}

void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  
  // Initialize local notification service
  LocalNotificationService.initialize(null);
  
  // Subscribe to Firebase topic
  await FirebaseMessaging.instance.subscribeToTopic('myTopic');
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification App',
      debugShowCheckedModeBanner: false,
      home:  HomeScreen(),
    );
  }
}