import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class NotificationService {
static final _messaging = FirebaseMessaging.instance;
static final _fln = FlutterLocalNotificationsPlugin();


static Future<String?> initAndGetToken() async {
// Request permissions
await _messaging.requestPermission(alert: true, badge: true, sound: true, provisional: false);


// Android init
const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
// iOS init
const iosInit = DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false);
const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
await _fln.initialize(initSettings,
onDidReceiveNotificationResponse: (resp) async {
// TODO: navigate to CallScreen(roomId: roomId, isCaller: false)
});


if (Platform.isAndroid) {
const channel = AndroidNotificationChannel(
'calls_channel',
'Calls',
description: 'Incoming calls',
importance: Importance.max,
playSound: true,
enableVibration: true,
);
await _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
?.createNotificationChannel(channel);
}

// Foreground handler
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
final data = message.data;
if (data['type'] == 'call') {
_showIncomingCallNotification(
title: data['callerName'] ?? 'Incoming call',
body: (data['video'] == 'true') ? 'Video call' : 'Audio call',
roomId: data['roomId'] ?? '',
);
}
});


// Background/terminated tap: handled in top-level handler in main.dart with `FirebaseMessaging.onBackgroundMessage`


return _messaging.getToken();
}


static Future<void> _showIncomingCallNotification({required String title, required String body, required String roomId}) async {
const androidDetails = AndroidNotificationDetails(
'calls_channel',
'Calls',
priority: Priority.max,
importance: Importance.max,
fullScreenIntent: true,
ongoing: true,
category: AndroidNotificationCategory.call,
);
const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true);
const details = NotificationDetails(android: androidDetails, iOS: iosDetails);


await _fln.show(1001, title, body, details, payload: roomId);
}
}