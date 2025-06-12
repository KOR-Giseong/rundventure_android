import 'package:flutter/material.dart';
import 'package:work/challenge/challenge.dart'; // 추가
import 'package:work/challenge/challenge_screen.dart'; // 추가
import '../../main_screens/main_screen.dart';
import '../challenge_setup_screen.dart';

class NavigationBar extends StatelessWidget {
  const NavigationBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 🔸 뒤로 가기 버튼 (오른쪽으로 이동)
        Padding(
          padding: const EdgeInsets.only(left: 17.0), // ← 이 부분으로 오른쪽 이동
          child: IconButton(
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
        ),

        // 챌린지 텍스트 (오른쪽으로 살짝)
        Padding(
          padding: const EdgeInsets.only(left: 3.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Challenge()),
              );
            },
            child: Text(
              '챌린지',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ),

        // 사담 텍스트 (강조 스타일)
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
              fontWeight: FontWeight.w800,
              fontSize: 18,
              fontFamily: 'Inter',
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // 메뉴 버튼
        Padding(
          padding: const EdgeInsets.only(right: 20.0), // ← 여기 값을 줄여서 왼쪽으로 살짝 이동
          child: IconButton(
            icon: Image.asset(
              'assets/images/menu.png',
              width: 50,
              height: 50,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChallengeSetupScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}

