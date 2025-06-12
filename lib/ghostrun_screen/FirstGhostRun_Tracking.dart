import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math' show cos, sqrt, asin;
import 'ghostrun_ready.dart';
import 'ghostrunpage.dart';

class FirstGhostRunTrackingPage extends StatefulWidget {
  const FirstGhostRunTrackingPage({Key? key}) : super(key: key);

  @override
  State<FirstGhostRunTrackingPage> createState() =>
      _FirstRunTrackingPageState();
}

class _FirstRunTrackingPageState extends State<FirstGhostRunTrackingPage> {
  // 구글 맵 컨트롤러
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final List<LatLng> _points = [];
  // 위치 관련 변수
  final Location _location = Location();
  LocationData? _currentLocation;
  // 트래킹 관련 변수
  bool _isTracking = false; // 변경됨: true → false
  bool _isPaused = false;
  Timer? _timer;
  int _elapsedSeconds = 0;
  // 자동 저장을 위한 타이머
  Timer? _autoSaveTimer;
  bool _autoSaved = false;
  // 러닝 데이터
  double _distanceKm = 0.0;
  double _paceMinPerKm = 0.0;
  // UI 표시용 변수
  String _timeDisplay = "00:00";
  String _distanceDisplay = "0.00km";
  String _paceDisplay = "0:00";
  // 파이어베이스 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 카운트다운 관련 변수
  String _countdownMessage = "";
  bool _showCountdown = false;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _startCountdown(); // 기존 _startTracking() 대신 실행
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // 위치 추적 초기화
  Future<void> _initLocationTracking() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // 위치 서비스 활성화 확인
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // 위치 권한 확인
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // 현재 위치 가져오기
    _currentLocation = await _location.getLocation();

    // 위치 변경 감지 리스너 설정
    _location.onLocationChanged.listen((LocationData newLocation) {
      if (!_isTracking || _isPaused) return;
      setState(() {
        _currentLocation = newLocation;
        final newPoint = LatLng(
            newLocation.latitude ?? 0.0,
            newLocation.longitude ?? 0.0);
        if (_points.isNotEmpty) {
          final prevPoint = _points.last;
          final distanceInMeters = _calculateDistance(
              prevPoint.latitude, prevPoint.longitude,
              newPoint.latitude, newPoint.longitude);
          _distanceKm += distanceInMeters / 1000;
          _distanceDisplay = "${_distanceKm.toStringAsFixed(2)}km";

          if (_distanceKm > 0) {
            _paceMinPerKm = _elapsedSeconds / 60 / _distanceKm;
            final paceMinutes = _paceMinPerKm.floor();
            final paceSeconds = ((_paceMinPerKm - paceMinutes) * 60).floor();
            _paceDisplay = "$paceMinutes:${paceSeconds.toString().padLeft(2, '0')}";
          }
        }
        _points.add(newPoint);
        _updatePolylines();
        _mapController?.animateCamera(CameraUpdate.newLatLng(newPoint));
      });
    });
  }

  // 카운트다운 시작
  void _startCountdown() {
    setState(() {
      _showCountdown = true;
      _countdownMessage = "준비하세요!";
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownMessage == "준비하세요!") {
        setState(() {
          _countdownMessage = "$_countdown";
        });
        _countdown--;
      } else if (_countdown > 0) {
        setState(() {
          _countdownMessage = "$_countdown";
        });
        _countdown--;
      } else {
        timer.cancel();
        setState(() {
          _countdownMessage = "출발!";
          _showCountdown = false;
          _isTracking = true;
          _isPaused = false;
        });
        _startTracking();
        _startAutoSaveTimer();

        // 1초 후 출발 메시지 숨김
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _countdownMessage = "";
            });
          }
        });
      }
    });
  }

  // 트래킹 시작
  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      setState(() {
        _elapsedSeconds++;
        final minutes = _elapsedSeconds ~/ 60;
        final seconds = _elapsedSeconds % 60;
        _timeDisplay = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      });
    });
  }

  // 30분 자동 저장 타이머 시작
  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer(const Duration(minutes: 30), () {
      if (_isTracking) {
        _saveRunRecord(isAutoSave: true).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('30분 경과! 기록이 자동 저장되었습니다.'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    });
  }

  // 트래킹 일시정지
  void _pauseTracking() {
    setState(() {
      _isPaused = true;
    });
  }

  // 트래킹 재개
  void _resumeTracking() {
    setState(() {
      _isPaused = false;
    });
  }

  // 중지 확인 다이얼로그 표시
  Future<bool> _showStopConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
        const Text("러닝 중지", style: TextStyle(color: Colors.white)),
        content: const Text("러닝을 중지하시겠습니까?",
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("아니오",
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text("예", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    ) ??
        false;
  }

  // 저장 여부 확인 다이얼로그 표시
  Future<bool> _showSaveConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            '기록 저장',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '현재 러닝 기록을 저장하시겠습니까?',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                '저장',
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ??
        false;
  }

  // 기록 저장 함수
  Future<void> _saveRunRecord({bool isAutoSave = false}) async {
    if (_autoSaved && isAutoSave) return;
    setState(() {
      if (isAutoSave) {
        _autoSaved = true;
      }
    });
    try {
      final String userEmail = _auth.currentUser?.email ?? '';
      if (userEmail.isEmpty) {
        print('로그인된 사용자가 없습니다.');
        return;
      }
      final now = DateTime.now();
      List<Map<String, double>> locationPoints = [];
      for (var point in _points) {
        locationPoints.add({
          'latitude': point.latitude,
          'longitude': point.longitude,
        });
      }
      final record = {
        'date': Timestamp.fromDate(now),
        'time': _elapsedSeconds,
        'distance': _distanceKm,
        'pace': _paceMinPerKm,
        'isFirstRecord': true,
        'locationPoints': locationPoints,
        'autoSaved': isAutoSave,
      };
      await _firestore
          .collection('ghostRunRecords')
          .doc(userEmail)
          .collection('records')
          .add(record);
      print('기록이 성공적으로 저장되었습니다. 자동 저장: $isAutoSave');
    } catch (e) {
      print('기록 저장 중 오류 발생: $e');
    }
  }

  // 트래킹 종료 및 기록 저장
  Future<void> _finishTracking({bool save = true}) async {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    setState(() {
      _isTracking = false;
    });
    if (save) {
      await _saveRunRecord();
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const GhostRunPage(),
        ),
      );
    }
  }

  // 폴리라인 업데이트
  void _updatePolylines() {
    if (_points.length < 2) return;
    final polyline = Polyline(
      polylineId: const PolylineId('run_track'),
      points: _points,
      color: Colors.blue,
      width: 5,
    );
    setState(() {
      _polylines.clear();
      _polylines.add(polyline);
    });
  }

  // 두 지점 간의 거리 계산 (Haversine 공식)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const earthRadiusKm = 6371.0;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) *
            cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) /
            2;
    return 2 * earthRadiusKm * asin(sqrt(a)) * 1000;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool stop = await _showStopConfirmDialog();
        if (stop) {
          await _finishTracking(save: false); // 저장 없이 이전 페이지로 이동
        }
        return stop;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 지도 표시
            _currentLocation != null && !_showCountdown
                ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentLocation!.latitude ?? 37.5665,
                  _currentLocation!.longitude ?? 126.9780,
                ),
                zoom: 16.0,
              ),
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              polylines: _polylines,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                controller.setMapStyle('''
                          [
                            {
                              "elementType": "geometry",
                              "stylers": [
                                { "color": "#212121" }
                              ]
                            },
                            {
                              "elementType": "labels.text.fill",
                              "stylers": [
                                { "color": "#757575" }
                              ]
                            },
                            {
                              "elementType": "labels.text.stroke",
                              "stylers": [
                                { "color": "#212121" }
                              ]
                            },
                            {
                              "featureType": "road",
                              "elementType": "geometry.fill",
                              "stylers": [
                                { "color": "#2c2c2c" }
                              ]
                            },
                            {
                              "featureType": "road",
                              "elementType": "geometry.stroke",
                              "stylers": [
                                { "color": "#000000" }
                              ]
                            },
                            {
                              "featureType": "water",
                              "elementType": "geometry",
                              "stylers": [
                                { "color": "#000000" }
                              ]
                            }
                          ]
                        ''');
              },
            )
                : const Center(child: CircularProgressIndicator()),

            // 카운트다운 화면
            if (_showCountdown || _countdownMessage.isNotEmpty)
              Container(
                color: Colors.black.withOpacity(0.8),
                alignment: Alignment.center,
                child: Text(
                  _countdownMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // 나머지 UI는 생략... (기존 코드 유지)
            Positioned(
              top: 40,
              left: 10,
              child: GestureDetector(
                onTap: () async {
                  bool stop = await _showStopConfirmDialog();
                  if (stop) {
                    await _finishTracking(save: false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '고스트런',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 100,
              right: 10,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _autoSaved ? '자동 저장됨' : '30분 후 자동 저장',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 160,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        '첫 기록을 재보아요!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          "Me",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.black,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _timeDisplay,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Time",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.black,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _distanceDisplay,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Pace",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.black,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _paceDisplay,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "min/km",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 70,
              right: 20,
              child: _isPaused
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _resumeTracking,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin:
                      const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      bool save = await _showSaveConfirmDialog();
                      if (save) {
                        await _finishTracking(save: true);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin:
                      const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              )
                  : GestureDetector(
                onTap: _pauseTracking,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange,
                  ),
                  child: const Icon(
                    Icons.pause,
                    color: Colors.white,
                    size: 32,
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