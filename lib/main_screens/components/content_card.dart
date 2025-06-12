import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../ghostrun_screen/ghostrun_ready.dart';

class ContentCardSection extends StatelessWidget {
  final PageController pageController;
  final int currentPage;
  final Function(int) onPageChanged;
  final String userEmail;

  const ContentCardSection({
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double cardHeight = deviceWidth * 0.5;

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: PageView(
            controller: pageController,
            onPageChanged: onPageChanged,
            children: [
              // ✅ 새로 추가된 카드: _buildNewGhostRunIntroCard
              _buildNewGhostRunIntroCard(context, cardHeight),
              // ✅ 원래 첫 번째였던 _buildBMICard
              _buildBMICard(cardHeight),
              _buildRunningScheduleCard(cardHeight),
              _buildChallengeCard(cardHeight),
            ],
          ),
        ),
        _buildPageIndicator(context),
      ],
    );
  }


  Widget _buildNewGhostRunIntroCard(BuildContext context, double cardHeight) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, // ✅ 파라미터로 받은 context 사용
          MaterialPageRoute(
            builder: (context) => GhostRunReadyPage(),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Card(
          color: Colors.black,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.symmetric(
            horizontal: cardHeight * 0.08,
            vertical: cardHeight * 0.09,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 배경 이미지 (ghostrunpage2)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                  child: Image.asset(
                    'assets/images/ghostrunpage2.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 고스트 캐릭터 이미지 (ghostrunconfirmation2)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 180,
                      height: 300,
                      child: Image.asset(
                        'assets/images/ghostrunconfirmation2.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              // 텍스트 영역
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NEW OPEN 버튼
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0D6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'NEW OPEN',
                        style: TextStyle(
                          color: Color(0xFFF34C16),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 7),
                    const Text(
                      '새로 오픈한 고스트런',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    const Text(
                      '나의 과거 이보다 더 훌륭함\n나의 변화를 느껴보세요!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBMICard(double cardHeight) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userEmail).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorCard("BMI 정보 로드 실패", cardHeight);
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null || !data.containsKey('bmi')) {
          return _buildErrorCard("BMI 정보가 없습니다.", cardHeight);
        }
        final bmi = data['bmi']?.toStringAsFixed(1) ?? 'N/A';
        final bmiValue = double.tryParse(bmi) ?? 0;
        final category = bmiValue < 18.5
            ? "저체중"
            : bmiValue < 25
            ? "정상"
            : bmiValue < 30
            ? "과체중"
            : "비만";
        return _buildStyledCard(
          title: '📊 내 BMI',
          description: '현재 BMI는 $bmi ($category) 입니다.',
          cardHeight: cardHeight,
          backgroundColor: Colors.white,
          trailing: _buildBMIGraph(bmiValue),
        );
      },
    );
  }

  Widget _buildRunningScheduleCard(double cardHeight) {
    final today = DateTime.now();
    final todayFormatted =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userEmail).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return _buildErrorCard("BMI 정보를 불러오는 중입니다.", cardHeight);
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final bmiValue = (userData?['bmi'] ?? 22).toDouble();
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('userRunningData')
              .doc(userEmail)
              .collection('workouts')
              .doc(todayFormatted)
              .collection('records')
              .orderBy('date', descending: true)
              .limit(1)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return _buildErrorCard("운동 기록이 없습니다.", cardHeight);
            }
            final data = snapshot.data!.docs.first.data() as Map<String, dynamic>?;
            if (data == null) {
              return _buildErrorCard("운동 기록이 유효하지 않습니다.", cardHeight);
            }
            final kilometers = (data['kilometers'] ?? 0).toDouble(); // double으로 변환
            final seconds = data['seconds'] ?? 0;
            final kmText = kilometers.toStringAsFixed(3); // 소수점 3자리까지

            return _buildStyledCard(
              title: '🏃 오늘의 운동',
              description: '$kmText km / ${seconds}초',
              cardHeight: cardHeight,
              backgroundColor: Colors.white,
              trailing: _buildExerciseRing(kilometers, bmiValue),
            );
          },
        );
      },
    );
  }

  Widget _buildChallengeCard(double cardHeight) {
    return RotatingChallengeCard(
      cardHeight: cardHeight,
      userEmail: userEmail,
    );
  }

  Widget _buildErrorCard(String message, double cardHeight) {
    return _buildStyledCard(
      title: '⚠️ 정보 없음',
      description: message,
      cardHeight: cardHeight,
      backgroundColor: Colors.white,
    );
  }

  Widget _buildStyledCard({
    required String title,
    required String description,
    required double cardHeight,
    required Color backgroundColor,
    Widget? trailing,
  }) {
    return Card(
      color: backgroundColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: cardHeight * 0.08,
        vertical: cardHeight * 0.09,
      ),
      child: Padding(
        padding: EdgeInsets.all(cardHeight * 0.1),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: cardHeight * 0.14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: cardHeight * 0.06),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: cardHeight * 0.09,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // ✅ 인디케이터 4개로 수정됨
  Widget _buildPageIndicator(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double indicatorSize = deviceWidth * 0.02;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: indicatorSize,
          height: indicatorSize,
          margin: EdgeInsets.symmetric(horizontal: indicatorSize * 0.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPage == index ? Colors.black87 : Colors.black26,
          ),
        );
      }),
    );
  }

  Widget _buildBMIGraph(double bmi) {
    return SizedBox(
      width: 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _bmiBar('저체중', 0, 18.5, bmi, Colors.blue),
          _bmiBar('정상', 18.5, 24.9, bmi, Colors.green),
          _bmiBar('과체중', 25.0, 29.9, bmi, Colors.orange),
          _bmiBar('비만', 30.0, 40.0, bmi, Colors.red),
        ],
      ),
    );
  }

  Widget _bmiBar(String label, double min, double max, double bmi, Color color) {
    final isInRange = bmi >= min && bmi < max;
    final isSelected = isInRange;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: isSelected ? 20 : 10,
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
                    : [],
              ),
            ),
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isSelected ? 14 : 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseRing(double km, double bmi) {
    double target = bmi < 18.5 ? 2 : bmi < 25 ? 3 : bmi < 30 ? 4 : 5;
    double progress = (km / target).clamp(0.0, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
              Text('${(progress * 100).toInt()}%',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        SizedBox(height: 3),
        Text('목표: ${target.toStringAsFixed(1)}km',
            style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

class RotatingChallengeCard extends StatefulWidget {
  final double cardHeight;
  final String userEmail;

  const RotatingChallengeCard({
    required this.cardHeight,
    required this.userEmail,
  });

  @override
  _RotatingChallengeCardState createState() => _RotatingChallengeCardState();
}

class _RotatingChallengeCardState extends State<RotatingChallengeCard> {
  List<Map<String, dynamic>> _challenges = [];
  int _currentIndex = 0;
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int? _parseDuration(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _loadChallenges() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('challenges').get();
      if (snapshot.docs.isEmpty) {
        setState(() {
          _challenges = [];
        });
        return;
      }
      final challenges = snapshot.docs.map((doc) {
        final data = doc.data();
        final participants = data['participants'] as List<dynamic>? ?? [];
        final int? duration = _parseDuration(data['duration']);
        return {
          'title': data['name'] ?? '제목 없음',
          'description':
          '📍 거리: ${data['distance']}km / 기간: ${duration ?? "?"}일\n👥 참여자: ${participants.length}명',
          'startTime': data['startTime'],
          'duration': duration,
          'progress': data['progress'] ?? 0.0,
        };
      }).toList();
      if (challenges.isNotEmpty) {
        setState(() {
          _challenges = challenges;
          _currentIndex = _random.nextInt(_challenges.length);
        });
        _startRotation();
      }
    } catch (e) {
      print('챌린지 로딩 실패: $e');
      setState(() {
        _challenges = [];
      });
    }
  }

  double _calculateProgress(Timestamp? startTime, int? duration) {
    if (startTime == null || duration == null || duration == 0) return 0.0;
    final now = DateTime.now();
    final start = startTime.toDate();
    final end = start.add(Duration(days: duration));
    final total = end.difference(start).inDays;
    final remaining = end.difference(now).inDays;
    final elapsed = (total - remaining).clamp(0, total);
    return elapsed / total;
  }

  void _startRotation() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 8), (timer) {
      if (_challenges.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _challenges.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_challenges.isEmpty) {
      return Center(child: Text('표시할 챌린지가 없습니다.'));
    }
    final challenge = _challenges[_currentIndex];
    final rawProgress = challenge['progress'];
    final progress = (rawProgress is num) ? rawProgress.toDouble().clamp(0.0, 1.0) : 0.0;
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: widget.cardHeight * 0.08,
        vertical: widget.cardHeight * 0.09,
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.cardHeight * 0.1),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    challenge['title'],
                    style: TextStyle(
                      fontSize: widget.cardHeight * 0.13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: widget.cardHeight * 0.06),
                  Text(
                    challenge['description'],
                    style: TextStyle(
                      fontSize: widget.cardHeight * 0.085,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${(progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Container(
                  width: 12,
                  height: widget.cardHeight * 0.5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}