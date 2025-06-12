import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class GhostRunTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> ghostRecord;

  const GhostRunTrackingScreen({super.key, required this.ghostRecord});

  @override
  State<GhostRunTrackingScreen> createState() => _GhostRunTrackingScreenState();
}

class _GhostRunTrackingScreenState extends State<GhostRunTrackingScreen> {
  GoogleMapController? _mapController;
  Location _location = Location();

  LatLng? _myPosition;
  LatLng? _ghostPosition;

  int _ghostIndex = 0;
  List<LatLng> ghostRoute = [];
  Timer? _ghostTimer;

  List<LatLng> myRoute = [];
  double myDistance = 0.0;
  double ghostDistance = 0.0;

  bool raceFinished = false;
  String? winner; // "me" or "ghost"

  bool isPaused = false;
  bool isStopped = false; // 대결 중단 여부
  bool isRaceStarted = false; // 대결 시작 여부
  StreamSubscription<LocationData>? _locationSubscription;

  int countdown = 3;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  Future<void> _initTracking() async {
    final List route = widget.ghostRecord['routePoints'] ?? [];
    ghostRoute = route.map((point) => LatLng(point['latitude'], point['longitude'])).toList();

    _ghostPosition = ghostRoute.isNotEmpty ? ghostRoute[0] : null;

    // 카운트다운 시작
    _startCountdown();
  }

  // 카운트다운 시작
  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          isRaceStarted = true; // 대결 시작
        });
        _startGhostTracking();
      }
    });
  }

  // 고스트 트래킹 시작
  void _startGhostTracking() {
    _ghostTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isPaused || isStopped || !isRaceStarted) return; // 정지 상태에서 업데이트 안함

      if (_ghostIndex < ghostRoute.length - 1) {
        setState(() {
          _ghostIndex++;
          _ghostPosition = ghostRoute[_ghostIndex];
          ghostDistance += _calculateDistance(
            ghostRoute[_ghostIndex - 1],
            ghostRoute[_ghostIndex],
          );
        });
      } else {
        _checkFinish();
      }
    });

    _locationSubscription = _location.onLocationChanged.listen((loc) {
      if (isPaused || isStopped || !isRaceStarted) return; // 정지 상태에서 위치 추적 안함

      final current = LatLng(loc.latitude!, loc.longitude!);

      setState(() {
        if (_myPosition != null) {
          myDistance += _calculateDistance(_myPosition!, current);
        }
        _myPosition = current;
        myRoute.add(current);
        _checkFinish();
      });
    });
  }

  void _checkFinish() {
    if (raceFinished) return;

    final kilometers = widget.ghostRecord['kilometers'];
    final double ghostGoal = (kilometers is int ? kilometers.toDouble() : kilometers) * 1000;

    final bool ghostFinished = ghostDistance >= ghostGoal;
    final bool myFinished = myDistance >= ghostGoal;

    if (ghostFinished || myFinished) {
      setState(() {
        raceFinished = true;
        winner = myFinished && myDistance >= ghostDistance ? 'me' : 'ghost';
      });

      _ghostTimer?.cancel();

      Future.delayed(const Duration(seconds: 3), () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(winner == 'me' ? '승리!' : '패배...'),
            content: Text(winner == 'me'
                ? '고스트보다 먼저 도착했어요!'
                : '고스트가 먼저 도착했어요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      });
    }
  }

  double _calculateDistance(LatLng a, LatLng b) {
    const R = 6371000;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);

    final aCalc = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(aCalc), sqrt(1 - aCalc));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  void dispose() {
    _ghostTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ghostAhead = _myPosition != null && _ghostPosition != null &&
        _calculateDistance(_ghostPosition!, _myPosition!) > 5;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _myPosition ?? const LatLng(37.7749, 127.0785),
              zoom: 16,
            ),
            myLocationEnabled: true,
            polylines: {
              if (ghostRoute.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId('ghostRoute'),
                  color: Colors.orange,
                  width: 4,
                  points: ghostRoute,
                ),
              if (myRoute.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId('myRoute'),
                  color: Colors.blueAccent,
                  width: 4,
                  points: myRoute,
                ),
            },
            markers: {
              if (_myPosition != null)
                Marker(markerId: const MarkerId('me'), position: _myPosition!, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),
              if (_ghostPosition != null)
                Marker(markerId: const MarkerId('ghost'), position: _ghostPosition!, icon: BitmapDescriptor.defaultMarker),
            },
            onMapCreated: (controller) async {
              _mapController = controller;
              final darkMapStyle = await DefaultAssetBundle.of(context).loadString('assets/maps/map_dark.json');
              _mapController?.setMapStyle(darkMapStyle);
            },
          ),

          // 카운트다운 표시
          if (!isRaceStarted)
            Positioned(
              top: 170,
              left: 90,
              child: Column(
                children: [
                  Text(
                    '대결을 시작합니다!',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                  Text(
                    '$countdown',
                    style: TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                ],
              ),
            ),

          // 고스트가 앞서고 있을 때
          if (ghostAhead)
            Positioned(
              top: 540,
              left: 30,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '고스트가 앞서고 있어요!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 100), // 왼쪽으로 이동
                    child: CustomPaint(
                      size: const Size(20, 10),
                      painter: TrianglePainter(), // 여기 const 붙이면 안 됩니다!
                    ),
                  ),
                ],
              ),
            ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRunnerInfoRow('Me', myDistance, widget.ghostRecord['pace'], isMe: true),
                      const SizedBox(height: 8),
                      _buildRunnerInfoRow('Ghost', ghostDistance, widget.ghostRecord['pace']),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Row(
                    children: [
                      // 최초 버튼 (일시정지/재개) 표시
                      if (!isPaused && !isStopped)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isPaused = true; // 일시정지 상태로 변경
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.deepOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pause,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // 일시정지 후 (재개) 버튼
                      if (isPaused && !isStopped)
                        Row(
                          children: [
                            // 재개 버튼
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isPaused = false; // 재개 상태로 변경
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // 중지 버튼
                            GestureDetector(
                              onTap: () async {
                                // 중단 버튼 눌렀을 때 다이얼로그 표시
                                final shouldStop = await _showStopDialog();
                                if (shouldStop) {
                                  setState(() {
                                    isStopped = true;
                                  });
                                  Navigator.of(context).pop();
                                }
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.stop,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showStopDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('대결 중단'),
        content: const Text('대결을 중단하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // 예
            },
            child: const Text('예'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // 아니오
            },
            child: const Text('아니오'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Widget _buildRunnerInfoRow(String name, double distance, double pace, {bool isMe = false}) {
    final border = isMe ? Border.all(color: Colors.white, width: 2) : null;
    final totalSeconds = (distance / (1000 / pace)).round();
    final timeText = _formatDuration(Duration(seconds: totalSeconds));
    final distanceText = (distance / 1000).toStringAsFixed(2);
    final paceText = '${pace.toStringAsFixed(2)}';

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // `Me` 또는 `Ghost`에 따라 다른 이미지를 표시
              Image.asset(
                isMe ? 'assets/images/runner.png' : 'assets/images/ghostrunner.png',
                width: 20, // 이미지 크기 조정
                height: 20,
              ),
              const SizedBox(width: 10), // 이미지와 텍스트 사이에 여백
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dataBox(title: 'Time', value: timeText),
              _dataBox(title: 'Km', value: '$distanceText km'),
              _dataBox(title: 'Pace', value: '$paceText'),
            ],
          ),
        ],
      ),
    );
  }


  Widget _dataBox({required String title, required String value}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.deepOrange.withOpacity(0.45);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
