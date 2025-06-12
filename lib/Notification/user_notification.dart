import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/timeago.dart' as timeago_ko show setLocaleMessages, KoMessages;

class NotificationItem {
  final String title;
  final String message;
  final DateTime timestamp;
  final DateTime? expiry;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.message,
    required this.timestamp,
    this.expiry,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'expiry': expiry?.toIso8601String(),
    'isRead': isRead,
  };

  static NotificationItem fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      expiry: json['expiry'] != null ? DateTime.tryParse(json['expiry']) : null,
      isRead: json['isRead'] ?? false,
    );
  }

  bool get isExpired => expiry != null && DateTime.now().isAfter(expiry!);
}

class UserNotificationPage extends StatefulWidget {
  @override
  _UserNotificationPageState createState() => _UserNotificationPageState();
}

class _UserNotificationPageState extends State<UserNotificationPage> {
  List<NotificationItem> notifications = [];
  int unreadCount = 0;
  Timer? _timer;
  bool _fcmListenersInitialized = false;
  Set<String> receivedMessageKeys = {}; // 중복 방지용 Set

  @override
  void initState() {
    super.initState();
    _clearOldFormatData();
    _loadNotifications();
    _setupFCMListeners();
    _timer = Timer.periodic(Duration(minutes: 1), (_) {
      _removeExpiredNotifications();
    });
  }

  Future<void> _clearOldFormatData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getStringList('notifications');
    if (rawData != null && rawData.isNotEmpty) {
      try {
        final first = jsonDecode(rawData.first);
        if (first is Map<String, dynamic> && !first.containsKey('timestamp')) {
          await prefs.remove('notifications');
        }
      } catch (e) {
        await prefs.remove('notifications');
      }
    }
  }

  void _setupFCMListeners() {
    if (_fcmListenersInitialized) return;

    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    _fcmListenersInitialized = true;
  }

  // 알림 고유 키 생성 함수
  String generateUniqueKey(RemoteMessage message) {
    final title = message.notification?.title ?? 'no_title';
    final body = message.notification?.body ?? 'no_body';
    final timestamp = message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
    return '$title:$body:$timestamp';
  }

  void _handleMessage(RemoteMessage message) async {
    if (message.notification != null) {
      final key = generateUniqueKey(message);

      if (receivedMessageKeys.contains(key)) {
        print("🚫 중복된 알림 무시됨: $key");
        return;
      }

      receivedMessageKeys.add(key); // 신규 알림 키 등록

      final expirySeconds = int.tryParse(message.data['expiry'] ?? '');
      final expiryTime = expirySeconds != null
          ? DateTime.now().add(Duration(seconds: expirySeconds))
          : null;

      final newNoti = NotificationItem(
        title: message.notification!.title ?? "알림",
        message: message.notification!.body ?? "내용 없음",
        timestamp: DateTime.now(),
        expiry: expiryTime,
      );

      final prefs = await SharedPreferences.getInstance();
      List<String> saved = prefs.getStringList('notifications') ?? [];

      // 동일한 제목+내용+시간 기반 중복 체크
      final existingIndex = saved.indexWhere((s) {
        final jsonMap = jsonDecode(s);
        final item = NotificationItem.fromJson(jsonMap);
        return item.title == newNoti.title &&
            item.message == newNoti.message &&
            item.timestamp.difference(newNoti.timestamp).inSeconds.abs() < 10;
      });

      if (existingIndex >= 0) {
        print("🚫 동일한 알림 무시됨: ${newNoti.title}");
        return;
      }

      saved.insert(0, jsonEncode(newNoti.toJson()));
      await prefs.setStringList('notifications', saved);

      setState(() {
        notifications.insert(0, newNoti);
        unreadCount++;
      });
    }
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('notifications') ?? [];
    final loaded = data.map((s) {
      final jsonData = jsonDecode(s);
      return NotificationItem.fromJson(jsonData);
    }).where((n) => !n.isExpired).toList();

    setState(() {
      notifications = loaded;
      unreadCount = notifications.where((n) => !n.isRead).length;
    });

    await _saveNotifications(); // 만료된 알림 정리
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList('notifications', data);
  }

  void _removeExpiredNotifications() async {
    setState(() {
      notifications.removeWhere((n) => n.isExpired);
      unreadCount = notifications.where((n) => !n.isRead).length;
    });
    await _saveNotifications();
  }

  void _markAllAsRead() async {
    setState(() {
      for (var n in notifications) {
        n.isRead = true;
      }
      unreadCount = 0;
    });
    await _saveNotifications();
  }

  void _markAsRead(int index) async {
    if (!notifications[index].isRead) {
      setState(() {
        notifications[index].isRead = true;
        unreadCount--;
      });
      await _saveNotifications();
    }
  }

  void _deleteNotification(int index) async {
    setState(() {
      notifications.removeAt(index);
      unreadCount = notifications.where((n) => !n.isRead).length;
    });
    await _saveNotifications();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('ko', timeago_ko.KoMessages());
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 왼쪽 끝: 뒤로가기 버튼
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    'assets/images/Back-Navs.png',
                    width: 70,
                    height: 70,
                  ),
                ),

                // 중앙: '알림' 텍스트
                const Expanded(
                  child: Center(
                    child: Text(
                      '알림',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // 오른쪽은 비워둠 (혹시 필요 시 다른 버튼 넣을 공간)
                const SizedBox(width: 70), // 이미지와 균형 맞추기 위해 여유 공간 추가
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(top: 10),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final noti = notifications[index];
                return NotificationCard(
                  notification: noti,
                  onTap: () => _markAsRead(index),
                  onDelete: () => _deleteNotification(index),
                );
              },
            ),
          ),
          if (notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: ElevatedButton(
                onPressed: _markAllAsRead,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "모두 읽음",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy년 M월 d일 a h:mm', 'ko')
        .format(notification.timestamp.toLocal());
    final relativeTime = timeago.format(notification.timestamp, locale: 'ko');

    return Card(
      color: notification.isRead ? Colors.white : Colors.blue[50],
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight:
                      notification.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: "삭제",
            )
          ],
        ),
        trailing: Text(
          relativeTime,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onExpansionChanged: (expanded) {
          if (expanded) onTap();
        },
        children: [
          Container(
            color: Colors.grey[200],
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Text(
              notification.message,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}