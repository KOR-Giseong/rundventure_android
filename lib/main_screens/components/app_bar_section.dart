import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Notification/user_notification.dart';
import '../../profile/user_profile.dart';
import 'dart:convert';

class AppBarSection extends StatefulWidget {
  @override
  _AppBarSectionState createState() => _AppBarSectionState();
}

class _AppBarSectionState extends State<AppBarSection> {
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('notifications') ?? [];
    List<NotificationItem> notifications = [];

    for (var s in data) {
      try {
        final jsonData = jsonDecode(s);
        notifications.add(NotificationItem.fromJson(jsonData));
      } catch (e) {
        print("알림 데이터 파싱 오류: $e");
      }
    }

    setState(() {
      unreadCount = notifications.where((n) => !n.isRead && !n.isExpired).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile 버튼
          SizedBox(
            height: 60,
            width: 60,
            child: IconButton(
              icon: Image.asset('assets/images/user.png'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
          ),

          // 로고 센터 배치
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/mainrundventure2.png',
                height: 40,
                width: 150,
              ),
            ),
          ),

          // 알림 버튼 + 뱃지
          Stack(
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: IconButton(
                  icon: Image.asset('assets/images/alarm.png'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserNotificationPage()),
                    ).then((_) {
                      // 페이지 종료 후 읽지 않은 알림 갯수 갱신
                      _loadUnreadCount();
                    });
                  },
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}