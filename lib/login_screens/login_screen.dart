import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:work/main_screens/main_screen.dart';
import '../sign_up/sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isAutoLogin = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? errorMessage; // 오류 메시지를 저장할 변수 추가

  @override
  void initState() {
    super.initState();
    _loadAutoLogin();
  }

  void _loadAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isAutoLogin = prefs.getBool('autoLogin') ?? false;
      if (isAutoLogin) {
        emailController.text = prefs.getString('email') ?? '';
        passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

  void _saveAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoLogin', isAutoLogin);
    if (isAutoLogin) {
      prefs.setString('email', emailController.text);
      prefs.setString('password', passwordController.text);
    } else {
      prefs.remove('email');
      prefs.remove('password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 90),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: IconButton(
                    icon: Image.asset('assets/images/Back-Navs.png'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  '러너님!\n환영합니다!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline, color: Colors.grey[600]),
                    hintText: '이메일',
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                    filled: true,
                    fillColor: Color(0xFFF7F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.grey[800]),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                    hintText: '비밀번호',
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                    filled: true,
                    fillColor: Color(0xFFF7F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: Colors.grey[800]),
                  obscureText: !isPasswordVisible,
                ),
                const SizedBox(height: 15),

                // 오류 메시지 표시
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                Row(
                  children: [
                    Checkbox(
                      value: isAutoLogin,
                      onChanged: (value) {
                        setState(() {
                          isAutoLogin = value ?? false;
                          _saveAutoLogin();
                        });
                      },
                      activeColor: Colors.grey[600],
                    ),
                    Text(
                      '자동 로그인',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        errorMessage = null; // 로그인 시 오류 메시지 초기화
                      });
                      await _loginWithEmailPassword(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '로그인',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Or'),
                    ),
                    Expanded(child: Divider(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey),
                        color: Color(0xFFFFFFFF),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 1, horizontal: 1),
                      child: IconButton(
                        icon: Image.asset(
                          'assets/images/googlelogo.png',
                          width: 30,
                          height: 30,
                        ),
                        iconSize: 30,
                        onPressed: () {
                          _loginWithGoogle();
                        },
                      ),
                    ),
                    const SizedBox(width: 20),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey),
                        color: Color(0xFFFFFFFF),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 1, horizontal: 1),
                      child: IconButton(
                        icon: Image.asset(
                          'assets/images/kakao.png',
                          width: 30,
                          height: 30,
                        ),
                        iconSize: 30,
                        onPressed: () {
                          // 카카오 로그인 기능 구현
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),


                Center(
                  child: GestureDetector(
                    onTap: () {
                      // 비밀번호 재설정 화면으로 이동
                    },
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '비밀번호를', // 밑줄 적용
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1,
                            ),
                          ),
                          TextSpan(
                            text: ' ', // 띄어쓰기 (밑줄 없음)
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          TextSpan(
                            text: '잊어버리셨나요', // 밑줄 적용
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1,
                            ),
                          ),
                          TextSpan(
                            text: '?', // 물음표 (밑줄 없음)
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '회원가입이 필요하신가요? ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextSpan(
                          text: '회원가입',
                          style: TextStyle(
                            color: Color(0xFFFF845C),
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => SignUpScreen()),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loginWithEmailPassword(BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 🔽 isAdmin 값 가져오기
      final user = userCredential.user;
      final idTokenResult = await user?.getIdTokenResult();
      final isAdmin = idTokenResult?.claims?['isAdmin'] ?? true;

      print("로그인 성공: ${user?.email}");
      print("관리자 여부: $isAdmin");

      // 🔽 MainScreen으로 이동하면서 isAdmin 전달 (선택 사항)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(isAdmin: isAdmin),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = '로그인 오류: ${e.code} - ${e.message}';
      });
      print('로그인 오류: ${e.code} - ${e.message}');
    } catch (e) {
      setState(() {
        errorMessage = '로그인 오류: $e';
      });
      print('로그인 오류: $e');
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자가 로그인 과정을 취소했습니다.
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 구글 로그인 후 Firebase 인증
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // null 체크
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        setState(() {
          errorMessage = '구글 인증에 실패했습니다. 다시 시도해주세요.';
        });
        return;
      }

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      print("구글 로그인 성공: ${userCredential.user?.email}");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } catch (e) {
      print('구글 로그인 오류: $e');
      setState(() {
        errorMessage = '구글 로그인 오류: $e';
      });
    }
  }
}