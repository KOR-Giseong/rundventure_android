import 'package:flutter/material.dart';
import 'package:work/challenge/challenge_screen.dart';

import '../../main_screens/main_screen.dart';
import '../challenge.dart';

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 요소들 간에 간격을 자동으로 조정
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Challenge()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 5.0), // 이미지만 오른쪽으로 밀기
              child: Image.asset(
                'assets/images/Back-Navs.png',  // 새 이미지 사용
                width: 70,
                height: 70,
              ),
            ),
          ),
          Text(
            '챌린지 등록',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              '규칙',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFFF845D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
