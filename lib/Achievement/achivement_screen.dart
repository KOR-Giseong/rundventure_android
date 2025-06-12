import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// 운동 기록 모델
class ExerciseRecord {
  final String id;
  final double kilometers;
  final DateTime date;
  final String userId;

  ExerciseRecord({
    required this.id,
    required this.kilometers,
    required this.date,
    required this.userId,
  });

  factory ExerciseRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseRecord(
      id: doc.id,
      kilometers: (data['kilometers'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }
}

// 도전과제 달성 정보 모델
class AchievementInfo {
  final double targetDistance;
  final bool isCompleted;
  final DateTime? completionDate;

  AchievementInfo({
    required this.targetDistance,
    required this.isCompleted,
    this.completionDate,
  });
}

// 운동 기록 서비스
class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<ExerciseRecord>> getAllExerciseRecords() async {
    try {
      final String? userEmail = _auth.currentUser?.email;
      if (userEmail == null) {
        throw Exception('사용자 이메일을 가져올 수 없습니다.');
      }

      // workouts(날짜) 문서들을 불러오기
      final workoutsSnapshot = await _firestore
          .collection('userRunningData')
          .doc(userEmail)
          .collection('workouts')
          .get();

      List<ExerciseRecord> allRecords = [];

      // 각 날짜 문서의 records 서브컬렉션 탐색
      for (var workoutDoc in workoutsSnapshot.docs) {
        final recordsSnapshot = await _firestore
            .collection('userRunningData')
            .doc(userEmail)
            .collection('workouts')
            .doc(workoutDoc.id)
            .collection('records')
            .get();

        for (var recordDoc in recordsSnapshot.docs) {
          final data = recordDoc.data();

          if (data.containsKey('kilometers') && data.containsKey('date')) {
            allRecords.add(
              ExerciseRecord(
                id: recordDoc.id,
                kilometers: (data['kilometers'] ?? 0.0).toDouble(),
                date: (data['date'] as Timestamp).toDate(),
                userId: userEmail,
              ),
            );
          }
        }
      }

      // 날짜순 정렬
      allRecords.sort((a, b) => a.date.compareTo(b.date));

      return allRecords;
    } catch (e) {
      rethrow;
    }
  }



  Future<double> calculateTotalDistance() async {
    final records = await getAllExerciseRecords();
    double totalDistance = 0.0;
    for (var record in records) {
      totalDistance += record.kilometers;
    }
    return totalDistance;
  }

  // 특정 목표 거리에 대한 달성 정보 계산
  Future<AchievementInfo> getAchievementInfo(double targetDistance) async {
    final records = await getAllExerciseRecords();

    if (records.isEmpty) {
      return AchievementInfo(
        targetDistance: targetDistance,
        isCompleted: false,
      );
    }

    double cumulativeDistance = 0.0;
    DateTime? completionDate;

    // 날짜순으로 정렬된 기록을 순회하며 목표 달성 날짜 찾기
    for (var record in records) {
      cumulativeDistance += record.kilometers;

      // 이번 기록을 더했을 때 처음으로 목표를 달성한 경우
      if (cumulativeDistance >= targetDistance && completionDate == null) {
        completionDate = record.date;
      }
    }

    return AchievementInfo(
      targetDistance: targetDistance,
      isCompleted: cumulativeDistance >= targetDistance,
      completionDate: completionDate,
    );
  }
}

// 도전과제 화면
class AchievementScreen extends StatefulWidget {
  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  double _totalDistance = 0.0;
  bool _isLoading = true;
  List<AchievementInfo> _achievements = [];
  final List<double> _targetDistances = [10, 100, 1000, 10000];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // 총 거리 계산
      final totalDistance = await _exerciseService.calculateTotalDistance();

      // 각 목표별 달성 정보 계산
      List<AchievementInfo> achievements = [];
      for (double target in _targetDistances) {
        final achievementInfo = await _exerciseService.getAchievementInfo(target);
        achievements.add(achievementInfo);
      }

      setState(() {
        _totalDistance = totalDistance;
        _achievements = achievements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 로딩 중 오류가 발생했습니다: $e')),
      );
    }
  }

  String _getBadgeTitle(double targetDistance) {
    if (targetDistance <= 10) return 'IRON';
    if (targetDistance <= 100) return 'BRONZE';
    if (targetDistance <= 1000) return 'SILVER';
    return 'GOLD';
  }

  // 배지 이미지 경로를 가져오는 함수
  String _getBadgeImagePath(String badgeTitle, bool isCompleted) {
    if (!isCompleted) {
      return 'assets/badges/unrank_badge.png';
    }

    switch (badgeTitle) {
      case 'IRON':
        return 'assets/badges/iron_badge.png';
      case 'BRONZE':
        return 'assets/badges/bronze_badge.png';
      case 'SILVER':
        return 'assets/badges/silver_badge.png';
      case 'GOLD':
        return 'assets/badges/gold_badge.png';
      default:
        return 'assets/badges/unrank_badge.png';
    }
  }

  void showChallengeCompletionPopup(BuildContext context, AchievementInfo achievement) {
    final String badgeTitle = _getBadgeTitle(achievement.targetDistance);
    final String badgeImagePath = _getBadgeImagePath(badgeTitle, true);
    final DateTime completionDate = achievement.completionDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 닫기 버튼 (오른쪽 상단)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // ✨ 배지 이미지에 살짝 튕기는 애니메이션
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.8),
                duration: Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Image.asset(
                  badgeImagePath,
                  width: 180,
                  height: 180,
                ),
              ),
              SizedBox(height: 20),
              // 목표 거리 텍스트
              Text(
                '${achievement.targetDistance.toStringAsFixed(0)}KM',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              // 설명 텍스트
              Text(
                '총 ${achievement.targetDistance.toStringAsFixed(0)}KM 달성',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // 달성 날짜
              Container(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  DateFormat('yyyy.MM.dd').format(completionDate),
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
              SizedBox(height: 20),
              // 닫기 버튼 (검정색)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('닫기', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    side: BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChallengeCard(AchievementInfo achievement) {
    final String badgeTitle = _getBadgeTitle(achievement.targetDistance);
    final String badgeImagePath = _getBadgeImagePath(badgeTitle, achievement.isCompleted);
    double progress = (_totalDistance / achievement.targetDistance).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(6.0), // 도전과제 카드 간 약간의 여백 추가
      child: GestureDetector(
        onTap: () {
          if (achievement.isCompleted) {
            showChallengeCompletionPopup(context, achievement);
          }
        },
        child: AnimatedScale(
          scale: achievement.isCompleted ? 1.05 : 1.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [], // 노란 그림자 제거
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 90,
                      width: 90,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          achievement.isCompleted ? Colors.green: Colors.grey,
                        ),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    Image.asset(
                      badgeImagePath,
                      width: 60,
                      height: 60,
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  '+ ${achievement.targetDistance.toStringAsFixed(0)}KM',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  achievement.isCompleted ? '달성완료!' : '도전중',
                  style: TextStyle(
                    color: achievement.isCompleted ? Colors.green : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _isLoading
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
                : Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  // 상단 네비게이션 (뒤로가기 버튼 + 도전과제 텍스트)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/images/Back-Navs.png', // 뒤로가기 버튼 이미지
                          width: 70,
                          height: 70,
                        ),
                      ),
                      Column(
                        children: [
                          Icon(Icons.emoji_events, color: Colors.amber[800], size: 30),
                          Text(
                            '도전과제',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.grey.withOpacity(0.5),
                                  offset: Offset(1, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 65), // 가운데 정렬용
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 총 누적 거리 카드 (노란 불빛 제거)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [], // 노란 그림자 제거
                    ),
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(text: '+ ${_totalDistance.toStringAsFixed(1)}'),
                              TextSpan(
                                text: 'KM',
                                style: TextStyle(fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _loadData,
                          child: const Text(
                            '누적 거리',
                            style: TextStyle(color: Colors.black),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 도전과제 그리드
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: screenHeight * 0.02,
                      crossAxisSpacing: screenWidth * 0.02,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _achievements.length,
                    itemBuilder: (context, index) {
                      return Container(
                        height: screenHeight * 0.2,
                        child: _buildChallengeCard(_achievements[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}