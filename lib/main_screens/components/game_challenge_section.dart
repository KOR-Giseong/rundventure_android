import 'package:flutter/material.dart';
import 'package:work/challenge/challenge.dart';
import '../../Achievement/achivement_screen.dart';

class GameChallengeSection extends StatelessWidget {
  final double gameRunTitleSpacing;
  final double gameRunDescriptionSpacing;
  final double challengeTitleSpacing;
  final double challengeDescriptionSpacing;

  // 텍스트 크기 조절용 파라미터 추가
  final double titleFontSize;
  final double descriptionFontSize;

  const GameChallengeSection({
    Key? key,
    this.gameRunTitleSpacing = 3.0,
    this.gameRunDescriptionSpacing = 100.0,
    this.challengeTitleSpacing = 3.0,
    this.challengeDescriptionSpacing = 120.0,
    this.titleFontSize = 22.0,
    this.descriptionFontSize = 14.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double cardHeight = deviceWidth * 0.59;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.03),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: deviceWidth * 0.015),
              child: _buildGameRunCard(context, cardHeight),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: deviceWidth * 0.015),
              child: _buildChallengeCard(context, cardHeight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameRunCard(BuildContext context, double cardHeight) {
    return _buildCard(
      context: context,
      imagePath: 'assets/images/runningimage2.png',
      title: '챌린지',
      description: '여러 챌린지에 참여해 목표를 이루세요!',
      cardHeight: cardHeight,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Challenge()),
        );
      },
    );
  }

  Widget _buildChallengeCard(BuildContext context, double cardHeight) {
    return _buildCard(
      context: context,
      imagePath: 'assets/images/runningimage3.png',
      title: '도전과제',
      description: '도전과제를 통해 성장해요!',
      cardHeight: cardHeight,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AchievementScreen()),
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String imagePath,
    required String title,
    required String description,
    required double cardHeight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        margin: const EdgeInsets.only(bottom: 5.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Stack(
          children: [
            _buildCardImage(imagePath, cardHeight),
            _buildCardGradient(),
            _buildCardContent(context, title, description),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(String imagePath, double cardHeight) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        imagePath,
        width: double.infinity,
        height: cardHeight,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildCardGradient() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [
              Colors.white.withOpacity(0.6),
              Colors.white,
            ],
            stops: [0.1, 0.5],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, String title, String description) {
    // 카드별 이미지 설정
    final String topImagePath = title == '챌린지'
        ? 'assets/images/graph.png'
        : 'assets/images/trophy.png';
    const String bottomImagePath = 'assets/images/nextbutton.png';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
        children: [
          Image.asset(
            topImagePath,
            width: 24,
            height: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: descriptionFontSize,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Image.asset(
            bottomImagePath,
            width: 40,
            height: 40,
          ),
        ],
      ),
    );
  }

}
