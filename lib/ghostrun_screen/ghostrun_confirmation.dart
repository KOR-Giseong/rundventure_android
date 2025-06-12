import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'ghostrun_start.dart';

class GhostRunChallengeScreen extends StatefulWidget {
  final String userEmail; // 예: 'test@naver.com'

  const GhostRunChallengeScreen({super.key, required this.userEmail});

  @override
  State<GhostRunChallengeScreen> createState() => _GhostRunChallengeScreenState();
}

class _GhostRunChallengeScreenState extends State<GhostRunChallengeScreen> {
  Map<String, dynamic>? selectedRecord;
  bool noRecordOver30Min = false;

  @override
  void initState() {
    super.initState();
    _loadRandomRecord();
  }

  Future<void> _loadRandomRecord() async {
    final firestore = FirebaseFirestore.instance;
    final workoutsSnapshot = await firestore
        .collection('userRunningData')
        .doc(widget.userEmail)
        .collection('workouts')
        .get();

    List<QueryDocumentSnapshot> allRecords = [];

    for (final workout in workoutsSnapshot.docs) {
      final recordsSnapshot = await workout.reference.collection('records').get();
      for (final doc in recordsSnapshot.docs) {
        final data = doc.data();
        final seconds = data['seconds'] ?? 0;
        if (seconds >= 1800) {
          allRecords.add(doc);
        }
      }
    }

    if (allRecords.isNotEmpty) {
      final random = Random();
      final randomRecord = allRecords[random.nextInt(allRecords.length)];
      setState(() {
        selectedRecord = randomRecord.data() as Map<String, dynamic>;
      });
    } else {
      setState(() {
        noRecordOver30Min = true;
      });
    }
  }

  String formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (selectedRecord == null && !noRecordOver30Min) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (noRecordOver30Min) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/ghostrunconfirmation2.png',
                  width: 200,
                ),
                const SizedBox(height: 20),
                const Text(
                  '30분 이상 러닝한 기록이 없습니다',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('뒤로가기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final record = selectedRecord!;
    final double distance = (record['kilometers'] is int)
        ? (record['kilometers'] as int).toDouble()
        : (record['kilometers'] ?? 0.0);

    final double pace = (record['pace'] is int)
        ? (record['pace'] as int).toDouble()
        : (record['pace'] ?? 0.0);

    final int seconds = record['seconds'] ?? 0;
    final DateTime date = (record['date'] as Timestamp).toDate();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/images/ghostrunconfirmation.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/images/Back-Navs-Black.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        '고스트런',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '지난기록 ${date.year % 100}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 35),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 70),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'RUNNING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatDuration(seconds),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 45,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            '과거 나에게 도전이 왔습니다!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: pace.toStringAsFixed(1),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const TextSpan(
                                              text: ' km',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Pace',
                                        style: TextStyle(color: Colors.white60, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        distance.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Km',
                                        style: TextStyle(color: Colors.white60, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: noRecordOver30Min ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GhostRunTrackingScreen(
                              ghostRecord: selectedRecord!,
                            ),
                          ),
                        );
                        // 도전 시작
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '도전하기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -30,
            child: Image.asset(
              'assets/images/ghostrunconfirmation2.png',
              width: 280,
              height: 280,
            ),
          ),
        ],
      ),
    );
  }
}
