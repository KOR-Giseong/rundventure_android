import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 뒤로가기 버튼과 중앙 제목
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset('assets/images/Back-Navs.png', width: 70, height: 70),
                ),
                const SizedBox(width: 80),
                Expanded(
                  child: Text(
                    '이용약관',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 이용약관 내용 텍스트 박스
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ScrollConfiguration(
                  behavior: CustomScrollBehavior(), // 커스텀 스크롤 동작 설정
                  child: SingleChildScrollView(
                    child: Text(
                      '이용약관의 본문 내용이 여기에 들어갑니다.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// 커스텀 스크롤 동작 정의
class CustomScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return Scrollbar(
      thumbVisibility: true, // 스크롤바 항상 보이기
      radius: Radius.circular(10), // 스크롤바 둥글기
      thickness: 8, // 스크롤바 두께
      child: super.buildScrollbar(context, child, details),
    );
  }
}