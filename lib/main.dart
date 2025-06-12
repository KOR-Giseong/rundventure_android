import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:work/home_Screens/home_screen.dart';
import 'package:work/services/user_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:work/Notification/user_notification.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 추가
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth 추가

// 🔹 알림 중복 방지를 위한 Set
Set<String> receivedMessageKeys = {};

// 🔹 고유 키 생성 함수
String generateUniqueKey(RemoteMessage message) {
  final title = message.notification?.title ?? 'no_title';
  final body = message.notification?.body ?? 'no_body';
  final timestamp = message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
  return '$title:$body:$timestamp';
}

// 🔹 백그라운드 알림 수신 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📥 백그라운드에서 알림 수신됨: ${message.notification?.title}");

  final String key = generateUniqueKey(message);

  if (receivedMessageKeys.contains(key)) {
    print("🚫 백그라운드 - 중복된 알림 무시됨: $key");
    return;
  }

  receivedMessageKeys.add(key);

  final prefs = await SharedPreferences.getInstance();
  List<String> notifications = prefs.getStringList('notifications') ?? [];

  final expirySeconds = int.tryParse(message.data['expiry'] ?? '');
  final expiryTime = expirySeconds != null
      ? DateTime.now().add(Duration(seconds: expirySeconds))
      : null;

  final newNoti = NotificationItem(
    title: message.notification?.title ?? "알림",
    message: message.notification?.body ?? "내용 없음",
    timestamp: DateTime.now(),
    expiry: expiryTime,
    isRead: false,
  );

  notifications.insert(0, jsonEncode(newNoti.toJson()));
  await prefs.setStringList('notifications', notifications);
}

// 🔹 Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // UI 설정 (상단 바만 유지)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [SystemUiOverlay.top],
  );

  await Firebase.initializeApp();
  await initializeDateFormatting();

  // 🔹 FCM 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await requestNotificationPermission();

  // 🔹 앱 실행 중 알림 수신
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      print('📢 포그라운드 알림: ${message.notification?.title}');
      print('📢 내용: ${message.notification?.body}');

      // ⬇️ 포그라운드에서도 SharedPreferences에 알림 저장
      _saveNotificationToStorage(message);
    }
  });

  // 🔹 백그라운드 상태에서 알림 클릭
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('🔔 알림 클릭됨 (백그라운드): ${message.notification?.title}');
    if (message.data['screen'] == 'UserNotificationPage') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => UserNotificationPage()),
      );
    }
  });

  // 🔹 종료 상태에서 앱 실행될 때 알림 클릭
  RemoteMessage? initialMessage =
  await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('🔁 앱 종료 상태에서 알림 클릭됨: ${initialMessage.notification?.title}');
    if (initialMessage.data['screen'] == 'UserNotificationPage') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => UserNotificationPage()),
        );
      });
    }
  }

  // 🔹 FCM 토큰 가져오기 및 Firestore 저장
  FirebaseMessaging.instance.getToken().then((token) async {
    print("✅ FCM 토큰: $token");

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .update({'fcmToken': token})
          .catchError((e) {
        print("❌ Firestore 업데이트 오류: $e");
      });
    }
  });

  // 🔁 토큰 갱신 리스너 추가
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print("🔄 FCM 토큰 갱신됨: $newToken");

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && newToken != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .update({'fcmToken': newToken})
          .catchError((e) {
        print("❌ 토큰 갱신 실패: $e");
      });
    }
  });

  runApp(MyApp());
}

// 🔹 포그라운드에서 받은 알림 저장 함수
Future<void> _saveNotificationToStorage(RemoteMessage message) async {
  final String key = generateUniqueKey(message);

  if (receivedMessageKeys.contains(key)) {
    print("🚫 포그라운드 - 중복된 알림 무시됨: $key");
    return;
  }

  receivedMessageKeys.add(key);

  final prefs = await SharedPreferences.getInstance();
  List<String> notifications = prefs.getStringList('notifications') ?? [];

  final expirySeconds = int.tryParse(message.data['expiry'] ?? '');
  final expiryTime = expirySeconds != null
      ? DateTime.now().add(Duration(seconds: expirySeconds))
      : null;

  final newNoti = NotificationItem(
    title: message.notification?.title ?? "알림",
    message: message.notification?.body ?? "내용 없음",
    timestamp: DateTime.now(),
    expiry: expiryTime,
    isRead: false,
  );

  notifications.insert(0, jsonEncode(newNoti.toJson()));
  await prefs.setStringList('notifications', notifications);
}

// 🔹 알림 권한 요청
Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('🔓 알림 허용됨');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('⚠️ 잠정적 허용됨');
  } else {
    print('❌ 알림 거부됨');
  }
}

// 🔹 메인 앱 위젯
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login UI',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: Home_screen(),
    );
  }
}