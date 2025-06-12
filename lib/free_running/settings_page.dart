import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SharedPreferences prefs;

  // 현재 설정값들
  loc.LocationAccuracy selectedAccuracy = loc.LocationAccuracy.high;
  int interval = 1000;
  double distanceFilter = 0.0;

  final Map<String, loc.LocationAccuracy> accuracyOptions = {
    'High': loc.LocationAccuracy.high,
    'Balanced': loc.LocationAccuracy.balanced,
    'Low': loc.LocationAccuracy.low,
    'Navigation': loc.LocationAccuracy.navigation,
  };

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    prefs = await SharedPreferences.getInstance();

    String? savedAccuracyKey = prefs.getString('accuracy');
    if (savedAccuracyKey != null && accuracyOptions.containsKey(savedAccuracyKey)) {
      setState(() {
        selectedAccuracy = accuracyOptions[savedAccuracyKey]!;
      });
    }

    setState(() {
      interval = prefs.getInt('interval') ?? 1000;
      distanceFilter = prefs.getDouble('distanceFilter') ?? 0.0;
    });
  }

  Future<void> _saveSettingsAndPop() async {
    prefs.setString('accuracy', accuracyOptions.entries
        .firstWhere((entry) => entry.value == selectedAccuracy)
        .key);
    prefs.setInt('interval', interval);
    prefs.setDouble('distanceFilter', distanceFilter);

    Navigator.of(context).pop(); // 이전 화면으로 돌아감
  }

  Future<void> _resetToDefaults() async {
    bool? confirm = await _showResetConfirmationDialog(context);
    if (confirm == true) {
      setState(() {
        selectedAccuracy = loc.LocationAccuracy.high;
        interval = 1000;
        distanceFilter = 0.0;
      });
      prefs.setString('accuracy', 'high');
      prefs.setInt('interval', 1000);
      prefs.setDouble('distanceFilter', 0.0);
    }
  }

  Future<bool?> _showResetConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('설정 초기화'),
        content: Text('모든 설정을 기본값으로 되돌리시겠습니까?'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('예'),
          ),
        ],
      ),
    );
  }

  void _showDescriptionDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('닫기'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경 흰색
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 0,
        title: Text('러닝 설정'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '위치 정확도',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    _showDescriptionDialog(
                      '위치 정확도',
                      'GPS의 위치 감지 정확도를 설정합니다.\n'
                          '- High: 가장 정밀한 위치\n'
                          '- Balanced: 일반적인 사용 권장\n'
                          '- Low: 배터리 절약 모드\n'
                          '- Navigation: 내비게이션 수준의 고정밀',
                    );
                  },
                  child: Icon(Icons.help_outline, color: Colors.blue),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              '다음 러닝부터 적용됩니다!',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            SizedBox(height: 8),
            DropdownButton<loc.LocationAccuracy>(
              value: selectedAccuracy,
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  selectedAccuracy = value!;
                });
              },
              items: accuracyOptions.entries.map((entry) {
                return DropdownMenuItem<loc.LocationAccuracy>(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Text(
                    '업데이트 주기 (ms)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    _showDescriptionDialog(
                      '업데이트 주기',
                      '위치 업데이트가 얼마나 자주 발생하는지를 설정합니다.\n'
                          '- 낮은 값일수록 실시간 반응성이 좋지만 배터리 소모가 큽니다.',
                    );
                  },
                  child: Icon(Icons.help_outline, color: Colors.blue),
                ),
              ],
            ),
            Slider(
              min: 500,
              max: 5000,
              divisions: 9,
              label: '$interval ms',
              value: interval.toDouble(),
              onChanged: (double value) {
                setState(() {
                  interval = value.toInt();
                });
              },
            ),

            SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Text(
                    '이동 필터 (미터)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    _showDescriptionDialog(
                      '이동 필터',
                      '사용자의 위치가 몇 미터 이상 변경되었을 때만 업데이트를 반영합니다.\n'
                          '- 0m: 모든 변화 감지\n'
                          '- 높을수록 배터리 절약',
                    );
                  },
                  child: Icon(Icons.help_outline, color: Colors.blue),
                ),
              ],
            ),
            Slider(
              min: 0.0,
              max: 10.0,
              divisions: 10,
              label: '${distanceFilter.toStringAsFixed(1)} m',
              value: distanceFilter,
              onChanged: (double value) {
                setState(() {
                  distanceFilter = value;
                });
              },
            ),

            SizedBox(height: 32),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _saveSettingsAndPop,
              child: Center(child: Text('적용하기', style: TextStyle(color: Colors.white))),
            ),

            SizedBox(height: 8),

            TextButton(
              onPressed: _resetToDefaults,
              child: Text('초기화', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}