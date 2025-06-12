import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:work/RunningData_screen/RunningDataScreen.dart';
import 'package:work/free_running/settings_page.dart';
import 'dart:async';
import 'dart:math';
import 'package:work/main_screens/main_screen.dart';
import 'package:location/location.dart'; // 위치 서비스 패키지 추가

class FreeRunningPage extends StatefulWidget {
  final double kilometers;
  final int seconds;
  final double pace;
  final int bpm;
  final int stepCount;
  final double elevation;
  final double averageSpeed;
  final double calories;
  final List<LatLng> routePoints;

  FreeRunningPage({
    required this.kilometers,
    required this.seconds,
    required this.pace,
    required this.bpm,
    required this.stepCount,
    required this.elevation,
    required this.averageSpeed,
    required this.calories,
    required this.routePoints,
  });

  @override
  _FreeRunningPageState createState() => _FreeRunningPageState();
}

class _FreeRunningPageState extends State<FreeRunningPage> {
  late GoogleMapController mapController;
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  bool _isSaving = false;
  bool _isMapReady = false;
  Location location = Location(); // 위치 서비스 인스턴스 생성
  StreamSubscription<LocationData>? _locationSubscription; // 위치 업데이트 구독

  @override
  void initState() {
    super.initState();
    _updatePolylines();
    _addEndMarker();
    _setupLocationService(); // 위치 서비스 설정
  }

  @override
  void dispose() {
    _locationSubscription?.cancel(); // 위치 업데이트 구독 취소
    super.dispose();
  }

  // 위치 서비스 설정
  Future<void> _setupLocationService() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // 위치 서비스가 활성화되어 있는지 확인
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // 위치 권한 확인
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // 위치 서비스 설정 최적화 (빠른 업데이트를 위한 설정)
    location.changeSettings(
      accuracy: LocationAccuracy.high, // 높은 정확도
      interval: 500, // 0.5초마다 업데이트
      distanceFilter: 5, // 5미터 이동 시 업데이트
    );

    // 위치 업데이트 구독
    _locationSubscription = location.onLocationChanged.listen((LocationData currentLocation) {
      if (_isMapReady && mounted) {
        // 현재 위치로 카메라 이동 (필요한 경우)
        mapController.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(currentLocation.latitude!, currentLocation.longitude!),
          ),
        );
      }
    });
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    // 지도 스타일 최적화 (선택적)
    try {
      // 지도 스타일을 간소화하여 렌더링 성능 향상
      await controller.setMapStyle('''
      [
        {
          "featureType": "poi",
          "elementType": "labels",
          "stylers": [{ "visibility": "off" }]
        },
        {
          "featureType": "transit",
          "elementType": "labels",
          "stylers": [{ "visibility": "off" }]
        }
      ]
    ''');
    } catch (e) {
      print('지도 스타일 설정 오류: $e');
    }

    if (widget.routePoints.isNotEmpty) {
      try {
        // 최소 2개 이상의 포인트가 있을 때만 경계 설정
        if (widget.routePoints.length >= 2) {
          double minLat = double.infinity;
          double maxLat = -double.infinity;
          double minLng = double.infinity;
          double maxLng = -double.infinity;

          // 경로 포인트 중 유효한 점만 사용
          for (var point in widget.routePoints) {
            if (point.latitude.isFinite && point.longitude.isFinite) {
              minLat = min(minLat, point.latitude);
              maxLat = max(maxLat, point.latitude);
              minLng = min(minLng, point.longitude);
              maxLng = max(maxLng, point.longitude);
            }
          }

          // 모든 값이 유효한지 확인
          if (minLat.isFinite && maxLat.isFinite &&
              minLng.isFinite && maxLng.isFinite &&
              minLat != maxLat && minLng != maxLng) {
            // 약간의 여백 추가
            final latPadding = (maxLat - minLat) * 0.1;
            final lngPadding = (maxLng - minLng) * 0.1;

            await controller.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(minLat - latPadding, minLng - lngPadding),
                  northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
                ),
                50.0,
              ),
            );
          } else {
            // 경계 설정 실패 시 첫 번째 포인트로 이동
            await controller.animateCamera(
              CameraUpdate.newLatLngZoom(widget.routePoints.first, 15),
            );
          }
        } else {
          // 포인트가 하나만 있을 경우
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(widget.routePoints.first, 15),
          );
        }
      } catch (e) {
        print('카메라 이동 오류: $e');
        // 오류 발생 시 기본 위치로 이동
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            widget.routePoints.isNotEmpty
                ? widget.routePoints.last
                : LatLng(37.5665, 126.9780),
            15.0,
          ),
        );
      }
    }

    setState(() {
      _isMapReady = true;
    });
  }

  void _updatePolylines() {
    polylines.clear();
    if (widget.routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: PolylineId('running_route'),
          points: widget.routePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
    }
  }

  void _addEndMarker() {
    if (widget.routePoints.isNotEmpty) {
      markers.add(
        Marker(
          markerId: MarkerId('end_position'),
          position: widget.routePoints.last,
          infoWindow: InfoWindow(title: '종료 지점'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  Future<void> _saveRunningData() async {
    setState(() {
      _isSaving = true;
    });

    try {
      List<Map<String, double>> routePointsList = widget.routePoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList();

      String email = FirebaseAuth.instance.currentUser?.email ?? '';

      if (email == '') {
        throw Exception("사용자 이메일을 찾을 수 없습니다.");
      }

      String date = DateTime.now().toIso8601String().substring(0, 10);

      final runningData = {
        'date': Timestamp.now(),
        'kilometers': widget.kilometers,
        'seconds': widget.seconds,
        'pace': widget.pace,
        'bpm': widget.bpm,
        'stepCount': widget.stepCount,
        'elevation': widget.elevation,
        'averageSpeed': widget.averageSpeed,
        'calories': widget.calories,
        'routePoints': routePointsList,
      };

      await FirebaseFirestore.instance
          .collection('userRunningData')
          .doc(email)
          .collection('workouts')
          .doc(date)
          .set(runningData, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('userRunningData')
          .doc(email)
          .collection('workouts')
          .doc(date)
          .collection('records')
          .add({
        ...runningData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('러닝 기록이 저장되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RunningStatsPage(date: date)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _showCancelConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('저장을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('예'),
          ),
        ],
      ),
    );

    if (result == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 21),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 30),
                  Text(
                    '자유러닝',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                    child: Icon(Icons.settings, size: 30),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              height: 300,
              width: double.infinity,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: widget.routePoints.isNotEmpty
                      ? widget.routePoints.last
                      : LatLng(37.5665, 126.9780),
                  zoom: 15.0,
                ),
                polylines: polylines,
                markers: markers,
                myLocationEnabled: true, // 현재 위치 표시 활성화
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapType: MapType.normal,
                compassEnabled: true,
                buildingsEnabled: true,
                mapToolbarEnabled: false,
                tiltGesturesEnabled: false, // 틸트 제스처 비활성화로 성능 향상
                trafficEnabled: false, // 교통 상황 비활성화로 성능 향상
              ),
            ),

            SizedBox(height: 50),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.kilometers.toStringAsFixed(1)}KM',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateTime.now().toString().substring(0, 16),
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRunningDetail('평균 페이스', formatPace(widget.pace)),
                            SizedBox(height: 8),
                            _buildRunningDetail(' 걸음수', '${widget.stepCount}'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildRunningDetail('시간', formatTime(widget.seconds)),
                            SizedBox(height: 8),
                            _buildRunningDetail('고도', '${widget.elevation.toStringAsFixed(0)} m'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildRunningDetail('칼로리', '${widget.calories.toStringAsFixed(0)} kcal'),
                            SizedBox(height: 8),
                            _buildRunningDetail('평균 속도', '${widget.averageSpeed.toStringAsFixed(1)} km/h'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _showCancelConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('취소', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveRunningData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                          : Text('저장', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRunningDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String formatPace(double pace) {
    // 페이스가 없거나 비현실적인 경우
    if (pace <= 0.0 || pace > 99.0) {
      return "--'--''";
    }

    int minutes = pace.floor();
    double secondsDecimal = (pace - minutes) * 60;
    int seconds = secondsDecimal.round();

    // 초가 60이 되면 분으로 올림
    if (seconds == 60) {
      minutes++;
      seconds = 0;
    }

    return '${minutes}\'${seconds.toString().padLeft(2, '0')}\'\'';
  }

  String formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes}\'${remainingSeconds}\'\'';
  }
}