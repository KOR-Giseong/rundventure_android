import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth 임포트
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 임포트
import 'birthday_input_screen.dart'; // BirthdayInputScreen 임포트

class ProfileGenderScreen extends StatefulWidget {
  final String email; // 이메일 추가
  final String password; // 비밀번호 추가
  final String nickname; // 닉네임 추가

  const ProfileGenderScreen({Key? key, required this.email, required this.password, required this.nickname}) : super(key: key);

  @override
  _ProfileGenderScreenState createState() => _ProfileGenderScreenState();
}

class _ProfileGenderScreenState extends State<ProfileGenderScreen> {
  String? _selectedGender; // 선택된 성별 저장

  void _navigateNext() {
    if (_selectedGender == null) {
      // 성별이 선택되지 않은 경우 경고 메시지 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            '성별 선택',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '성별을 선택해주세요!',
            style: TextStyle(color: Colors.black54),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '확인',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    } else {
      // 생년월일 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BirthdayInputScreen(
            email: widget.email,
            password: widget.password,
            nickname: widget.nickname,
            gender: _selectedGender!,
          ),
        ),
      );
    }
  }

  Widget _genderBox(String gender, {double? height, double? width}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _selectedGender == gender ? Colors.black : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            gender,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    double boxHeight = screenHeight * 0.07;
    double boxWidth = screenWidth * 0.4;
    double minBoxHeight = 50;
    double minBoxWidth = 100;

    boxHeight = boxHeight < minBoxHeight ? minBoxHeight : boxHeight;
    boxWidth = boxWidth < minBoxWidth ? minBoxWidth : boxWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: screenHeight * 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 입력 안내 텍스트
            Text(
              '프로필을 입력해주세요!',
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '러너님에 대해 더 알게 되면 도움이 될 거예요!',
              style: TextStyle(
                color: Colors.grey,
                fontSize: screenWidth * 0.035,
              ),
            ),
            const SizedBox(height: 60),

            // 성별 선택 박스
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _genderBox('남자', height: boxHeight, width: boxWidth),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _genderBox('여자', height: boxHeight, width: boxWidth),
                ),
              ],
            ),
          ],
        ),
      ),

      // 다음 버튼만 하단에 고정
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: screenHeight * 0.07),
        child: ElevatedButton(
          onPressed: _navigateNext,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            '다음',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
