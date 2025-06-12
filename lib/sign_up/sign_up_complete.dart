import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase 초기화 패키지 추가
import 'package:firebase_auth/firebase_auth.dart'; // Firebase 인증 패키지 추가
import '../login_screens/login_screen.dart'; // 로그인 화면 페이지 임포트

class SignUpCompleteScreen extends StatelessWidget {
  final String email;
  final String password;
  final String height;
  final String weight;
  final String birthdate;
  final String gender;
  final String nickname;
  final String bmi;

  const SignUpCompleteScreen({
    Key? key,
    required this.email,
    required this.password,
    required this.height,
    required this.weight,
    required this.birthdate,
    required this.gender,
    required this.nickname,
    required this.bmi,
  }) : super(key: key);

  // Firestore에 사용자 정보를 저장하는 함수
  Future<void> saveUserInfo() async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    // 변수 값 로그
    print('Saving user info:');
    print('Nickname: $nickname');
    print('Gender: $gender');
    print('Birthdate: $birthdate');
    print('Weight: $weight');
    print('Height: $height');
    print('Email: $email');
    print('BMI: $bmi');

    try {
      // Firestore에 데이터 저장 (문서 ID를 이메일로 설정)
      await users.doc(email).set({
        'nickname': nickname,
        'gender': gender,
        'birthdate': birthdate,
        'weight': weight,
        'height': height,
        'bmi': bmi,
      });
      print('User info saved successfully.');
    } catch (e) {
      print('Failed to save user info: $e');
    }
  }

  // Firebase Auth를 사용하여 사용자 등록하는 함수
  Future<void> registerUser() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("User registered: ${userCredential.user?.email}");
    } catch (e) {
      print("Failed to register user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height; // 화면의 높이
    final screenWidth = MediaQuery.of(context).size.width; // 화면의 너비

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 배경 이미지 (signupcom.png)
          Positioned.fill(
            child: Image.asset(
              'assets/images/signupcom.png', // signupcom.png 파일 경로
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),

          // 중간 이미지 (man.png)
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            bottom: screenHeight * 0.003, // man.png 이미지는 화면 하단 40%까지 표시
            child: Image.asset(
              'assets/images/man.png', // man.png 파일 경로
              fit: BoxFit.contain,
              alignment: Alignment.bottomLeft,
            ),
          ),

          // 내용 부분
          Align(
            alignment: Alignment.topCenter, // 상단에 정렬
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // 텍스트들을 위로 정렬
              children: [
                // 가입 완료 텍스트
                Container(
                  margin: EdgeInsets.only(
                    top: screenHeight * 0.15, // 화면 크기에 따라 상단 위치를 조금 더 위로 조정
                    bottom: 0.001,
                    right: screenWidth * 0.3,
                  ),
                  child: Text(
                    '회원가입 완료!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                // 환영합니다 텍스트
                Container(
                  margin: EdgeInsets.only(
                    top: 1.0,
                    bottom: 0.01,
                    left: screenWidth * 0.05, // 좌측 위치를 5%로 설정
                    right: screenWidth * 0.34, // 우측 위치를 5%로 설정
                  ),
                  child: Text(
                    '계정생성이 완료되었습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.black54,
                    ),
                  ),
                ),
                // 동일한 환영합니다 텍스트 추가
                Container(
                  margin: EdgeInsets.only(
                    top: 1,
                    bottom: 13.0,
                    left: screenWidth * 0.05, // 좌측 위치를 5%로 설정
                    right: screenWidth * 0.39, // 우측 위치를 5%로 설정
                  ),
                  child: Text(
                    '이제 힘차게 뛰어볼까요?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // '다음' 버튼
          Positioned(
            bottom: screenHeight * 0.07, // 화면의 높이에 비례하여 위치 설정
            left: 30,
            right: 30,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await registerUser(); // Firebase에 사용자 등록
                  await saveUserInfo(); // Firestore에 추가 정보 저장
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()), // 로그인 화면으로 이동
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}