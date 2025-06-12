import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'FirstGhostRun_Tracking.dart';
import 'GhostRunRulePage.dart';
import 'GhostRun_TrackingPage.dart';  // 고스트런 트래킹 페이지 import 추가

// 고스트런 결과 팝업 다이얼로그 위젯
class GhostRunResultDialog extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  const GhostRunResultDialog({super.key, required this.records});
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
          mainAxisSize: MainAxisSize.min, // 내용에 맞게 크기 조정
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '고스트런 결과',
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
                maxHeight: MediaQuery.of(context).size.height * 0.6, // 화면 높이의 60%로 제한
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
                          ? "오늘기록 ${DateFormat('yy.MM.dd').format(recordDate)}"
                          : "지난기록 ${DateFormat('yy.MM.dd').format(recordDate)}";
                    } else {
                      dateText = index == 0 ? "오늘기록" : "지난기록";
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
                    paceText = pace.toStringAsFixed(2);
                  }
                  // 레이스 결과 표시 추가
                  String resultText = "";
                  if (record['raceResult'] != null) {
                    final String result = record['raceResult'] as String;
                    resultText = result == 'win' ? ' (승리)' : (result == 'lose' ? ' (패배)' : ' (무승부)');
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$dateText$resultText",  // 결과 텍스트 추가
                          style: TextStyle(
                            color: record['raceResult'] == 'win' ? Colors.green[400] :
                            (record['raceResult'] == 'lose' ? Colors.red[400] : Colors.grey[400]),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            buildRecordCard(timeText, 'Time'),
                            buildRecordCard(distanceText, 'Distance'),
                            buildRecordCard(paceText, 'min/km'),
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

  Widget buildRecordCard(String value, String label) {
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

class GhostRunPage extends StatefulWidget {
  final Map<String, dynamic>? ghostRecord;
  const GhostRunPage({super.key, this.ghostRecord});
  @override
  State<GhostRunPage> createState() => _GhostRunPageState();
}

class _GhostRunPageState extends State<GhostRunPage> {
  // 타이머 관련 변수
  String _displayTime = "--:--";  // 기록 없을 때는 --:-- 표시
  // 런닝 데이터
  String _distanceDisplay = "--";  // 기록 없을 때는 -- 표시
  String _paceDisplay = "-- ";    // 기록 없을 때는 -- km 표시
  double _distance = 0.0;
  double _pace = 0.0;
  // 고스트 캐릭터 위치 설정
  double _ghostBottomPosition = 20.0;
  double _ghostRightPosition = 20.0;
  // 현재 날짜 표시
  String _currentDate = "--.--.--";  // 기록 없을 때는 --.--.-- 표시
  // 도전 메시지
  String _challengeMessage = "도전을 시도해보세요!";  // 기본 메시지 변경
  // 기록 존재 여부
  bool _hasRecord = false;
  // 파이어베이스 관련 변수
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _latestRecord;
  bool _isLoading = false;
  // 레이스 결과 표시 변수
  String _raceResultText = "";
  Color _raceResultColor = Colors.white;
  // 사용자의 모든 기록을 저장하는 리스트
  List<Map<String, dynamic>> _allRecords = [];

  // ✅ 새로 추가된 함수: Firestore 데이터 삭제 및 초기화
  Future<void> _resetGhostRunData() async {
    try {
      final String userEmail = _auth.currentUser?.email ?? '';
      if (userEmail.isEmpty) {
        print('로그인된 사용자가 없습니다.');
        return;
      }

      final CollectionReference userRecordsRef = _firestore
          .collection('ghostRunRecords')
          .doc(userEmail)
          .collection('records');

      final DocumentReference userDocRef = _firestore.collection('ghostRunRecords').doc(userEmail);

      // 기존 모든 기록 삭제
      final QuerySnapshot snapshot = await userRecordsRef.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // 최신 기록 참조 초기화
      await userDocRef.update({
        'latestRecordId': FieldValue.delete(),
        'latestRecordDate': FieldValue.delete(),
      });

      setState(() {
        _hasRecord = false;
        _latestRecord = null;
        _allRecords.clear();
        _displayTime = "--:--";
        _distanceDisplay = "--";
        _paceDisplay = "--";
        _currentDate = "--.--.--";
        _raceResultText = "";
        _challengeMessage = "첫 도전 시작하기!";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록이 초기화되었습니다.')),
      );
    } catch (e) {
      print('데이터 초기화 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록 초기화 실패')),
      );
    }
  }

  // ✅ 다이얼로그 추가
  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('기록 초기화', style: TextStyle(color: Colors.white)),
        content: const Text('모든 기록을 삭제하시겠습니까?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('아니요', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGhostRunData();
            },
            child: const Text('예', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 위젯 초기화 시 파이어베이스에서 데이터 가져오기
    if (widget.ghostRecord != null) {
      // GhostRunReadyPage에서 전달받은 레코드가 있으면 그걸 사용
      _updateUIFromRecord(widget.ghostRecord!);
      _hasRecord = true;
      // 모든 기록도 가져오기
      _loadAllUserRecords();
    } else {
      // 없으면 파이어베이스에서 새로 가져오기
      _loadUserRecord();
    }
  }

  // 레코드 데이터로 UI 업데이트하는 함수
  void _updateUIFromRecord(Map<String, dynamic> record) {
    setState(() {
      _latestRecord = record;
      _hasRecord = true;
      // 날짜 포맷팅
      if (record['date'] != null) {
        final Timestamp timestamp = record['date'] as Timestamp;
        final DateTime recordDate = timestamp.toDate();
        _currentDate = DateFormat('yy.MM.dd').format(recordDate);
      }
      // 거리
      if (record['distance'] != null) {
        _distance = (record['distance'] as num).toDouble();
        _distanceDisplay = _distance.toStringAsFixed(2);
      }
      // 페이스
      if (record['pace'] != null) {
        _pace = (record['pace'] as num).toDouble();
        _paceDisplay = "${_pace.toStringAsFixed(2)} km";
      }
      // 시간 (초 단위를 mm:ss 형식으로 변환)
      if (record['time'] != null) {
        final int timeInSeconds = (record['time'] as num).toInt();
        final int minutes = timeInSeconds ~/ 60;
        final int seconds = timeInSeconds % 60;
        _displayTime = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      }
      // 고스트 캐릭터 위치 설정 (파이어베이스에 저장된 경우)
      if (record['ghostBottomPosition'] != null) {
        _ghostBottomPosition = (record['ghostBottomPosition'] as num).toDouble();
      }
      if (record['ghostRightPosition'] != null) {
        _ghostRightPosition = (record['ghostRightPosition'] as num).toDouble();
      }
      // 레이스 결과 표시 (있는 경우)
      if (record['raceResult'] != null) {
        final String result = record['raceResult'] as String;
        if (result == 'win') {
          _raceResultText = " (승리)";
          _raceResultColor = Colors.green;
        } else if (result == 'lose') {
          _raceResultText = " (패배)";
          _raceResultColor = Colors.red;
        } else {
          _raceResultText = " (무승부)";
          _raceResultColor = Colors.orange;
        }
      }
      // 도전 메시지 (파이어베이스에 저장된 경우)
      if (record['challengeMessage'] != null) {
        _challengeMessage = record['challengeMessage'] as String;
      } else {
        // 기록은 있지만 메시지가 없는 경우 기본 메시지 설정
        _challengeMessage = "과거 나에게 도전이 있습니다!";
      }
    });
  }

  // 사용자의 가장 최근 레코드 가져오기
  Future<void> _loadUserRecord() async {
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
          _hasRecord = false;
        });
        return;
      }
      // 먼저 사용자 문서에서 최신 기록 ID 확인
      final userDoc = await _firestore
          .collection('ghostRunRecords')
          .doc(userEmail)
          .get();
      if (userDoc.exists && userDoc.data()!.containsKey('latestRecordId')) {
        // 최신 기록 ID가 있는 경우 해당 기록 가져오기
        String latestRecordId = userDoc.data()!['latestRecordId'];
        final recordDoc = await _firestore
            .collection('ghostRunRecords')
            .doc(userEmail)
            .collection('records')
            .doc(latestRecordId)
            .get();
        if (recordDoc.exists) {
          final data = recordDoc.data()!;
          // ID도 함께 저장 (고스트런 트래킹에서 사용하기 위함)
          data['id'] = recordDoc.id;
          _updateUIFromRecord(data);
          print('최신 기록을 성공적으로 불러왔습니다: $data');
          // 모든 기록도 가져오기
          _loadAllUserRecords();
          return;
        }
      }
      // 대체 방법: 가장 최근 날짜 기준으로 가져오기
      final recordsSnapshot = await _firestore
          .collection('ghostRunRecords')
          .doc(userEmail)
          .collection('records')
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      if (recordsSnapshot.docs.isNotEmpty) {
        // 최근 레코드 가져오기 성공
        final data = recordsSnapshot.docs.first.data();
        // docId도 함께 저장
        data['id'] = recordsSnapshot.docs.first.id;
        _updateUIFromRecord(data);
        print('최근 레코드를 성공적으로 불러왔습니다: $data');
        // 사용자 문서에 최신 기록 참조 업데이트
        await _firestore
            .collection('ghostRunRecords')
            .doc(userEmail)
            .set({
          'latestRecordId': recordsSnapshot.docs.first.id,
          'latestRecordDate': data['date'],
        }, SetOptions(merge: true));
        // 모든 기록도 가져오기
        _loadAllUserRecords();
      } else {
        print('사용자의 이전 레코드가 없습니다.');
        setState(() {
          _isLoading = false;
          _hasRecord = false;
        });
      }
    } catch (e) {
      print('레코드 로딩 중 오류 발생: $e');
      setState(() {
        _isLoading = false;
        _hasRecord = false;
      });
    }
  }

  // 사용자의 모든 레코드 가져오기
  Future<void> _loadAllUserRecords() async {
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
    // 기록이 없는 경우 팝업 표시하지 않음
    if (_allRecords.isEmpty) {
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) => GhostRunResultDialog(records: _allRecords),
    );
  }

  // 첫 런닝 트래킹 페이지로 이동
  void _navigateToFirstRunTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FirstGhostRunTrackingPage(),
      ),
    );
  }

  // 고스트런 트래킹 페이지로 이동
  void _navigateToGhostRunTracking() {
    if (_latestRecord != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GhostRunTrackingPage(
            ghostRunData: _latestRecord!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(5),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          '고스트런',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GhostRunRulePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
        children: [
          // 배경 트랙 이미지 - 하단에 위치 (가장 먼저 쌓는 요소)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/ghostrunconfirmation.png',
              fit: BoxFit.cover,
            ),
          ),
          // 고스트 캐릭터 (배경 위, 콘텐츠 아래에 배치)
          Positioned(
            bottom: 0,
            right: 20,
            child: Image.asset(
              'assets/images/ghostrunconfirmation2.png',
              width: 80,
              height: 80,
            ),
          ),
          // 메인 컨텐츠 (가장 마지막에 쌓이는 요소로 버튼이 캐릭터 위에 표시됨)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // 날짜 표시 (레이스 결과 포함)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '지난기록 $_currentDate$_raceResultText',
                    style: TextStyle(
                      color: _raceResultText.isEmpty ? Colors.grey[400] : _raceResultColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 타이머 디스플레이
                Container(
                  width: double.infinity,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'RUNNING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _displayTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 도전 메시지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _challengeMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // 속도 및 페이스 표시
                Row(
                  children: [
                    // 분/km 표시
                    Expanded(
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _distanceDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'distance',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 페이스 표시
                    Expanded(
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _paceDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Pace',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),  // 남은 공간을 채워서 버튼을 화면 하단에 배치
// 지난기록 더보기 + 새로 기록하기 버튼
// 지난기록 더보기 + 새로 기록하기 버튼
                Row(
                  children: [
                    // 지난기록 더보기 버튼 - 기록 있을 때만 활성화 및 팝업 표시
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _hasRecord ? _showRecordsDialog : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            disabledBackgroundColor: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            _hasRecord ? '지난기록 더보기' : '기록이 없습니다',
                            style: TextStyle(
                              color: _hasRecord ? Colors.white : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10), // 간격 추가
                    // 새로 기록하기 버튼 - 기록이 있을 때만 표시
                    if (_hasRecord)
                      Expanded( // ✅ 여기서 Expanded 추가
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _showResetConfirmDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '새로 기록하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // 도전하기 버튼 - 기록 유무에 따라 다른 페이지로 이동
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _hasRecord ? _navigateToGhostRunTracking : _navigateToFirstRunTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _hasRecord ? '도전하기' : '첫 도전 시작하기',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),  // 하단 여백 추가
              ],
            ),
          ),
        ],
      ),
    );
  }
}