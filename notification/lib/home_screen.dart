import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'local_notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _titleText;
  String? _bodyText;
  String _status = "Initializing...";
  String? _fcmToken;
  bool _firebaseAvailable = true;
  bool _isGooglePlayServicesAvailable = false;

  @override
  void initState() {
    super.initState();
    print('HomeScreen: initState called');
    _checkGooglePlayServices();
    _setupFirebaseListeners();
    _getFCMToken();
  }

  void _checkGooglePlayServices() {
    // Simple check untuk Google Play Services
    // Pada emulator tanpa Google Play, FCM tidak akan bekerja
    setState(() {
      _isGooglePlayServicesAvailable = true; // Assume available for now
    });
  }

  void _setupFirebaseListeners() {
    try {
      print('HomeScreen: Setting up Firebase listeners');
      setState(() {
        _status = "Setting up Firebase listeners...";
      });

      // Handle initial message when app is opened from notification
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        print('HomeScreen: Initial message: $message');
        if (message != null) {
          _handleMessage(message);
        }
        setState(() {
          _status = "Firebase listeners active";
        });
      }).catchError((error) {
        print('HomeScreen: Error getting initial message: $error');
        setState(() {
          _firebaseAvailable = false;
          _status = "Firebase unavailable - Check Google Play Services";
        });
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        print('HomeScreen: Foreground message: ${message.notification?.title}');
        if (message.notification != null) {
          // Show local notification for foreground messages
          LocalNotificationService.createAndDisplayNotification(message);
          _handleMessage(message);
        }
      }).onError((error) {
        print('HomeScreen: Error in onMessage: $error');
        setState(() {
          _firebaseAvailable = false;
          _status = "Firebase messaging unavailable";
        });
      });

      // Handle message when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        print('HomeScreen: App opened from notification: ${message.notification?.title}');
        if (message.notification != null) {
          _handleMessage(message);
        }
      }).onError((error) {
        print('HomeScreen: Error in onMessageOpenedApp: $error');
      });

    } catch (e) {
      print('HomeScreen: Error setting up listeners: $e');
      setState(() {
        _firebaseAvailable = false;
        _status = "Error: $e";
      });
    }
  }

  void _getFCMToken() async {
    try {
      print('HomeScreen: Getting FCM token...');
      
      // Add timeout untuk FCM token request
      String? token = await FirebaseMessaging.instance.getToken().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('FCM token request timeout');
          return null;
        },
      );
      
      if (token != null) {
        setState(() {
          _fcmToken = token;
          _firebaseAvailable = true;
          _status = "FCM Token received - Push notifications ready";
        });
        print('FCM Token: $token');
        
        // Listen for token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
          print('FCM Token refreshed: $newToken');
          setState(() {
            _fcmToken = newToken;
          });
        });
      } else {
        setState(() {
          _firebaseAvailable = false;
          _status = "FCM Token unavailable - Check device compatibility";
        });
      }
    } catch (e) {
      print('Error getting FCM token: $e');
      setState(() {
        _firebaseAvailable = false;
        _status = "FCM Error: ${e.toString()}";
      });
    }
  }

  void _handleMessage(RemoteMessage message) {
    print('Handling message: ${message.notification?.title}');
    setState(() {
      _titleText = message.notification?.title;
      _bodyText = message.notification?.body;
    });
    
    // Show snackbar untuk user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New notification: ${message.notification?.title}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sendTestNotification() async {
    try {
      await LocalNotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Test Local Notification',
        body: 'This is a test local notification - ${DateTime.now().toString()}',
        payload: 'test_payload',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Local test notification sent!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error sending test notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyTokenToClipboard() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('FCM Token copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _retryFirebaseConnection() {
    setState(() {
      _status = "Retrying Firebase connection...";
      _firebaseAvailable = true;
    });
    _setupFirebaseListeners();
    _getFCMToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Push Notification App"),
        backgroundColor: _firebaseAvailable ? Colors.blue : Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status Icon
              Icon(
                _firebaseAvailable ? Icons.cloud_done : Icons.cloud_off,
                size: 80,
                color: _firebaseAvailable ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                "Push Notification App",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Status
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _firebaseAvailable ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _firebaseAvailable ? Colors.green : Colors.orange,
                  ),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    fontSize: 14,
                    color: _firebaseAvailable ? Colors.green[800] : Colors.orange[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              
              // Last Notification Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Last Notification Received:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Title: ", style: TextStyle(fontWeight: FontWeight.w600)),
                          Expanded(child: Text(_titleText ?? 'No notification received')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Body: ", style: TextStyle(fontWeight: FontWeight.w600)),
                          Expanded(child: Text(_bodyText ?? 'No notification received')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // FCM Token Card
              if (_fcmToken != null) ...[
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "FCM Token:",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy),
                              onPressed: _copyTokenToClipboard,
                              tooltip: 'Copy Token',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _fcmToken!,
                            style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Use this token to send push notifications from Firebase Console",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendTestNotification,
                      icon: Icon(Icons.notification_add),
                      label: Text('Send Test Local Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_firebaseAvailable) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _retryFirebaseConnection,
                        icon: Icon(Icons.refresh),
                        label: Text('Retry Firebase Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              // Debug Info
              const SizedBox(height: 24),
              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Debug Info:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("Firebase Available: $_firebaseAvailable"),
                      Text("Has FCM Token: ${_fcmToken != null}"),
                      Text("Google Play Services: $_isGooglePlayServicesAvailable"),
                      const SizedBox(height: 8),
                      Text(
                        "Note: Push notifications require Google Play Services. Test on real device for full functionality.",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}