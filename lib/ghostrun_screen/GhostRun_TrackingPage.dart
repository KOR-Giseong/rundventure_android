import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math' show cos, sqrt, asin, min;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'GhostRun_Resultpage.dart';
import 'ghostrun_ready.dart';
import 'ghostrunpage.dart';

class GhostRunTrackingPage extends StatefulWidget {
  final Map<String, dynamic> ghostRunData;
  const GhostRunTrackingPage({
    Key? key,
    required this.ghostRunData,
  }) : super(key: key);

  @override
  State<GhostRunTrackingPage> createState() => _GhostRunTrackingPageState();
}

class _GhostRunTrackingPageState extends State<GhostRunTrackingPage> {
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final List<LatLng> _points = [];

  // 고스트 관련 변수
  List<Map<String, double>> _ghostPoints = [];
  double _ghostDistanceKm = 0.0;
  String _ghostTimeDisplay = "00:00";
  String _ghostDistanceDisplay = "0.00km";
  String _ghostPaceDisplay = "0:00";
  int _ghostElapsedSeconds = 0;
  double _ghostPaceMinPerKm = 0.0;
  int _ghostIndex = 0;
  BitmapDescriptor? _ghostIcon;

  // 위치 관련 변수
  final Location _location = Location();
  LocationData? _currentLocation;

  // 트래킹 관련 변수
  bool _isTracking = false;
  bool _isPaused = false;
  Timer? _timer;
  Timer? _ghostTimer;
  Timer? _autoSaveTimer;
  int _elapsedSeconds = 0;
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

  // 경쟁 상태 변수
  String _raceStatus = "";
  double _leadDistance = 0.0;

  // 레이스 결과 변수
  String _raceResult = ""; // 'win', 'lose', 'tie'

  // 🔁 스크롤 고정 모드 추가
  bool _followUserLocation = true; // 기본값: 사용자 위치 추적 활성화
  late StreamSubscription<LocationData> _locationSubscription;

  // 카운트다운 관련 변수 추가
  String _countdownMessage = "";
  bool _showCountdown = false;
  int _countdown = 3;

  // ⏱️ 고스트 제한 시간 타이머 추가
  Timer? _ghostTimeLimitTimer;

  @override
  void initState() {
    super.initState();
    _loadGhostIcon(); // 고스트 아이콘 로드
    _loadGhostData();
    _initLocationTracking();

    // 트래킹 시작 전 카운트다운 실행
    _startCountdown();
    _startAutoSaveTimer();

    // 위치 변경 리스너 설정
    _locationSubscription = _location.onLocationChanged.listen((LocationData newLocation) {
      if (!_isTracking || _isPaused) return;

      setState(() {
        _currentLocation = newLocation;

        // 🔁 사용자 위치 추적 모드일 때만 지도 자동 이동
        if (_followUserLocation) {
          final newPoint = LatLng(newLocation.latitude ?? 0.0, newLocation.longitude ?? 0.0);
          _mapController?.animateCamera(CameraUpdate.newLatLng(newPoint));
        }

        final newPoint = LatLng(
            newLocation.latitude ?? 0.0,
            newLocation.longitude ?? 0.0
        );

        if (_points.isNotEmpty) {
          final prevPoint = _points.last;
          final distanceInMeters = _calculateDistance(
              prevPoint.latitude, prevPoint.longitude,
              newPoint.latitude, newPoint.longitude
          );
          _distanceKm += distanceInMeters / 1000;
          _distanceDisplay = "${_distanceKm.toStringAsFixed(2)}km";

          if (_distanceKm > 0) {
            _paceMinPerKm = _elapsedSeconds / 60 / _distanceKm;
            final paceMinutes = (_paceMinPerKm).floor();
            final paceSeconds = ((_paceMinPerKm - paceMinutes) * 60).floor();
            _paceDisplay = "$paceMinutes:${paceSeconds.toString().padLeft(2, '0')}";
            _compareWithGhost();
          }
        }

        _points.add(newPoint);
        _updatePolylines();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ghostTimer?.cancel();
    _autoSaveTimer?.cancel();
    _ghostTimeLimitTimer?.cancel();
    _mapController?.dispose();
    _locationSubscription.cancel();
    super.dispose();
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
        _startGhostRun();

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _countdownMessage = "";
            });
          }
        });

// ⏱️ 고스트 기록 시간 만큼만 트래킹 가능하도록 타이머 설정
        int ghostTotalTime = widget.ghostRunData['time'] ?? 0;
        if (ghostTotalTime > 0) {
          int alreadyElapsed = _elapsedSeconds;

          // ⏳ 남은 시간 계산
          int remainingTime = ghostTotalTime - alreadyElapsed;

          // 🚨 10초 전 알림 타이머
          if (remainingTime > 10) {
            Timer(Duration(seconds: remainingTime - 10), () {
              if (_isTracking && !_isPaused) {
                setState(() {
                  _raceStatus = "곧 경기가 종료됩니다!";
                });
              }
            });
          }

          // ⏱️ 정확히 고스트 시간 만큼 진행 후 페이스 비교로 종료
          _ghostTimeLimitTimer = Timer(Duration(seconds: remainingTime), () {
            if (_isTracking && !_isPaused) {
              _finishRaceBasedOnPace();
            }
          });
        }
      }
    });
  }

  // 🏁 고스트 시간이 끝났을 때 페이스 기준으로 결과 계산 후 종료
  void _finishRaceBasedOnPace() async {
    if (!_isTracking) return;

    setState(() {
      _isTracking = false;
      _isPaused = true;
    });

    _timer?.cancel();
    _ghostTimer?.cancel();
    _autoSaveTimer?.cancel();
    _ghostTimeLimitTimer?.cancel();

    // 페이스 비교
    String finalRaceResult;
    if (_paceMinPerKm < _ghostPaceMinPerKm) {
      finalRaceResult = 'win'; // 페이스 더 빠름
    } else if (_paceMinPerKm > _ghostPaceMinPerKm) {
      finalRaceResult = 'lose'; // 페이스 느림
    } else {
      finalRaceResult = 'tie'; // 같은 페이스
    }

    final isWin = finalRaceResult == 'win';

    final Map<String, dynamic> userResult = {
      'time': _elapsedSeconds,
      'distance': _distanceKm,
      'pace': _paceMinPerKm,
    };

    final Map<String, dynamic> ghostResult = {
      'time': widget.ghostRunData['time'] ?? 0,
      'distance': widget.ghostRunData['distance'] ?? 0.0,
      'pace': widget.ghostRunData['pace'] ?? 0.0,
    };

    await _saveRunRecord(raceResult: finalRaceResult);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GhostRunResultScreen(
            userResult: userResult,
            ghostResult: ghostResult,
            isWin: isWin,
          ),
        ),
      );
    }
  }

  // 고스트 아이콘 로드
  Future<void> _loadGhostIcon() async {
    try {
      final Uint8List markerIcon = await getBytesFromAsset('assets/images/ghostlogo.png', 80);
      _ghostIcon = BitmapDescriptor.fromBytes(markerIcon);
    } catch (e) {
      print('고스트 아이콘 로드 실패: $e');
      _ghostIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  // 이미지 에셋을 바이트로 변환
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  // 고스트 런 데이터 로드
  void _loadGhostData() {
    List<dynamic> points = widget.ghostRunData['locationPoints'] ?? [];
    _ghostPoints = points.map((point) => {
      'latitude': point['latitude'] as double,
      'longitude': point['longitude'] as double,
    }).toList();

    _ghostDistanceKm = widget.ghostRunData['distance'] ?? 0.0;
    _ghostPaceMinPerKm = widget.ghostRunData['pace'] ?? 0.0;

    int totalSeconds = widget.ghostRunData['time'] ?? 0;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    _ghostTimeDisplay = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    _ghostDistanceDisplay = "${_ghostDistanceKm.toStringAsFixed(2)}km";

    final paceMinutes = _ghostPaceMinPerKm.floor();
    final paceSeconds = ((_ghostPaceMinPerKm - paceMinutes) * 60).floor();
    _ghostPaceDisplay = "$paceMinutes:${paceSeconds.toString().padLeft(2, '0')}";
  }

  // 고스트 런 시작
  void _startGhostRun() {
    if (_ghostPoints.isEmpty) return;

    if (_ghostPoints.isNotEmpty) {
      _updateGhostMarker(LatLng(
        _ghostPoints[0]['latitude']!,
        _ghostPoints[0]['longitude']!,
      ));
    }

    _ghostTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        _ghostElapsedSeconds++;

        if (_ghostIndex < _ghostPoints.length - 1) {
          double totalGhostDistance = _ghostDistanceKm;
          int totalGhostTime = widget.ghostRunData['time'] ?? 1;
          double progressRatio = _ghostElapsedSeconds / totalGhostTime;
          double expectedDistance = totalGhostDistance * progressRatio;
          double calculatedDistance = 0.0;
          int newGhostIndex = 0;

          for (int i = 0; i < _ghostPoints.length - 1; i++) {
            double segmentDistance = _calculateDistance(
                _ghostPoints[i]['latitude']!,
                _ghostPoints[i]['longitude']!,
                _ghostPoints[i + 1]['latitude']!,
                _ghostPoints[i + 1]['longitude']!
            ) / 1000;

            if (calculatedDistance + segmentDistance > expectedDistance) {
              double segmentProgress = (expectedDistance - calculatedDistance) / segmentDistance;
              double lat = _ghostPoints[i]['latitude']! +
                  segmentProgress * (_ghostPoints[i + 1]['latitude']! - _ghostPoints[i]['latitude']!);
              double lng = _ghostPoints[i]['longitude']! +
                  segmentProgress * (_ghostPoints[i + 1]['longitude']! - _ghostPoints[i]['longitude']!);

              _updateGhostMarker(LatLng(lat, lng));
              newGhostIndex = i;
              break;
            }

            calculatedDistance += segmentDistance;
            newGhostIndex = i + 1;
          }

          if (newGhostIndex != _ghostIndex || _ghostIndex == 0) {
            _ghostIndex = newGhostIndex;
            _updateGhostPolylines();
            _compareWithGhost();
          }
        }
      });
    });
  }

  // 고스트 마커 업데이트
  void _updateGhostMarker(LatLng position) {
    final marker = Marker(
      markerId: const MarkerId('ghost_marker'),
      position: position,
      icon: _ghostIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      zIndex: 2,
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'ghost_marker');
      _markers.add(marker);
    });
  }

  // 고스트 폴리라인 업데이트
  void _updateGhostPolylines() {
    if (_ghostPoints.isEmpty || _ghostIndex >= _ghostPoints.length) return;

    List<LatLng> ghostPathPoints = [];
    for (int i = 0; i <= _ghostIndex; i++) {
      ghostPathPoints.add(LatLng(
        _ghostPoints[i]['latitude']!,
        _ghostPoints[i]['longitude']!,
      ));
    }

    final ghostPolyline = Polyline(
      polylineId: const PolylineId('ghost_track'),
      points: ghostPathPoints,
      color: Colors.purple,
      width: 5,
      patterns: [PatternItem.dash(10), PatternItem.gap(10)],
    );

    setState(() {
      _polylines.removeWhere((polyline) => polyline.polylineId.value == 'ghost_track');
      _polylines.add(ghostPolyline);
    });
  }

  // 고스트와 비교
  void _compareWithGhost() {
    if (_points.isEmpty || _ghostIndex >= _ghostPoints.length) return;

    LatLng myPosition = _points.last;
    LatLng ghostPosition = LatLng(
      _ghostPoints[_ghostIndex]['latitude']!,
      _ghostPoints[_ghostIndex]['longitude']!,
    );

    double distanceBetween = _calculateDistance(
        myPosition.latitude,
        myPosition.longitude,
        ghostPosition.latitude,
        ghostPosition.longitude
    );

    double ghostProgress = _ghostElapsedSeconds / (widget.ghostRunData['time'] ?? 1);
    ghostProgress = ghostProgress.clamp(0.0, 1.0);
    double expectedGhostDistance = _ghostDistanceKm * ghostProgress;

    if (_distanceKm > expectedGhostDistance) {
      _leadDistance = (_distanceKm - expectedGhostDistance) * 1000;
      _raceStatus = "고스트보다 ${_leadDistance.toStringAsFixed(1)}m 앞서고 있습니다";
      _raceResult = _distanceKm > _ghostDistanceKm ? 'win' : 'ahead';
    } else {
      _leadDistance = (expectedGhostDistance - _distanceKm) * 1000;
      _raceStatus = "고스트가 ${_leadDistance.toStringAsFixed(1)}m 앞서고 있습니다";
      _raceResult = 'lose';
    }
  }

  // 위치 추적 초기화
  Future<void> _initLocationTracking() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // 위치 서비스 활성화 확인
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    // 위치 권한 확인
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    // 현재 위치 가져오기
    _currentLocation = await _location.getLocation();
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
        String finalRaceResult =
        _distanceKm > _ghostDistanceKm ? 'win' : (_distanceKm < _ghostDistanceKm ? 'lose' : 'tie');

        bool isWin = finalRaceResult == 'win';
        _saveRunRecord(isAutoSave: true, raceResult: finalRaceResult).then((_) {
          bool willUpdateLatest = finalRaceResult == 'win' || finalRaceResult == 'lose';

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '30분 경과! 기록이 자동 저장되었습니다.' +
                        (willUpdateLatest ? ' 이 기록이 최신 기록으로 갱신되었습니다.' : '')
                ),
                duration: const Duration(seconds: 3),
                backgroundColor: finalRaceResult == 'win' ? Colors.green : Colors.orange,
              ),
            );

            final Map<String, dynamic> userResult = {
              'time': _elapsedSeconds,
              'distance': _distanceKm,
              'pace': _paceMinPerKm,
            };

            final Map<String, dynamic> ghostResult = {
              'time': widget.ghostRunData['time'] ?? 0,
              'distance': widget.ghostRunData['distance'] ?? 0.0,
              'pace': widget.ghostRunData['pace'] ?? 0.0,
            };

            Timer(const Duration(seconds: 3), () {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GhostRunResultScreen(
                      userResult: userResult,
                      ghostResult: ghostResult,
                      isWin: isWin,
                    ),
                  ),
                );
              }
            });
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
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            '러닝 중지',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '러닝을 중지하시겠습니까?',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '아니오',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                '예',
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
  Future<void> _saveRunRecord({bool isAutoSave = false, String? raceResult}) async {
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

      String ghostRecordId = widget.ghostRunData['id'] ?? '';

      final finalRaceResult = raceResult ?? (_distanceKm > _ghostDistanceKm ? 'win' : (_distanceKm < _ghostDistanceKm ? 'lose' : 'tie'));

      bool shouldUpdateLatest = finalRaceResult == 'win' || (isAutoSave && finalRaceResult == 'lose');

      final record = {
        'date': Timestamp.fromDate(now),
        'time': _elapsedSeconds,
        'distance': _distanceKm,
        'pace': _paceMinPerKm,
        'isFirstRecord': false,
        'locationPoints': locationPoints,
        'autoSaved': isAutoSave,
        'ghostRecordId': ghostRecordId,
        'raceResult': finalRaceResult,
        'isLatestRecord': shouldUpdateLatest,
      };

      DocumentReference docRef = await _firestore
          .collection('ghostRunRecords')
          .doc(userEmail)
          .collection('records')
          .add(record);

      if (shouldUpdateLatest) {
        await _firestore
            .collection('ghostRunRecords')
            .doc(userEmail)
            .set({
          'latestRecordId': docRef.id,
          'latestRecordDate': Timestamp.fromDate(now),
        }, SetOptions(merge: true));
      }

      print('기록이 성공적으로 저장되었습니다. 자동 저장: $isAutoSave, 최신 기록 갱신: $shouldUpdateLatest');
    } catch (e) {
      print('기록 저장 중 오류 발생: $e');
    }
  }

  // 트래킹 종료 및 기록 저장
  Future<void> _finishTracking({bool save = true}) async {
    _timer?.cancel();
    _ghostTimer?.cancel();
    _autoSaveTimer?.cancel();
    setState(() {
      _isTracking = false;
    });

    String finalRaceResult = _distanceKm > _ghostDistanceKm ? 'win' : (_distanceKm < _ghostDistanceKm ? 'lose' : 'tie');
    bool isWin = finalRaceResult == 'win';

    final Map<String, dynamic> userResult = {
      'time': _elapsedSeconds,
      'distance': _distanceKm,
      'pace': _paceMinPerKm,
    };

    final Map<String, dynamic> ghostResult = {
      'time': widget.ghostRunData['time'] ?? 0,
      'distance': widget.ghostRunData['distance'] ?? 0.0,
      'pace': widget.ghostRunData['pace'] ?? 0.0,
    };

    if (save) {
      await _saveRunRecord(raceResult: finalRaceResult);
    }

    if (mounted) {
      if (save) {
        // 저장한 경우에만 결과 페이지로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GhostRunResultScreen(
              userResult: userResult,
              ghostResult: ghostResult,
              isWin: isWin,
            ),
          ),
        );
      } else {
        // 저장하지 않은 경우 GhostRunPage로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GhostRunPage(),
          ),
        );
      }
    }
  }

  // 폴리라인 업데이트
  void _updatePolylines() {
    if (_points.length < 2) return;

    final myPolyline = Polyline(
      polylineId: const PolylineId('run_track'),
      points: _points,
      color: Colors.blue,
      width: 5,
    );

    setState(() {
      _polylines.removeWhere((polyline) => polyline.polylineId.value == 'run_track');
      _polylines.add(myPolyline);
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

  // 고스트 위치로 이동하는 함수 추가
  void _moveToGhost() {
    if (_ghostPoints.isNotEmpty && _ghostIndex < _ghostPoints.length) {
      LatLng ghostPosition = LatLng(
        _ghostPoints[_ghostIndex]['latitude']!,
        _ghostPoints[_ghostIndex]['longitude']!,
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(ghostPosition, 16.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool stop = await _showStopConfirmDialog();
        if (stop) {
          await _finishTracking(save: false); // 저장 없이 GhostRunPage로 이동
        }
        return stop;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 지도 표시
            _currentLocation != null
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
              markers: _markers,
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
            // 고스트 위치 보기 버튼 (상단 우측)
            Positioned(
              top: 140,
              right: 10,
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _followUserLocation = false;
                  });
                  _moveToGhost(); // 눌렀을 때 바로 고스트 위치로 이동
                },
                onTapUp: (_) {
                  setState(() {
                    _followUserLocation = true;
                  });
                  if (_currentLocation != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(
                          _currentLocation!.latitude ?? 0.0,
                          _currentLocation!.longitude ?? 0.0,
                        ),
                      ),
                    );
                  }
                },
                onVerticalDragUpdate: (_) {
                  _moveToGhost(); // 드래그 중에도 계속 이동
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/ghostlogo.png',
                    width: 24,
                    height: 24,
                    color: Colors.purple,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // 뒤로가기 버튼
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
            // 타이틀
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
            // 자동 저장 알림
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
            // 경주 상태 메시지
            Positioned(
              top: 160,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _leadDistance > 0 &&
                            _raceStatus.contains('앞서고') &&
                            !_raceStatus.contains('고스트가')
                            ? Icons.emoji_events
                            : Icons.directions_run,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _raceStatus.isEmpty
                            ? '고스트와 경주 중입니다!'
                            : _raceStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 하단 정보 패널
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
                padding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 내 정보 행
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          "Me",
                          style:
                          TextStyle(color: Colors.white, fontSize: 12),
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
                                  style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
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
                                  "Distance",
                                  style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
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
                                  style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 고스트 정보 행
                    Row(
                      children: [
                        const Icon(Icons.directions_run,
                            color: Colors.purple, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          "Ghost",
                          style:
                          TextStyle(color: Colors.purple, fontSize: 12),
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
                                  _ghostTimeDisplay,
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Time",
                                  style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
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
                                  _ghostDistanceDisplay,
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Distance",
                                  style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
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
                                  _ghostPaceDisplay,
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "min/km",
                                  style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 일시정지/재개/중지 버튼
                    if (!_isPaused)
                      Center(
                        child: GestureDetector(
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
                      )
                    else
                      Row(
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
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}