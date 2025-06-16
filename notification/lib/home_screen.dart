import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'local_notification_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _titleText;
  String? _bodyText;

  @override
  void initState() {
    super.initState();
    LocalNotificationService.initialize(context);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        LocalNotificationService.createAndDisplayNotification(message);
        setState(() {
          _titleText = message.notification!.title;
          _bodyText = message.notification!.body;
        });
      }
    });

    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        LocalNotificationService.createAndDisplayNotification(message);
        setState(() {
          _titleText = message.notification!.title;
          _bodyText = message.notification!.body;
        });
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.notification != null) {
        LocalNotificationService.createAndDisplayNotification(message);
        setState(() {
          _titleText = message.notification!.title;
          _bodyText = message.notification!.body;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Push Notification App"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Text("Notification"),
            Text("Title: $_titleText"),
            Text("Body: $_bodyText"),
          ],
        ),
      ),
    );
  }
}
