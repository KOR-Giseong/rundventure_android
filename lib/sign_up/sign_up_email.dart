import 'package:flutter/material.dart';
import 'sign_up_password_screen.dart'; // 비밀번호 입력 화면 import

class SignUpEmailScreen extends StatefulWidget {
  const SignUpEmailScreen({Key? key}) : super(key: key);

  @override
  _SignUpEmailScreenState createState() => _SignUpEmailScreenState();
}

class _SignUpEmailScreenState extends State<SignUpEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 회원가입 제목의 굵기 설정
  final FontWeight _titleFontWeight = FontWeight.bold;

  void _navigateToPasswordScreen() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignUpPasswordScreen(email: _emailController.text),
        ),
      );
    }
  }

  void _goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경을 흰색으로 설정
      body: Container(
        height: MediaQuery.of(context).size.height, // 화면 높이 전체 사용
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 90),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 뒤로가기 버튼 (이미지로 대체)
                SizedBox(
                  width: 70,
                  height: 70,
                  child: GestureDetector(
                    onTap: _goBack,
                    child: Image.asset('assets/images/Back-Navs.png', width: 70, height: 70),
                  ),
                ),
                const SizedBox(height: 20),

                // 이메일 입력 제목
                Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600, // 굵기 설정
                  ),
                ),
                const SizedBox(height: 40),

                // 이메일 입력 폼
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(10.0), // 패딩 추가
                        child: Icon(
                          Icons.email, // 기본 이메일 아이콘
                          color: Colors.grey, // 그레이 색상
                          size: 24, // 아이콘 크기
                        ),
                      ),
                      hintText: '이메일을 입력하세요', // 힌트 텍스트 추가
                      hintStyle: TextStyle(
                        color: Colors.grey[500], // 연한 회색으로 설정
                        fontWeight: FontWeight.w400, // hintText 굵기 조정
                      ),
                      filled: true,
                      fillColor: Color(0xFFF7F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: Colors.grey[900]), // 텍스트 색상
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력하세요';
                      }
                      // 이메일 형식 검증
                      if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                        return '유효한 이메일 주소를 입력하세요';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 430),

                // 다음 버튼
                Container(
                  width: double.infinity, // 버튼 박스의 넓이를 화면 가득 채움
                  child: ElevatedButton(
                    onPressed: _navigateToPasswordScreen,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '다음',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}