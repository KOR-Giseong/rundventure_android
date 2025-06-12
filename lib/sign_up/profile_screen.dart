import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 임포트
import 'profile_gender_screen.dart'; // ProfileGenderScreen 임포트

class ProfileScreen extends StatefulWidget {
  final String email; // 이메일 추가
  final String password; // 비밀번호 추가

  const ProfileScreen({Key? key, required this.email, required this.password}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nicknameController = TextEditingController(); // 닉네임 입력 컨트롤러
  bool _isNicknameChecked = false; // 닉네임 중복 확인 여부

  // 다이얼로그 표시 함수
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title, style: const TextStyle(color: Colors.black)),
          content: Text(message, style: const TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  // 닉네임 중복 확인 함수
  Future<void> _checkNickname() async {
    String nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      _showDialog('경고', '닉네임을 입력해주세요.');
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _isNicknameChecked = false;
        });
        _showDialog('중복 확인', '이미 사용 중인 닉네임입니다. 다른 닉네임을 사용해주세요.');
      } else {
        setState(() {
          _isNicknameChecked = true;
        });
        _showDialog('확인', '사용 가능한 닉네임입니다.');
      }
    } catch (e) {
      _showDialog('오류', '닉네임 확인 중 오류가 발생했습니다.\n네트워크 상태를 확인하세요.');
    }
  }

  // 다음 화면으로 이동 함수
  void _navigateNext() {
    if (_nicknameController.text.isEmpty) {
      _showDialog('경고', '닉네임을 입력해주세요!');
      return;
    }

    if (!_isNicknameChecked) {
      _showDialog('경고', '닉네임 중복 확인을 해주세요!');
      return;
    }

    // 페이드 효과 적용
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 300), // 애니메이션 지속 시간
        pageBuilder: (context, animation, secondaryAnimation) {
          return ProfileGenderScreen(
            email: widget.email,
            password: widget.password,
            nickname: _nicknameController.text,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 페이드 애니메이션 적용
          return FadeTransition(
            opacity: animation, // 애니메이션에 따라 투명도 변화
            child: child,
          );
        },
      ),
    );
  }

  void _goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    double boxHeight = screenHeight * 0.06;
    double buttonHeight = screenHeight * 0.07;
    double buttonWidth = screenWidth * 0.9;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: screenHeight * 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: GestureDetector(
                onTap: () {
                  // 페이드 효과 적용
                  Navigator.of(context).pop();  // 기본 뒤로가기
                },
                child: Image.asset('assets/images/Back-Navs.png', width: 70, height: 70),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              '프로필을 입력해주세요!',
              style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              '러너님에 대해 더 알게 되면 도움이 될 거예요!',
              style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035),
            ),
            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(
                  child: Container(
                    height: boxHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: TextField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        hintText: '닉네임을 입력하세요',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.03, fontWeight: FontWeight.w400),
                        contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.012, horizontal: screenWidth * 0.01),
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015, horizontal: screenWidth * 0.04),
                          child: const Icon(Icons.person, size: 20, color: Colors.grey),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: _checkNickname,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.grey, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    ),
                    child: const Text('중복 확인', style: TextStyle(color: Colors.black54, fontSize: 8, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 355),

            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: _navigateNext,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('다음', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
