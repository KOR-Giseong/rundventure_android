import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../RunningData_screen/RunningDataScreen.dart';

class BottomNavBar extends StatelessWidget {
  final double deviceWidth;
  static const double underbarHeight = 119.0;

  const BottomNavBar({
    Key? key,
    required this.deviceWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      child: Container(
        height: underbarHeight,
        color: const Color(0xFFF9F9F9),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/underbar.png',
              width: deviceWidth,
              fit: BoxFit.fill,
            ),
            _buildHomeButton(context),
            _buildChartButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    final double buttonWidth = deviceWidth * 0.1; // 디바이스 크기에 비례한 너비
    final double buttonHeight = underbarHeight * 0.2; // 언더바 높이에 비례한 높이

    return Positioned(
      left: deviceWidth * 0.13, // 디바이스 너비 기준으로 위치 조정
      child: GestureDetector(
        onTap: () {},
        child: Image.asset(
          'assets/images/underbarhome.png',
          width: buttonWidth,
          height: buttonHeight,
        ),
      ),
    );
  }

  Widget _buildChartButton(BuildContext context) {
    final double buttonWidth = deviceWidth * 0.1; // 디바이스 크기에 비례한 너비
    final double buttonHeight = underbarHeight * 0.2; // 언더바 높이에 비례한 높이

    return Positioned(
      right: deviceWidth * 0.13, // 디바이스 너비 기준으로 위치 조정
      child: GestureDetector(
        onTap: () {
          String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RunningStatsPage(date: currentDate),
            ),
          );
        },
        child: Image.asset(
          'assets/images/underbarchart.png',
          width: buttonWidth,
          height: buttonHeight,
        ),
      ),
    );
  }
}
