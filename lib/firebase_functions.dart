import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseFunctions {
  // Firebase 콘솔에서 복사한 Server Key 넣기 (보안상 주의!)
  static const String SERVER_KEY = 'AAAAXXXXXXXXXXXXXXXX';

  // 여러 디바이스에게 알림 보내기
  static Future<void> sendPushNotifications(
      List<String> tokens, String title, String body) async {
    final data = {
      'registration_ids': tokens,
      'notification': {'title': title, 'body': body},
      'priority': 'high',
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$SERVER_KEY',
    };

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        body: jsonEncode(data),
        headers: headers,
      );

      if (response.statusCode != 200) {
        print('FCM 전송 실패: ${response.body}');
      }
    } catch (e) {
      print('알림 전송 오류: $e');
    }
  }
}