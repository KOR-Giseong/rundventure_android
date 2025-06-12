import 'package:flutter/material.dart';

import '../../ghostrun_screen/ghostrun_ready.dart';
import '../../ghostrun_screen/ghostrun_stretching.dart';

class GameSelectionPage extends StatelessWidget {
  const GameSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          '게임 선택',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset('assets/images/Back-Navs.png', width: 70, height: 70),
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.only(left: 8),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            _buildGameCard(
              context,
              '고스트런',
              '나의 과거이력보다 향상된 나!',
              'assets/images/ghostrunpage3-1.png',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StretchingPage()),
                );
              },
            ),
            _buildGameCard(
              context,
              'Coming Soon',
              '조금만 기다려주세요 곧 출시될거에요!',
              'assets/images/game2.png',
                  () {
                // 추후 게임 이동
              },
            ),
            _buildGameCard(
              context,
              'Coming Soon',
              '조금만 기다려주세요 곧 출시될거에요!',
              'assets/images/game3.png',
                  () {
                // 추후 게임 이동
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
      BuildContext context,
      String title,
      String description,
      String imagePath,
      VoidCallback onTap,
      ) {
    // 각 타이틀에 따라 아이콘 다르게 지정
    String iconPath;
    if (title == '고스트런') {
      iconPath = 'assets/images/ghostlogo.png';
    } else {
      iconPath = 'assets/images/soonlogo.png';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(1),
                        Colors.white.withOpacity(0.6),
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.4, 0.8, 1.0, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          iconPath,
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Image.asset(
                      'assets/images/nextbutton.png',
                      width: 40,
                      height: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
