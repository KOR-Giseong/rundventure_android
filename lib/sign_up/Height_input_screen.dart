import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth 임포트
import 'package:work/sign_up/weight_input_screen.dart';
import 'loading_screen.dart'; // 다음 페이지 임포트

class HeightInputScreen extends StatefulWidget {
  final String email;
  final String password;
  final String nickname;
  final String gender;
  final String birthday;
  final String weight;

  const HeightInputScreen({
    Key? key,
    required this.email,
    required this.password,
    required this.nickname,
    required this.gender,
    required this.birthday,
    required this.weight,
  }) : super(key: key);

  @override
  _HeightInputScreenState createState() => _HeightInputScreenState();
}

class _HeightInputScreenState extends State<HeightInputScreen> {
  final TextEditingController _heightController = TextEditingController(); // 키 입력 컨트롤러
  final FirebaseAuth _auth = FirebaseAuth.instance; // FirebaseAuth 인스턴스

  void _goBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WeightInputScreen(
          email: widget.email,
          password: widget.password,
          nickname: widget.nickname,
          gender: widget.gender,
          birthday: widget.birthday, // 이전 화면에서 넘어온 몸무게 전달
        ),
      ),
    ); // 이전 페이지로 이동
  }

  void _navigateNext() async {
    if (_heightController.text.isEmpty) {
      // 경고 다이얼로그 표시
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white, // 다이얼로그 배경을 흰색으로
            title: const Text('경고', style: TextStyle(color: Colors.black)),
            content: const Text('키를 입력해주세요!', style: TextStyle(color: Colors.black)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                },
                child: const Text('확인', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        },
      );
      return; // 키가 비어있으면 다음으로 넘어가지 않음
    }

    // 다음 페이지로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingScreen(
          email: widget.email,
          password: widget.password,
          height: _heightController.text, // 입력된 키 전달
          weight: widget.weight, // 몸무게 전달
          birthdate: widget.birthday, // 생년월일 전달
          gender: widget.gender, // 성별 전달
          nickname: widget.nickname, // 닉네임 전달
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // 키보드가 올라와도 레이아웃 변경하지 않음
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1,
          vertical: screenHeight * 0.25,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 입력 안내 텍스트
            Text(
              '프로필을 입력해주세요!',
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              '러너님에 대해 더 알게 되면 도움이 될 거예요!',
              style: TextStyle(
                color: Colors.grey,
                fontSize: screenWidth * 0.035,
              ),
            ),
            SizedBox(height: screenHeight * 0.04),

            // 키 입력 박스
            Row(
              children: [
                // 키 입력 필드
                Expanded(
                  child: Container(
                    height: screenHeight * 0.07,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _heightController,
                      decoration: InputDecoration(
                        hintText: '키를 입력하세요',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Image.asset(
                            'assets/images/Height.png',
                            width: screenWidth * 0.06,
                            height: screenHeight * 0.06,
                            fit: BoxFit.contain,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),

                // 단위(CM) 박스
                Container(
                  height: screenHeight * 0.07,
                  width: screenWidth * 0.18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9E80).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'CM',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),
          ],
        ),
      ),

      // Bottom Navigation Bar with Previous and Next Buttons
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1,
          vertical: screenHeight * 0.08,
        ),
        child: Row(
          children: [
            // 이전 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: _goBack,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.black, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '이전',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.03), // 버튼 간격

            // 다음 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: _navigateNext,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '다음',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w400,
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
