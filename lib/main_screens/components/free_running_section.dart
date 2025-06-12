import 'package:flutter/material.dart';
import '../constants/main_screen_constants.dart';

class FreeRunningSection extends StatelessWidget {
  final MainScreenConstants constants;
  final VoidCallback? onTap;

  const FreeRunningSection({
    Key? key,
    required this.constants,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 180, // 높이 늘려줌 (next 버튼 이미지 공간 확보)
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/runningimage.png',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              _buildGradientOverlay(),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.centerLeft,
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.9),
            ],
            stops: [0.1, 0.5],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/flame.png', // 불꽃 아이콘 경로
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '게임런',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '다양한 콘텐츠로 질리지 않는 게임런!',
            style: TextStyle(fontSize: 14, color: Colors.black45),
          ),
          const SizedBox(height: 12),
          Image.asset(
            'assets/images/nextbutton.png', // next 버튼 이미지 경로
            width: 40,
            height: 40,
          ),
        ],
      ),
    );
  }
}
