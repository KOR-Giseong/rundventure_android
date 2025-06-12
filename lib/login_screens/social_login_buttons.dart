import 'package:flutter/material.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // 세로 정렬
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // 가로 정렬
          children: [
            GestureDetector(
              onTap: () {
                // 구글 로그인 처리
              },
              child: Image.asset(
                'assets/images/googlelogo.png', // 구글 버튼 이미지 파일 이름 입력
                width: 130,
                height: 50,
              ),
            ),
            const SizedBox(width: 10), // 버튼 사이 여백
            GestureDetector(
              onTap: () {
                // 카카오 로그인 처리
              },
              child: Image.asset(
                'assets/images/kakao.png', // 카카오 버튼 이미지 파일 이름 입력
                width: 130,
                height: 50,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
