import 'package:flutter/material.dart';
import '../../free_running/free_running_start.dart';
import '../constants/main_screen_constants.dart';

class CenterButton extends StatelessWidget {
  final Animation<double> animation;
  final double deviceWidth;
  final MainScreenConstants constants;

  const CenterButton({
    Key? key,
    required this.animation,
    required this.deviceWidth,
    required this.constants,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMainButton(context),
        _buildCoverButton(context),
      ],
    );
  }

  Widget _buildMainButton(BuildContext context) {
    return Positioned(
      bottom: constants.centerButtonHeight / 2,
      left: (deviceWidth - constants.centerButtonWidth) / 2,
      child: GestureDetector(
        onTap: () => _navigateToRunningPage(context),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/centerbutton.png',
              width: constants.centerButtonWidth,
              height: constants.centerButtonHeight,
            ),
            _buildAnimatedArrow(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedArrow() {
    return Positioned(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value,
            child: Image.asset(
              'assets/images/buttonurrow.png',
              width: constants.centerButtonWidth * 0.3, // 버튼 너비에 비례 조정
              height: constants.centerButtonHeight * 0.3, // 버튼 높이에 비례 조정
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoverButton(BuildContext context) {
    return Positioned(
      left: (deviceWidth - constants.buttonCoverWidth) / 2, // 중앙 정렬
      bottom: constants.buttonCoverBottom,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value,
            child: GestureDetector(
              onTap: () => _navigateToRunningPage(context),
              child: Container(
                width: constants.buttonCoverWidth,
                height: constants.buttonCoverHeight,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  'assets/images/buttoncover.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToRunningPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RunningPage()),
    );
  }
}
