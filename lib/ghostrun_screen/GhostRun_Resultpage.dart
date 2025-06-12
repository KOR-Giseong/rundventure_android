import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'ghostrun_ready.dart';

// 재사용 가능한 결과 다이얼로그 위젯
class GhostRunHistoryDialog extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const GhostRunHistoryDialog({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '고스트런 기록',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[800]),

            // 기록 목록
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];

                  // 날짜 형식 변환
                  String dateText = "기록 없음";
                  if (record['date'] != null) {
                    if (record['date'] is Timestamp) {
                      final Timestamp timestamp = record['date'] as Timestamp;
                      final DateTime recordDate = timestamp.toDate();
                      dateText = index == 0
                          ? "오늘 기록 ${DateFormat('yy.MM.dd').format(recordDate)}"
                          : "지난 기록 ${DateFormat('yy.MM.dd').format(recordDate)}";
                    }
                  }

                  // 시간 형식 변환
                  String timeText = "--:--";
                  if (record['time'] != null) {
                    final int timeInSeconds = (record['time'] as num).toInt();
                    final int minutes = timeInSeconds ~/ 60;
                    final int seconds = timeInSeconds % 60;
                    timeText = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
                  }

                  // 거리 형식 변환
                  String distanceText = "--";
                  if (record['distance'] != null) {
                    final double distance = (record['distance'] as num).toDouble();
                    distanceText = "${distance.toStringAsFixed(2)}km";
                  }

                  // 페이스 형식 변환
                  String paceText = "--";
                  if (record['pace'] != null) {
                    final double pace = (record['pace'] as num).toDouble();
                    final paceMinutes = pace.floor();
                    final paceSeconds = ((pace - paceMinutes) * 60).floor();
                    paceText = "$paceMinutes:${paceSeconds.toString().padLeft(2, '0')}";
                  }

                  // 레이스 결과 표시
                  String resultText = "";
                  Color resultColor = Colors.grey;
                  if (record['raceResult'] != null) {
                    final String result = record['raceResult'] as String;
                    if (result == 'win') {
                      resultText = " (승리)";
                      resultColor = Colors.green;
                    } else if (result == 'lose') {
                      resultText = " (패배)";
                      resultColor = Colors.red;
                    } else {
                      resultText = " (무승부)";
                      resultColor = Colors.orange;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$dateText$resultText",
                          style: TextStyle(
                            color: resultColor,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildRecordCard(timeText, 'Time'),
                            _buildRecordCard(distanceText, 'Distance'),
                            _buildRecordCard(paceText, 'min/km'),
                          ],
                        ),
                        if (index < records.length - 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Divider(color: Colors.grey[800]),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 닫기 버튼
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(120, 40),
                ),
                child: const Text("닫기", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(String value, String label) {
    return Container(
      width: 90,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

class GhostRunResultScreen extends StatefulWidget {
  final Map<String, dynamic> userResult;
  final Map<String, dynamic> ghostResult;
  final bool isWin;

  const GhostRunResultScreen({
    Key? key,
    required this.userResult,
    required this.ghostResult,
    required this.isWin,
  }) : super(key: key);

  @override
  State<GhostRunResultScreen> createState() => _GhostRunResultScreenState();
}

class _GhostRunResultScreenState extends State<GhostRunResultScreen> {
  // 파이어베이스 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 모든 기록 저장 리스트
  List<Map<String, dynamic>> _allRecords = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 모든 기록 데이터 로드
    _loadAllUserRecords();
  }

  // 사용자의 모든 레코드 가져오기
  Future<void> _loadAllUserRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 로그인된 사용자 이메일 가져오기
      final String userEmail = _auth.currentUser?.email ?? '';
      if (userEmail.isEmpty) {
        print('로그인된 사용자가 없습니다.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Firestore에서 모든 레코드 가져오기 (최대 20개)
      final recordsSnapshot = await _firestore
          .collection('ghostRunRecords')
          .doc(userEmail)
          .collection('records')
          .orderBy('date', descending: true)
          .limit(20)
          .get();

      if (recordsSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> records = [];
        for (var doc in recordsSnapshot.docs) {
          var data = doc.data();
          // docId도 함께 저장
          data['id'] = doc.id;
          records.add(data);
        }

        setState(() {
          _allRecords = records;
          _isLoading = false;
        });

        print('사용자의 모든 기록을 성공적으로 불러왔습니다: ${records.length}개');
      } else {
        print('사용자의 이전 레코드가 없습니다.');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('모든 레코드 로딩 중 오류 발생: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 지난기록 더보기 팝업 표시
  void _showRecordsDialog() {
    if (_allRecords.isEmpty) {
      // 기록이 없는 경우 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('불러올 기록이 없습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => GhostRunHistoryDialog(records: _allRecords),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 러닝 데이터 추출
    final String userTime = _formatTime(widget.userResult['time'] ?? 0);
    final String userDistance = _formatDistance(widget.userResult['distance'] ?? 0.0);
    final String userPace = _formatPace(widget.userResult['pace'] ?? 0.0);

    final String ghostTime = _formatTime(widget.ghostResult['time'] ?? 0);
    final String ghostDistance = _formatDistance(widget.ghostResult['distance'] ?? 0.0);
    final String ghostPace = _formatPace(widget.ghostResult['pace'] ?? 0.0);

    String resultMessage = widget.isWin ? "수고하셨습니다!\n결과를 확인해주세요!" : "과거의 나에게 패배했습니다!";
    String comparisonMessage = widget.isWin ? "과거의 나에게 이겼습니다!" : "과거의 나에게 뒤쳐졌습니다!";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          '고스트런 결과',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            bottom: 0,
            child: Image.asset(
              'assets/images/ghostrunconfirmation.png',
              fit: BoxFit.cover,
            ),
          ),

          // 고스트 캐릭터
          Positioned(
            bottom: 10,
            right: 10,
            child: Image.asset(
              'assets/images/ghostrunconfirmation2.png',
              width: 120,
              height: 120,
            ),
          ),

          // 메인 콘텐츠
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // 타이틀 메시지
                  Text(
                    resultMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 안내 메시지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      comparisonMessage,
                      style: TextStyle(
                        color: widget.isWin ? Colors.green : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 내 결과
                  _buildResultCard("Me", userTime, userDistance, userPace, Colors.blue),

                  const SizedBox(height: 25),

                  // 고스트 결과
                  _buildResultCard("Ghost", ghostTime, ghostDistance, ghostPace, Colors.purple),

                  const Spacer(),

                  // 지난기록 보기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _showRecordsDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        '지난기록 더보기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 확인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GhostRunReadyPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 결과 카드 위젯
  Widget _buildResultCard(String title, String time, String distance, String pace, Color iconColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                title == "Me" ? Icons.person : Icons.directions_run,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildMetricBox(time, "Time"),
              const SizedBox(width: 10),
              _buildMetricBox(distance, "Distance"),
              const SizedBox(width: 10),
              _buildMetricBox(pace, "min/km"),
            ],
          ),
        ],
      ),
    );
  }

  // 지표 박스 위젯
  Widget _buildMetricBox(String value, String label) {
    return Expanded(
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade800, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 시간 포맷팅
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  // 거리 포맷팅
  String _formatDistance(double distance) {
    return "${distance.toStringAsFixed(2)}km";
  }

  // 페이스 포맷팅
  String _formatPace(double pace) {
    final paceMinutes = pace.floor();
    final paceSeconds = ((pace - paceMinutes) * 60).floor();
    return "$paceMinutes:${paceSeconds.toString().padLeft(2, '0')}";
  }
}