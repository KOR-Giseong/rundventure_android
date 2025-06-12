import 'package:flutter/material.dart';
import '../admin.dart';
import 'components/app_bar_section.dart';
import 'components/content_card.dart';
import 'components/free_running_section.dart';
import 'components/game_challenge_section.dart';
import 'components/bottom_nav_bar.dart';
import 'components/center_button.dart';
import 'constants/main_screen_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'game_running/game_running_section.dart';

class MainScreen extends StatefulWidget {
  final MainScreenConstants constants;
  final bool isAdmin;

  const MainScreen({
    Key? key,
    this.constants = const MainScreenConstants(),
    this.isAdmin = false,
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _isAdmin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _checkAdminClaim();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _checkAdminClaim() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final idTokenResult = await user.getIdTokenResult(true);
      final claims = idTokenResult.claims;

      final isAdmin = claims?['isAdmin'] == true;

      // 강제로 특정 이메일만 관리자 허용
      final emailBasedAdmin = user.email == 'test12@naver.com';

      print("로그인 성공: ${user.email}");
      print("claims 기반 관리자 여부: $isAdmin");
      print("이메일 기반 관리자 여부: $emailBasedAdmin");

      setState(() {
        _isAdmin = emailBasedAdmin; // 또는: isAdmin && emailBasedAdmin
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text("로그인이 필요합니다")));
    }

    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userEmail = user.email!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  AppBarSection(),
                  SizedBox(height: deviceHeight * 0.00),

                  if (_isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AdminScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: Colors.white,
                              textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            child: Text('관리자 모드'),
                          ),
                        ),
                      ),
                    ),

                  ContentCardSection(
                    pageController: _pageController,
                    currentPage: _currentPage,
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    userEmail: userEmail,
                  ),
                  SizedBox(height: deviceHeight * 0.03),
                  FreeRunningSection(
                    constants: widget.constants,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const GameSelectionPage()),
                      );
                    },
                  ),
                  SizedBox(height: deviceHeight * 0.01),
                  GameChallengeSection(),
                  SizedBox(height: widget.constants.underbarHeight + 20),
                ],
              ),
            ),
            BottomNavBar(deviceWidth: deviceWidth),
            CenterButton(animation: _animation, deviceWidth: deviceWidth, constants: widget.constants),
          ],
        ),
      ),
    );
  }
}
