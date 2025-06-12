import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:work/home_Screens/home_screen2.dart';
import '../login_screens/login_screen.dart';
import '../sign_up/sign_up_email.dart'; // 이메일 회원가입 페이지 추가
import 'profile_screen.dart'; // 프로필 화면 추가
import 'package:work/sign_up/components/social_sign_up_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signUpWithEmail() async {
    // 이메일 회원가입 로직이 필요한 경우 여기에 구현
  }

  Future<void> _signUpWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return; // 로그인 취소됨
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      print("구글 회원가입 성공: ${userCredential.user?.uid}");

      // 프로필 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            email: googleUser.email,
            password: '', // 구글 로그인에서는 비밀번호가 없으므로 빈 문자열
          ),
        ),
      );
    } catch (e) {
      print("구글 회원가입 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("구글 회원가입 오류")),
      );
    }
  }

  Future<void> _signUpWithKakao() async {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
      final AuthCredential credential = OAuthProvider("kakao.com").credential(
        accessToken: token.accessToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      print("카카오 회원가입 성공: ${userCredential.user?.uid}");

      // 프로필 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            email: userCredential.user?.email ?? '',
            password: '', // 카카오 로그인에서도 비밀번호가 없으므로 빈 문자열
          ),
        ),
      );
    } catch (e) {
      print("카카오 회원가입 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("카카오 회원가입 오류")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0), // 패딩을 LoginScreen과 동일하게 설정
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 85), // 위쪽 여백을 증가시켜 아래로 내리기

            // 뒤로가기 버튼 (이미지로 대체)
            SizedBox(
              width: 70,
              height: 70,
              child: IconButton(
                icon: Image.asset('assets/images/Back-Navs.png', width: 70, height: 70), // 이미지 크기 조정
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Home_screen2()),
                  );
                },
              ),
            ),

            const SizedBox(height: 20), // LoginScreen과 같은 간격으로 설정
            Text(
              '회원가입',
              style: TextStyle(
                fontSize: 24, // 폰트 크기 조정
                fontWeight: FontWeight.w600, // 폰트 두께 조정
              ),
            ),
            const SizedBox(height: 40), // 버튼 위치를 LoginScreen과 동일하게 설정

            // 이메일로 회원가입 버튼
            Row(
              children: [
                Expanded(
                  child: SocialSignUpButton(
                    text: '이메일로 회원가입',
                    icon: Icon(Icons.email, color: Colors.grey),
                    onPressed: () {
                      // 이메일 회원가입 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpEmailScreen()),
                      );
                    },
                    borderWidth: 1.0,
                    borderColor: Colors.grey.withOpacity(0.5), // 연한 테두리 색상
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15), // 간격 조정

            // 구글로 회원가입 버튼
            Row(
              children: [
                Expanded(
                  child: SocialSignUpButton(
                    text: '구글로 회원가입',
                    icon: Image.asset('assets/images/googlelogo.png', width: 24, height: 24),
                    onPressed: _signUpWithGoogle,
                    borderWidth: 1.0,
                    borderColor: Colors.grey.withOpacity(0.5), // 연한 테두리 색상
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15), // 간격 조정

            // 카카오톡으로 회원가입 버튼
            Row(
              children: [
                Expanded(
                  child: SocialSignUpButton(
                    text: '카카오톡으로 회원가입',
                    icon: Image.asset('assets/images/kakao.png', width: 24, height: 24),
                    onPressed: _signUpWithKakao,
                    borderWidth: 1.0,
                    borderColor: Colors.grey.withOpacity(0.5), // 연한 테두리 색상
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30), // 간격 조정
            Spacer(),

            // 계정이 있으신가요? 로그인 부분
// 계정이 있으신가요? 로그인 부분
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '계정이 있으신가요? ',
                    style: TextStyle(
                      color: Color(0xFFADA4A5),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      '로그인',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Color(0xFFFF845C),
                        decoration: TextDecoration.underline, // 로그인 텍스트에만 밑줄 추가
                        decorationColor: Color(0xFFFF845C), // 밑줄 색상 설정
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50), // 간격 조정
          ],
        ),
      ),
    );
  }
}

class SocialSignUpButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final VoidCallback onPressed;
  final double borderWidth; // 박스 두께
  final Color borderColor; // 테두리 색상

  const SocialSignUpButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.borderWidth = 0.0, // 기본값 설정
    required this.borderColor, // 테두리 색상
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor, // 테두리 색상
          width: borderWidth, // 테두리 두께
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onPressed,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10.0), // 패딩 조정
          leading: icon,
          title: Text(text),
          titleAlignment: ListTileTitleAlignment.center, // 타이틀 정렬
        ),
      ),
    );
  }
}