import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_screens/login_screen.dart'; // 로그인 화면으로 임포트
import 'terms_of_Use.dart'; // 이용약관 화면 임포트
import 'profile_screen.dart'; // 프로필 화면 임포트

class ConfirmPasswordScreen extends StatefulWidget {
  final String email;
  final String password;

  const ConfirmPasswordScreen({Key? key, required this.email, required this.password}) : super(key: key);

  @override
  _ConfirmPasswordScreenState createState() => _ConfirmPasswordScreenState();
}

class _ConfirmPasswordScreenState extends State<ConfirmPasswordScreen> {
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false; // 이용약관 동의 상태
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _goBack() {
    Navigator.pop(context);
  }

  Future<void> _navigateToTerms() async {
    // 이용약관 페이지로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsAndConditionsScreen(),
      ),
    );

    // 이용약관 동의 여부를 확인하고 체크박스 상태 업데이트
    if (result != null && result) {
      setState(() {
        _agreedToTerms = true; // 이용약관에 동의했을 경우 체크박스 체크
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 90),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 뒤로가기 버튼
                SizedBox(
                  width: 70,
                  height: 70,
                  child: GestureDetector(
                    onTap: _goBack,
                    child: Image.asset('assets/images/Back-Navs.png', width: 70, height: 70),
                  ),
                ),
                const SizedBox(height: 20),

                // 회원가입 제목
                Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 40),

                // 이메일 입력 필드
                TextFormField(
                  initialValue: widget.email,
                  decoration: InputDecoration(
                    enabled: false,
                    filled: true,
                    fillColor: Color(0xFFF7F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.email, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 비밀번호 입력 필드
                TextFormField(
                  initialValue: widget.password,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF7F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.lock, color: Colors.grey),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 20),

                // 비밀번호 확인 입력 필드
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF7F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.lock, color: Colors.grey),
                      ),
                      labelText: '비밀번호 확인',
                      labelStyle: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력하세요';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 개인정보 보호정책 및 이용약관 동의 체크박스
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _navigateToTerms,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '개인정보',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.underline,  // 띄어쓰기 후 밑줄 없앰
                                ),
                              ),
                              TextSpan(
                                text: ' ',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.none,  // 띄어쓰기 후 밑줄 없앰
                                ),
                              ),
                              TextSpan(
                                text: '보호정책',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.underline,  // '보호정책'에 밑줄 적용
                                ),
                              ),
                              TextSpan(
                                text: ' ',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.none,  // 띄어쓰기 후 밑줄 없앰
                                ),
                              ),
                              TextSpan(
                                text: '및',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.underline,  // '및'에 밑줄 적용
                                ),
                              ),
                              TextSpan(
                                text: ' ',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.none,  // 띄어쓰기 후 밑줄 없앰
                                ),
                              ),
                              TextSpan(
                                text: '이용약관에',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.underline,  // '이용약관'에 밑줄 적용
                                ),
                              ),
                              TextSpan(
                                text: ' ',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.none,  // 띄어쓰기 후 밑줄 없앰
                                ),
                              ),
                              TextSpan(
                                text: '동의합니다',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.underline,  // '동의합니다'에 밑줄 적용
                                ),
                              ),
                              TextSpan(
                                text: '.',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.none,  // 마침표 밑줄 없앰
                                ),
                              ),
                            ],
                          ),
                          softWrap: true,  // 텍스트가 줄바꿈 될 수 있게 설정
                        ),
                      ),
                    ),
                  ],
                ),



                SizedBox(height: 200),

                // 이전, 다음 버튼
                Row(
                  children: [
                    // 이전 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _goBack,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.black, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '이전',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 다음 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _agreedToTerms
                            ? () {
                          if (_formKey.currentState!.validate()) {
                            if (widget.password == _confirmPasswordController.text.trim()) {
                              // 프로필 입력 화면으로 이동
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(email: widget.email, password: widget.password), // 이메일과 비밀번호를 전달
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("비밀번호가 일치하지 않습니다.")),
                              );
                            }
                          }
                        }
                            : null,
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
