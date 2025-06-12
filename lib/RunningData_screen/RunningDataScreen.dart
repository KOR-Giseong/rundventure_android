import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:work/free_running/free_running.dart';
import 'CustomCalendar_Dialog.dart';
import 'package:work/main_screens/main_screen.dart';
import 'RunningRecords_Page.dart';
import 'Running_Goal_Setting.dart';
import 'dart:math' as math;

class RunningStatsPage extends StatefulWidget {
  final String date;

  RunningStatsPage({Key? key, required this.date}) : super(key: key);

  @override
  State<RunningStatsPage> createState() => _RunningStatsPageState();
}

class _RunningStatsPageState extends State<RunningStatsPage> {
  late DateTime _selectedDate;
  bool _showCalendar = false;
  bool _isCaloriesSelected = true;
  Map<String, Map<String, dynamic>?> weeklyData = {};
  Map<String, dynamic>? _selectedRecord;
  int calorieGoal = 500; // 기본값이지만 initState에서 실제 값으로 업데이트됨
  double distanceGoal = 10.0; // 기본값이지만 initState에서 실제 값으로 업데이트됨
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoadingGoal = true; // 목표 불러오는 중 상태 추가

  @override
  void initState() {
    super.initState();
    _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.date);
    _loadGoalForDate(_selectedDate).then((_) {
      _loadWeeklyData();
    });
  }

  Future<void> _loadGoalForDate(DateTime date) async {
    setState(() {
      _isLoadingGoal = true;
    });

    String userEmail = FirebaseAuth.instance.currentUser!.email!;
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    try {
      // 1. 첫 번째로 collection('goals')에서 확인
      DocumentSnapshot goalSnapshot = await FirebaseFirestore.instance
          .collection('userRunningData')
          .doc(userEmail)
          .collection('goals')
          .doc(formattedDate)
          .get();

      if (goalSnapshot.exists) {
        Map<String, dynamic> data = goalSnapshot.data() as Map<String, dynamic>;
        setState(() {
          calorieGoal = data['calorieGoal'] ?? 500;
          distanceGoal = (data['distanceGoal'] ?? 10.0).toDouble();
          _isLoadingGoal = false;
        });
        return; // 데이터를 찾았으므로 여기서 종료
      }

      // 2. 두 번째로 userRunningGoals에서 확인
      DocumentSnapshot oldGoalSnapshot = await FirebaseFirestore.instance
          .collection('userRunningGoals')
          .doc(userEmail)
          .collection('dailyGoals')
          .doc(formattedDate)
          .get();

      if (oldGoalSnapshot.exists) {
        Map<String, dynamic> data = oldGoalSnapshot.data() as Map<String, dynamic>;
        setState(() {
          calorieGoal = data['calorieGoal'] ?? 500;
          distanceGoal = (data['distanceGoal'] ?? 10.0).toDouble();
          _isLoadingGoal = false;
        });

        // 발견된 데이터를 다른 경로에도 저장해서 동기화
        await _syncGoalToAllPaths(calorieGoal, distanceGoal, formattedDate);
        return; // 데이터를 찾았으므로 여기서 종료
      }

      // 3. 세 번째로 userRunningData의 goals 필드에서 확인
      DocumentSnapshot userDataSnapshot = await FirebaseFirestore.instance
          .collection('userRunningData')
          .doc(userEmail)
          .get();

      if (userDataSnapshot.exists) {
        Map<String, dynamic>? userData = userDataSnapshot.data() as Map<String, dynamic>?;
        if (userData != null && userData.containsKey('goals')) {
          Map<String, dynamic> goals = userData['goals'] as Map<String, dynamic>;
          setState(() {
            calorieGoal = goals['calorieGoal'] ?? 500;
            distanceGoal = (goals['distanceGoal'] ?? 10.0).toDouble();
            _isLoadingGoal = false;
          });

          // 발견된 데이터를 다른 경로에도 저장해서 동기화
          await _syncGoalToAllPaths(calorieGoal, distanceGoal, formattedDate);
          return;
        }
      }

      // 4. 어디에도 없으면 기본값 사용
      setState(() {
        calorieGoal = 500;
        distanceGoal = 10.0;
        _isLoadingGoal = false;
      });

    } catch (e) {
      print("Error loading goal: $e");
      setState(() {
        calorieGoal = 500;
        distanceGoal = 10.0;
        _isLoadingGoal = false;
      });
    }
  }

  // 모든 경로에 목표 데이터 동기화하는 메서드
  Future<void> _syncGoalToAllPaths(int calories, double distance, String dateKey) async {
    try {
      String userEmail = FirebaseAuth.instance.currentUser!.email!;

      // 1. userRunningData의 goals 컬렉션에 저장
      await FirebaseFirestore.instance
          .collection('userRunningData')
          .doc(userEmail)
          .collection('goals')
          .doc(dateKey)
          .set({
        'calorieGoal': calories,
        'distanceGoal': distance,
        'goalType': distance >= calories ? 'distance' : 'calorie',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. userRunningGoals 컬렉션에도 저장
      await FirebaseFirestore.instance
          .collection('userRunningGoals')
          .doc(userEmail)
          .collection('dailyGoals')
          .doc(dateKey)
          .set({
        'calorieGoal': calories,
        'distanceGoal': distance,
        'goalType': distance >= calories ? 'distance' : 'calorie',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. userRunningData 문서의 goals 필드에도 저장
      await FirebaseFirestore.instance
          .collection('userRunningData')
          .doc(userEmail)
          .set({
        'goals': {
          'calorieGoal': calories,
          'distanceGoal': distance,
          'goalType': distance >= calories ? 'distance' : 'calorie',
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true)); // merge 옵션으로 다른 필드 유지

    } catch (e) {
      print("Error syncing goals: $e");
    }
  }

  Future<Map<String, dynamic>?> _fetchRunningData(String date) async {
    try {
      String userEmail = FirebaseAuth.instance.currentUser!.email!;
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('userRunningData')
          .doc(userEmail)
          .collection('workouts')
          .doc(date)
          .get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error fetching data: $e");
      return null;
    }
  }

  // 해당 주의 월요일을 구하는 메서드
  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // 주간 데이터를 로드하는 메서드
  Future<void> _loadWeeklyData() async {
    DateTime startOfWeek = _getStartOfWeek(_selectedDate);
    String userEmail = FirebaseAuth.instance.currentUser!.email!;

    weeklyData.clear(); // 기존 데이터 초기화

    for (int i = 0; i < 7; i++) {
      DateTime currentDate = startOfWeek.add(Duration(days: i));
      String formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);

      // 운동 데이터
      Map<String, dynamic>? workoutData = await _fetchRunningData(formattedDate);

      // 목표 데이터 - 여러 경로 중 첫 번째로 확인
      DocumentSnapshot goalSnapshot = await FirebaseFirestore.instance
          .collection('userRunningData')
          .doc(userEmail)
          .collection('goals')
          .doc(formattedDate)
          .get();

      // 첫 번째 경로에 없으면 두 번째 경로에서 확인
      if (!goalSnapshot.exists) {
        goalSnapshot = await FirebaseFirestore.instance
            .collection('userRunningGoals')
            .doc(userEmail)
            .collection('dailyGoals')
            .doc(formattedDate)
            .get();
      }

      Map<String, dynamic>? goalData =
      goalSnapshot.exists ? goalSnapshot.data() as Map<String, dynamic> : null;

      // 저장 (두 개 합쳐서)
      weeklyData[formattedDate] = {
        'data': workoutData,
        'goal': goalData,
      };
    }

    setState(() {});
  }

  // Timestamp를 DateTime으로 안전하게 변환하는 메서드
  DateTime _getDateTime(Map<String, dynamic> runningData) {
    final dateData = runningData['date'];
    if (dateData is Timestamp) {
      return dateData.toDate();
    } else if (dateData is DateTime) {
      return dateData;
    }
    return DateTime.now();
  }

  // 달력 위젯
  Widget _buildCalendarDialog() {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.now(),
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _showCalendar = false;
                });
                Navigator.of(context).pop();
                _loadGoalForDate(_selectedDate).then((_) => _loadWeeklyData());
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDay(String day, bool isComplete, {bool isActive = false}) {
    int dayIndex = ['월', '화', '수', '목', '금', '토', '일'].indexOf(day);
    DateTime dayDate = _getStartOfWeek(_selectedDate).add(Duration(days: dayIndex));
    String formattedDayDate = DateFormat('yyyy-MM-dd').format(dayDate);

    final dayInfo = weeklyData[formattedDayDate];
    final dayData = dayInfo?['data'];
    final goalData = dayInfo?['goal'];
    bool hasData = dayData != null;

    // 선택된 모드에 따라 값 꺼내기
    double value = 0.0;
    double goal = 1.0; // 기본값 (0으로 나눔 방지용)
    if (hasData) {
      if (_isCaloriesSelected) {
        value = (dayData['calories'] ?? 0).toDouble();
        goal = (goalData?['calorieGoal'] ?? calorieGoal).toDouble();
      } else {
        value = (dayData['kilometers'] ?? 0).toDouble();
        goal = (goalData?['distanceGoal'] ?? distanceGoal).toDouble();
      }
    }

    double progress = (goal > 0) ? (value / goal).clamp(0.0, 1.0) : 0.0;
    final double deviceWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedDate = dayDate;
        });
        await _loadGoalForDate(dayDate);
        await _loadWeeklyData();
      },
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              color: hasData ? Colors.deepOrange : Colors.grey,
              fontSize: deviceWidth * 0.04,
            ),
          ),
          SizedBox(height: deviceWidth * 0.02),
          Stack(
            alignment: Alignment.center,
            children: [
              if (hasData)
                SizedBox(
                  width: deviceWidth * 0.08,
                  height: deviceWidth * 0.08,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                    strokeCap: StrokeCap.round,
                  ),
                ),
              Center(
                child: Container(
                  width: deviceWidth * 0.07,
                  height: deviceWidth * 0.08,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSameDay(dayDate, _selectedDate)
                        ? Colors.deepOrange.withOpacity(0.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: hasData ? Colors.deepOrange : Colors.grey[300]!,
                      width: hasData ? 2 : 1,
                    ),
                  ),
                  child: hasData
                      ? Center(
                    child: Text(
                      _isCaloriesSelected
                          ? '${value.round()}'
                          : value.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: deviceWidth * 0.022,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final double deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoadingGoal
            ? Center(child: CircularProgressIndicator()) // 목표 로딩 중일 때 로딩 표시
            : FutureBuilder<Map<String, dynamic>?>(
          future: _fetchRunningData(formattedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('데이터를 불러오는 데 오류가 발생했습니다.'));
            } else {
              // 데이터가 없을 때 기본값 0으로 처리
              final selectedData = _selectedRecord ?? snapshot.data ?? {
                'calories': 0,
                'pace': 0.0,
                'seconds': 0,
                'elevation': 0,
                'averageSpeed': 0.0,
                'kilometers': 0.0,
                'stepCount': 0,
              };

              // 목표 달성 진행률 계산
              final double progressValue = _isCaloriesSelected
                  ? (selectedData['calories'] as num).toDouble() / calorieGoal
                  : (selectedData['kilometers'] as num).toDouble() / distanceGoal;

              return ListView(
                physics: ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 20.0),
                children: [
                  // 상단 헤더
                  Padding(
                    padding: const EdgeInsets.all(8.0), // 패딩 축소
                    child: Row(
                      children: [
                        IconButton(
                          icon: Image.asset('assets/images/Back-Navs.png'),
                          iconSize: 20, // 아이콘 크기 축소
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => MainScreen()),
                            );
                          },
                        ),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR').format(_selectedDate),
                              style: TextStyle(
                                fontSize: deviceWidth * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.calendar_today, size: 20), // 아이콘 크기 축소
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => CustomCalendarDialog(
                                selectedDate: _selectedDate,
                                onDateSelected: (DateTime date) {
                                  setState(() {
                                    _selectedDate = date;
                                  });
                                  _loadGoalForDate(date).then((_) => _loadWeeklyData());
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 요일별 데이터
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildWeekDay('월', false),
                        _buildWeekDay('화', false),
                        _buildWeekDay('수', false),
                        _buildWeekDay('목', false),
                        _buildWeekDay('금', false),
                        _buildWeekDay('토', false),
                        _buildWeekDay('일', false),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // 3D 링 효과
                  Center(
                    child: SizedBox(
                      width: math.min(deviceWidth * 0.6, 230), // 화면 크기에 따라 크기 제한
                      height: math.min(deviceWidth * 0.6, 230),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 커스텀 링
                          Transform(
                            transform: Matrix4.rotationX(0.2),
                            alignment: Alignment.center,
                            child: CustomPaint(
                              painter: ThreeDProgressPainter(
                                progress: progressValue.clamp(0.0, 1.5),
                              ),
                              size: Size(deviceWidth * 0.6, deviceWidth * 0.6),
                            ),
                          ),

                          // 버튼 중앙 배치
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GoalSettingPage(
                                        initialCalorieGoal: calorieGoal,
                                        initialDistanceGoal: distanceGoal,
                                        selectedDate: _selectedDate,
                                      ),
                                    ),
                                  );

                                  if (result is Map<String, dynamic>) {
                                    setState(() {
                                      calorieGoal = result['calorieGoal'];
                                      distanceGoal = result['distanceGoal'];
                                    });

                                    // 모든 경로에 목표 데이터 동기화
                                    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
                                    await _syncGoalToAllPaths(calorieGoal, distanceGoal, formattedDate);

                                    // UI 업데이트
                                    await _loadWeeklyData();
                                  }
                                },
                                icon: Icon(Icons.flag, color: Colors.deepOrange, size: 16),
                                label: Text(
                                  '목표 설정',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.deepOrange,
                                  backgroundColor: Colors.deepOrange.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // 칼로리/거리 선택 버튼
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: deviceWidth * 0.05,
                      vertical: 10.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isCaloriesSelected = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCaloriesSelected ? Colors.deepOrange : Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              '칼로리',
                              style: TextStyle(
                                color: _isCaloriesSelected ? Colors.white : Colors.black,
                                fontSize: deviceWidth * 0.035,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isCaloriesSelected = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_isCaloriesSelected ? Colors.deepOrange : Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              '거리',
                              style: TextStyle(
                                color: !_isCaloriesSelected ? Colors.white : Colors.black,
                                fontSize: deviceWidth * 0.035,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 칼로리/거리 텍스트
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 목표 칼로리 & 기록 보기 버튼
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 목표 정보
                            Flexible(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isCaloriesSelected ? '목표 칼로리' : '목표 거리',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: deviceWidth * 0.038,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: _isCaloriesSelected
                                                ? '${(selectedData['calories'] as num).round()}'
                                                : '${(selectedData['kilometers'] as num).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 40,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          TextSpan(
                                            text: _isCaloriesSelected
                                                ? '/$calorieGoal'
                                                : '/${distanceGoal.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: _isCaloriesSelected ? ' KCAL' : ' KM',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 기록 보기 버튼
                            Flexible(
                              flex: 1,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final selectedRecord = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RunningRecordsPage(date: formattedDate),
                                    ),
                                  );

                                  if (selectedRecord is Map<String, dynamic>) {
                                    setState(() {
                                      _selectedRecord = selectedRecord;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: deviceWidth * 0.02,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '기록 보기',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: deviceWidth * 0.035,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 15),

                        // 기록 상세 정보 (반응형으로 수정)
                        _buildResponsiveDetailRow(
                          context,
                          '평균 페이스',
                          '${_formatPace((selectedData['pace'] as num).toDouble())}/KM',
                          '시간',
                          _formatDuration((selectedData['seconds'] as num).toInt()),
                          _isCaloriesSelected ? '거리' : '칼로리',
                          _isCaloriesSelected
                              ? '${(selectedData['kilometers'] as num).toStringAsFixed(2)}km'
                              : '${(selectedData['calories'] as num).round()}KCAL',
                        ),

                        SizedBox(height: 15),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              _buildResponsiveDetailItem(context, '고도', '${(selectedData['elevation'] as num?)?.toDouble().toStringAsFixed(1) ?? "0.0"} m'),
                              SizedBox(width: deviceWidth * 0.15),
                              _buildResponsiveDetailItem(context, '걸음수', '${(selectedData['stepCount'] as num?)?.toInt() ?? 0}'),
                              SizedBox(width: deviceWidth * 0.15),
                              _buildResponsiveDetailItem(context, '평균 속도', '${(selectedData['averageSpeed'] as num).toStringAsFixed(1)}km/h'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  // 반응형 세부 정보 행 (화면 크기에 맞게 조정)
  Widget _buildResponsiveDetailRow(
      BuildContext context,
      String label1, String value1,
      String label2, String value2,
      String label3, String value3,
      ) {
    final double deviceWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildResponsiveDetailItem(context, label1, value1)),
        Expanded(child: _buildResponsiveDetailItem(context, label2, value2)),
        Expanded(child: _buildResponsiveDetailItem(context, label3, value3)),
      ],
    );
  }

  // 반응형 세부 정보 아이템 (화면 크기에 맞게 조정)
  Widget _buildResponsiveDetailItem(BuildContext context, String label, String value) {
    final double deviceWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: deviceWidth * 0.033,
          ),
        ),
        SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: deviceWidth * 0.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class ThreeDProgressPainter extends CustomPainter {
  final double progress;

  ThreeDProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final double startAngle = -math.pi / 2;
    // 스트로크 너비를 화면 크기에 비례하게 조정
    final double strokeWidth = size.width * 0.15;

    // 배경 링
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, 0, 2 * math.pi, false, backgroundPaint);

    // 달성 전에는 deepOrange, 달성 후에는 green
    final bool isGoalReached = progress >= 1.0;

    final Paint basePaint = Paint()
      ..color = isGoalReached ? Colors.deepOrange[600]! : Colors.deepOrange
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double primaryProgress = math.min(progress, 1.0);
    final double primarySweep = primaryProgress * 2 * math.pi;

    if (primarySweep > 0) {
      canvas.drawArc(rect, startAngle, primarySweep, false, basePaint);
    }

    // 초과 부분
    if (progress > 1.0) {
      final double extraProgress = progress - 1.0;
      final double extraSweep = extraProgress * 2 * math.pi;

      // gradient로 부드럽게 연결
      final Paint gradientPaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: extraSweep,
          colors: [
            Colors.deepOrange[600]!,
            Colors.deepOrange[700]!,
            Colors.deepOrange[800]!,
          ],
          stops: [0.0, 0.5, 1.0],
          transform: GradientRotation(startAngle + primarySweep),
        ).createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle + primarySweep, extraSweep, false, gradientPaint);

      // 끝부분 둥글게
      final Paint endCapPaint = Paint()
        ..color = Colors.deepOrange[800]!
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle + primarySweep + extraSweep - 0.001, 0.001, false, endCapPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

String _formatPace(double pace) {
  int minutes = pace.floor();
  int seconds = ((pace - minutes) * 60).round();
  return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
}

String _formatDuration(int seconds) {
  int minutes = seconds ~/ 60;
  int remainingSeconds = seconds % 60;
  return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
}