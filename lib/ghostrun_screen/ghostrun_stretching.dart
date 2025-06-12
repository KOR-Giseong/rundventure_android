import 'package:flutter/material.dart';

import '../main_screens/game_running/game_running_section.dart';
import 'StretchingGuidePage.dart';
import 'ghostrun_ready.dart';
import '../../ghostrun_screen/ghostrun_stretching.dart'; // GameSelectionPage 가져오기

class StretchingPage extends StatelessWidget {
  const StretchingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const StretchingPageBody();
  }
}

class StretchingPageBody extends StatefulWidget {
  const StretchingPageBody({Key? key}) : super(key: key);

  @override
  State<StretchingPageBody> createState() => _StretchingPageBodyState();
}

class _StretchingPageBodyState extends State<StretchingPageBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ★ 여기서부터 기존 Scaffold 내용 복사 시작
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(5),
            child: Image.asset(
              'assets/images/Back-Navs-Black.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: const Text(
          "고스트런",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sports_gymnastics, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StretchingGuidePage(),
                ),
              );
            },
          )
        ],
      ),

      body: SafeArea(
        child: Stack(
          children: [
            // 배경 이미지 (ghostrunpage2)
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  'assets/images/ghostrunpage2.png',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),

            // 오버레이 이미지 (stretching)
            Positioned(
              top: 410,
              left: 0,
              right: 20,
              child: Image.asset(
                'assets/images/stretching.png',
                width: double.infinity,
                height: 500,
                fit: BoxFit.contain,
              ),
            ),

            // 본문 내용
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              bottom: 100,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "러닝 하기전",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      "몸을 잘 풀어주세요!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "러닝할 때는 항상 조신하며 몸을 충분히 풀어준 뒤\n운동해주세요!\n준비가 되면 아래 시작버튼을 눌러주세요!",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 시작하기 버튼
            Positioned(
              bottom: 30,
              left: 30,
              right: 30,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GhostRunReadyPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("시작하기"),
              ),
            ),

            // ✅ 스트레칭 아이콘 바로 아래에 말풍선 + 화살표 배치 (애니메이션 적용)
            Positioned(
              top: kToolbarHeight - 45,
              right: 10,
              child: FadeTransition(
                opacity: _controller,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.1).animate(_controller),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 말풍선 본문
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 1.2),
                        ),
                        child: const Text(
                          "스트레칭!",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // 삼각형 화살표 - 말풍선 왼쪽 바깥에 배치
                      Positioned(
                        top: -10,
                        left: 50,
                        child: CustomPaint(
                          size: const Size(14, 14),
                          painter: TrianglePainter(paintColor: Colors.yellow),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✨ 삼각형 화살표 커스텀 페인터 클래스
class TrianglePainter extends CustomPainter {
  final Color paintColor;

  TrianglePainter({required this.paintColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = paintColor;

    final path = Path();
    path.moveTo(0, size.height); // 왼쪽 아래
    path.lineTo(size.width / 2, 0); // 위쪽 중앙
    path.lineTo(size.width, size.height); // 오른쪽 아래
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}