import 'package:flutter/material.dart';
import 'height_input_screen.dart';
import 'birthday_input_screen.dart';

class WeightInputScreen extends StatefulWidget {
  final String email;
  final String password;
  final String nickname;
  final String gender;
  final String birthday;

  const WeightInputScreen({
    Key? key,
    required this.email,
    required this.password,
    required this.nickname,
    required this.gender,
    required this.birthday,
  }) : super(key: key);

  @override
  _WeightInputScreenState createState() => _WeightInputScreenState();
}

class _WeightInputScreenState extends State<WeightInputScreen> {
  final TextEditingController _weightController = TextEditingController();

  void _goBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BirthdayInputScreen(
          email: widget.email,
          password: widget.password,
          nickname: widget.nickname,
          gender: widget.gender,
        ),
      ),
    );
  }

  void _navigateNext() {
    if (_weightController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('경고', style: TextStyle(color: Colors.black)),
            content: const Text('체중을 입력해주세요!', style: TextStyle(color: Colors.black)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('확인', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        },
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HeightInputScreen(
          email: widget.email,
          password: widget.password,
          nickname: widget.nickname,
          gender: widget.gender,
          birthday: widget.birthday,
          weight: _weightController.text,
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
      resizeToAvoidBottomInset: false, // 키보드가 올라와도 레이아웃이 변경되지 않도록 설정
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

            // 체중 입력 박스
            Row(
              children: [
                // 체중 입력 필드
                Expanded(
                  child: Container(
                    height: screenHeight * 0.07,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        hintText: '체중을 입력하세요',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Image.asset(
                            'assets/images/weight.png',
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

                // 단위(KG) 박스
                Container(
                  height: screenHeight * 0.07,
                  width: screenWidth * 0.18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9E80).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'KG',
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
