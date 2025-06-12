import 'package:flutter/material.dart';
import '../login_screens/login_screen.dart';
import 'package:work/sign_up/sign_up_screen.dart';

class Home_screen2 extends StatefulWidget {
  @override
  _Home_screen2State createState() => _Home_screen2State();
}

class _Home_screen2State extends State<Home_screen2> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _controller = AnimationController(
      duration: Duration(seconds: 3), // 3초 동안 애니메이션 진행
      vsync: this,
    )..repeat(reverse: true); // 반복 애니메이션

    // 투명도 애니메이션 설정 (처음에 서서히 나타남)
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.2)), // 앞부분에 투명도 변화
    );

    // 크기 애니메이션 설정 (작게 -> 커졌다가 반복)
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // 화면 너비
    final screenHeight = MediaQuery.of(context).size.height; // 화면 높이

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/running2.png"), // 배경 이미지
                  fit: BoxFit.cover, // 이미지가 화면을 꽉 채우도록
                ),
              ),
              child: Stack(
                children: [
                  // Rundventure 로고 이미지에 애니메이션 적용
                  Positioned(
                    left: screenWidth * 0.5 - screenWidth * 0.35, // 화면 중심에 배치
                    top: screenHeight * 0.3, // 화면 상단에서 30% 지점
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _opacityAnimation.value, // 서서히 나타나는 효과
                          child: Transform.scale(
                            scale: _scaleAnimation.value, // 크기 애니메이션 적용
                            child: Image.asset(
                              "assets/images/rundventure2.png", // 로고 이미지
                              width: screenWidth * 0.7, // 화면 너비의 70%
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // "로그인" 버튼
                  Positioned(
                    left: screenWidth * 0.08, // 왼쪽 여백 (8%)
                    bottom: screenHeight * 0.08, // 아래에서부터 8% 띄움
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 500), // 0.5초 애니메이션
                            pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation, // 페이드 인 효과
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        width: screenWidth * 0.4, // 버튼 너비 (화면 너비의 40%)
                        height: screenHeight * 0.06, // 버튼 높이 (화면 높이의 6%)
                        decoration: ShapeDecoration(
                          color: Colors.black, // 검정색 배경
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: Colors.black), // 테두리 색상 및 두께
                            borderRadius: BorderRadius.circular(15), // 둥근 모서리
                          ),
                        ),
                        alignment: Alignment.center, // 텍스트 중앙 정렬
                        child: Text(
                          '로그인', // 한글 텍스트로 수정
                          style: TextStyle(
                            color: Colors.white, // 텍스트 흰색
                            fontSize: screenWidth * 0.045, // 폰트 크기 (화면 너비 비율)
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400, // 굵기 설정
                          ),
                        ),
                      ),
                    ),
                  ),

                  // "가입하기" 버튼
                  Positioned(
                    right: screenWidth * 0.08, // 오른쪽 여백 (8%)
                    bottom: screenHeight * 0.08, // 아래에서부터 8% 띄움
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 500), // 0.5초 애니메이션
                            pageBuilder: (context, animation, secondaryAnimation) => SignUpScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation, // 페이드 인 효과
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        width: screenWidth * 0.4, // 버튼 너비 (화면 너비의 40%)
                        height: screenHeight * 0.06, // 버튼 높이 (화면 높이의 6%)
                        decoration: ShapeDecoration(
                          color: Colors.white, // 흰색 배경
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: Colors.white), // 테두리 흰색
                            borderRadius: BorderRadius.circular(15), // 둥근 모서리
                          ),
                        ),
                        alignment: Alignment.center, // 텍스트 중앙 정렬
                        child: Text(
                          '가입하기', // 한글 텍스트로 수정
                          style: TextStyle(
                            color: Colors.black, // 텍스트 검정색
                            fontSize: screenWidth * 0.044, // 폰트 크기 (화면 너비 비율)
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400, // 굵기 설정
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
