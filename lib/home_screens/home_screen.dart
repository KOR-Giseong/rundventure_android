import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:work/home_Screens/home_screen2.dart';
import 'package:work/services/user_screen.dart';

class Home_screen extends StatefulWidget {
  @override
  State<Home_screen> createState() => _Home_screenState();
}

class _Home_screenState extends State<Home_screen> {
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.subscribeToTopic('all');
    _hideSystemUI(); // 시작 시 UI 숨기기
  }

  // 🔽 시스템 UI 자동 숨김 함수
  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _hideSystemUI(); // 스크롤 시 UI 숨기기
        return false;
      },
      child: GestureDetector(
        onTap: _hideSystemUI, // 탭 시 UI 숨기기
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // 배경 이미지
                  Positioned.fill(
                    child: Image.asset(
                      "assets/images/running.png",
                      fit: BoxFit.cover,
                    ),
                  ),

                  // 로고
                  Positioned(
                    left: screenWidth * 0.1,
                    top: screenHeight * 0.4,
                    child: Image.asset(
                      "assets/images/rundventure.png",
                      width: screenWidth * 0.8,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // 설명 텍스트 이미지
                  Positioned(
                    left: screenWidth * 0.15,
                    top: screenHeight * 0.55,
                    child: Image.asset(
                      "assets/images/rundventuretext.png",
                      width: screenWidth * 0.7,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // 시작하기 버튼
                  Positioned(
                    left: (screenWidth - screenWidth * 0.8) / 2,
                    bottom: screenHeight * 0.05,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 500),
                            pageBuilder: (context, animation, secondaryAnimation) => Home_screen2(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.07,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '시작하기',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
