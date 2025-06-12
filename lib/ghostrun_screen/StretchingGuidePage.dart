import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class StretchingGuidePage extends StatelessWidget {
  const StretchingGuidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("스트레칭 방법"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 스크롤 가능한 본문 내용
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 🧘‍♂️ 팔벌려뛰기 섹션
                const Text(
                  "팔벌려뛰기",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200, // 🔽 높이 축소
                  child: Lottie.asset('assets/lottie/armsjump.json'),
                ),
                const Text(
                  "1. 양발을 모으고 똑바로 선 상태를 유지하세요.\n"
                      "2. 팔을 머리 위로 벌리면서 동시에 발을 어깨 너비만큼 벌립니다.\n"
                      "3. 원래 자세로 돌아오세요.\n"
                      "4. 이 동작을 10회 반복합니다.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),

                // 🧘‍♀️ 스쿼트 섹션
                const Text(
                  "스쿼트 (다리 스트레칭)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200, // 🔽 높이 축소
                  child: Lottie.asset('assets/lottie/legexercise.json'),
                ),
                const Text(
                  "1. 발을 어깨 너비만큼 벌리고 똑바로 선 상태를 만듭니다.\n"
                      "2. 상체를 곧게 펴고 천천히 무릎을 구부리며 앉습니다.\n"
                      "3. 허벅지가 바닥과 평행이 될 때까지 내려오세요.\n"
                      "4. 다시 일어서고, 이 동작을 10회 반복합니다.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text("닫기"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}