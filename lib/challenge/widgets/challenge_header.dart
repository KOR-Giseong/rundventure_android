import 'package:flutter/material.dart';
import 'package:work/challenge/challenge.dart';
import 'package:work/challenge/challenge_screen.dart';
import '../challenge_setup_screen.dart';
import 'package:work/main_screens/main_screen.dart';

class ChallengeHeader extends StatelessWidget {
  const ChallengeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 🔸 뒤로 가기 버튼
        IconButton(
          icon: Image.asset(
            'assets/images/Back-Navs.png',
            width: 70,
            height: 70,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          },
        ),

        // 🔸 챌린지 텍스트 - 강조 스타일
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Challenge()),
            );
          },
          child: Text(
            '챌린지',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              fontFamily: 'Inter',
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // 🔸 사담 텍스트 (기본 스타일)
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChallengeScreen()),
            );
          },
          child: Text(
            '사담',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(width: 75)
      ],
    );
  }
}