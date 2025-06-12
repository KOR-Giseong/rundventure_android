import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'free_running.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 추가된 부분

class RunningPage extends StatefulWidget {
  @override
  _RunningPageState createState() => _RunningPageState();
}

class _RunningPageState extends State<RunningPage> with SingleTickerProviderStateMixin {
  // 위치 관련 변수
  loc.Location location = loc.Location();
  LatLng? _currentLocation;
  StreamSubscription<loc.LocationData>? _locationSubscription;
  GoogleMapController? _googleMapController;

  // 운동 데이터 변수
  double _pace = 0.0;
  int _seconds = 0;
  double _kilometers = 0.0;
  double _elevation = 0.0; // 고도 (총 상승 고도)
  double _averageSpeed = 0.0;
  double _calories = 0.0;
  int _stepCount = 0;
  bool _isPaused = false;

  // 사용자 체중 관련 변수 추가
  double? _userWeight;
  bool _isLoadingUserData = true;

  // 타이머
  Timer? _timer;

  // 이동 거리 계산을 위한 변수
  loc.LocationData? _lastLocation;

  // 카운트다운 및 메시지 변수
  int _countdown = 3;
  bool _showStartMessage = true;
  late AnimationController _animationController;

  // 카운트다운 이후 지도 표시 여부
  bool _showMap = false;

  // 이동 경로를 저장할 리스트
  List<LatLng> _routePoints = [];

  // 👇 SharedPreferences 인스턴스 추가
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    )..repeat(reverse: true);

    // 👇 SharedPreferences 초기화
    _initSharedPreferences();

    // 현재 위치를 즉시 가져옴
    _getCurrentLocation();
    _startCountdown();
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  // 현재 위치를 즉시 가져오는 메소드
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    // 👇 설정 반영
    await location.changeSettings(
      accuracy: _getLocationAccuracy(),
      interval: _getInterval(),
      distanceFilter: _getDistanceFilter(),
    );

    // 연속 업데이트 시작 전에 한 번 위치 가져오기
    final locationData = await location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        _elevation = locationData.altitude ?? 0.0; // 고도 초기값 설정
      });
      _lastLocation = locationData; // 최초 위치 저장
    }
  }

  // 사용자 체중 정보 로드 함수
  Future<void> _loadUserWeight() async {
    try {
      String userEmail = FirebaseAuth.instance.currentUser!.email!;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userWeight = (userDoc.data() as Map<String, dynamic>)['weight']?.toDouble() ?? 70.0;
          _isLoadingUserData = false;
        });
      } else {
        setState(() {
          _userWeight = 70.0; // 기본값 설정
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      print('Error loading user weight: $e');
      setState(() {
        _userWeight = 70.0; // 오류 시 기본값 설정
        _isLoadingUserData = false;
      });
    }
  }

  void _startCountdown() {
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showStartMessage = false;
      });
      Timer.periodic(Duration(seconds: 1), (timer) {
        if (_countdown > 1) {
          setState(() {
            _countdown--;
          });
        } else {
          timer.cancel();
          setState(() {
            _countdown = 0;
            _showMap = true;
          });
          _initializeTracking();
        }
      });
    });
  }

  Future<void> _initializeTracking() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    // 👇 설정 반영
    await location.changeSettings(
      accuracy: _getLocationAccuracy(),
      interval: _getInterval(),
      distanceFilter: _getDistanceFilter(),
    );

    _startLocationTracking();
    _startTimer();
  }

  void _startLocationTracking() {
    _locationSubscription = location.onLocationChanged.listen((loc.LocationData currentLocation) {
      if (_isPaused) return;

      // 현재 위치 정보가 유효한지 확인
      if (currentLocation.latitude == null || currentLocation.longitude == null) {
        print('위치 정보 누락');
        return;
      }

      LatLng newLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);

      // 고도 계산
      double currentAltitude = currentLocation.altitude ?? 0.0;
      double elevationDiff = 0.0;

      if (_lastLocation != null) {
        double lastAltitude = _lastLocation!.altitude ?? 0.0;
        elevationDiff = currentAltitude - lastAltitude;

        // 상승한 경우에만 고도 반영 (임계값 0.5m 이상)
        if (elevationDiff > 0.5) {
          _elevation += elevationDiff;
        }
      }

      setState(() {
        _currentLocation = newLocation;
      });

      // 지도 컨트롤러 업데이트
      if (_googleMapController != null) {
        _googleMapController!.animateCamera(CameraUpdate.newLatLng(newLocation));
      }

      if (_lastLocation != null) {
        double distance = Geolocator.distanceBetween(
          _lastLocation!.latitude!,
          _lastLocation!.longitude!,
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
        double timeIntervalSec = (currentLocation.time! - (_lastLocation?.time ?? 0)) / 1000;
        if (timeIntervalSec <= 0) timeIntervalSec = 0.5;
        double speed = distance / timeIntervalSec; // m/s

        if (speed > 10.0) {
          print('비현실적인 속도 감지: $speed m/s');
          return;
        }

        if (distance > 0.5) {
          setState(() {
            _kilometers += distance / 1000;
            _stepCount += (distance / 0.78).toInt(); // 평균 보폭 0.78m 기준으로 걸음 수 계산
            _routePoints.add(newLocation);
            print('거리 업데이트: $_kilometers km (추가: ${distance / 1000} km)');
          });
        }
      } else {
        setState(() {
          _routePoints.add(newLocation);
          print('첫 위치 기록됨');
        });
      }

      _lastLocation = currentLocation;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _seconds++;
          _updatePaceAndSpeed();
          _updateCalories();
        });
      }
    });
  }

  void _updatePaceAndSpeed() {
    if (_kilometers > 0.005 && _seconds > 5) {
      _averageSpeed = (_kilometers / (_seconds / 3600));
      _pace = (_seconds / 60) / _kilometers;
      if (_pace < 1.0) _pace = 1.0;
      if (_pace > 30.0) _pace = 30.0;
      print('페이스 계산: $_pace 분/km, 평균 속도: $_averageSpeed km/h');
    } else {
      if (_pace <= 0.0) {
        _pace = 0.0;
        _averageSpeed = 0.0;
      }
      print('최소 조건 미달: 거리=$_kilometers, 시간=$_seconds');
    }
  }

  void _updateCalories() {
    if (_userWeight == null || _isPaused || _kilometers < 0.005) return;

    double met;
    if (_averageSpeed < 4.0) {
      met = 4.0;
    } else if (_averageSpeed < 6.4) {
      met = 6.0;
    } else if (_averageSpeed < 8.0) {
      met = 8.3;
    } else if (_averageSpeed < 9.7) {
      met = 9.8;
    } else if (_averageSpeed < 11.3) {
      met = 11.0;
    } else if (_averageSpeed < 12.9) {
      met = 11.8;
    } else {
      met = 12.8;
    }

    double hours = _seconds / 3600.0;
    _calories = met * _userWeight! * hours;
    print('칼로리 계산: MET=$met, 체중=$_userWeight, 시간=$hours, 칼로리=$_calories');
  }

  void _pauseRunning() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeRunning() {
    setState(() {
      _isPaused = false;
    });
  }

  void _stopRunning() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FreeRunningPage(
          kilometers: _kilometers,
          seconds: _seconds,
          pace: _pace,
          bpm: 0,
          stepCount: _stepCount,
          elevation: _elevation,
          averageSpeed: _averageSpeed,
          calories: _calories,
          routePoints: _routePoints,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            if (_showMap)
              Positioned.fill(
                child: GoogleMap(
                  onMapCreated: (controller) {
                    _googleMapController = controller;
                    if (_currentLocation != null) {
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentLocation!, 15),
                      );
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? LatLng(37.5665, 126.9780),
                    zoom: 15,
                  ),
                  markers: _currentLocation != null
                      ? {
                    Marker(
                      markerId: MarkerId(_currentLocation.toString()),
                      position: _currentLocation!,
                    ),
                  }
                      : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: _showStartMessage
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '운동을 시작합니다!',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
                    : _countdown > 0
                    ? AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.5).animate(_animationController),
                      child: Text(
                        '$_countdown',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                )
                    : _buildRunningPageContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunningPageContent() {
    if (_isLoadingUserData) {
      return Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRunningInfo('페이스', '${_pace.toStringAsFixed(2)}/KM'),
              _buildRunningInfo('시간', _formatTime(_seconds)),
              _buildRunningInfo('칼로리', '${_calories.toStringAsFixed(0)}kcal'),
            ],
          ),
        ),
        Spacer(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_kilometers.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 80, fontWeight: FontWeight.w900),
            ),
            Text(
              'KM',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isPaused)
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.stop, color: Colors.white),
                        iconSize: 30,
                        onPressed: _stopRunning,
                      ),
                    ),
                    SizedBox(width: 20),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.play_arrow, color: Colors.black),
                        iconSize: 30,
                        onPressed: _resumeRunning,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.pause, color: Colors.white),
                    iconSize: 30,
                    onPressed: _pauseRunning,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRunningInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // 👇 설정 불러오기 메서드 추가
  loc.LocationAccuracy _getLocationAccuracy() {
    String accuracyStr = prefs.getString('accuracy') ?? 'high';
    switch (accuracyStr) {
      case 'Balanced':
        return loc.LocationAccuracy.balanced;
      case 'Low':
        return loc.LocationAccuracy.low;
      case 'Navigation':
        return loc.LocationAccuracy.navigation;
      case 'high':
      default:
        return loc.LocationAccuracy.high;
    }
  }

  int _getInterval() {
    return prefs.getInt('interval') ?? 1000;
  }

  double _getDistanceFilter() {
    return prefs.getDouble('distanceFilter') ?? 0.0;
  }
}