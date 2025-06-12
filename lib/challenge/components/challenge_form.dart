import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore 추가
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication 추가
import '../challenge_screen.dart';
import 'next_button.dart'; // NextButton import
import 'dart:convert'; // URL 인코딩을 위한 라이브러리 추가
import '../challenge.dart';

class ChallengeForm extends StatefulWidget {
  const ChallengeForm({Key? key}) : super(key: key);

  @override
  State<ChallengeForm> createState() => _ChallengeFormState();
}

class _ChallengeFormState extends State<ChallengeForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();

  // 데이터 저장 메서드

  Future<void> _saveChallenge() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자가 로그인되지 않았습니다.')),
      );
      return;
    }

    final String userEmail = user.email ?? ''; // 사용자 이메일 가져오기

    if (userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자의 이메일이 없습니다.')),
      );
      return;
    }

    // 이메일을 문서 ID로 사용하지 않고, 이메일 + timestamp 조합으로 문서 ID 생성
    final String userEmailFormatted = userEmail.replaceAll('@', '_at_').replaceAll('.', '_dot_');
    final String challengeId = '${userEmailFormatted}_${DateTime.now().millisecondsSinceEpoch}';

    if (_nameController.text.isNotEmpty &&
        _durationController.text.isNotEmpty &&
        _distanceController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('challenges').doc(challengeId).set({
        'name': _nameController.text,
        'duration': _durationController.text,
        'distance': _distanceController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'userEmail': userEmail, // 사용자 이메일 저장
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge saved!')),
      );

      // 저장 후 챌린지 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChallengeScreen()),
      );

      _nameController.clear();
      _durationController.clear();
      _distanceController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
    }
  }




  // 필드 검증 후 다음 단계로 진행하는 함수
  void _validateAndProceed() {
    // 입력된 값이 모두 비어있는지 확인
    if (_nameController.text.isEmpty ||
        _durationController.text.isEmpty ||
        _distanceController.text.isEmpty) {
      // 비어있는 필드가 있으면 다이얼로그 표시
      _showDialog();
    } else {
      // 필드가 모두 채워졌으면 저장하고 이동
      _saveChallenge();
    }
  }

  // 다이얼로그 표시 함수
  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // 배경을 흰색으로 설정
          title: Text(
            '정보를 입력해주세요',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            "모든 필드를 입력해 주세요.",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  // 다이얼로그 닫기
              },
              child: Text(
                '확인',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '챌린지 설정',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '원하는 챌린지를 설정해주세요.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7B6F72),
            ),
          ),
          const SizedBox(height: 32),
          _buildFormField(
            '챌린지 이름',
            Icons.text_fields,
            _nameController,
          ),
          const SizedBox(height: 16),
          _buildFormField(
            '기간',
            Icons.calendar_today,
            _durationController,
          ),
          const SizedBox(height: 16),
          _buildFormField(
            '거리',
            Icons.directions_run,
            _distanceController,
          ),
          const SizedBox(height: 32),
          // NextButton에 _validateAndProceed 메서드 전달
          NextButton(onPressed: _validateAndProceed),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, IconData icon, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: const Color(0xFF7B6F72),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: label,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFADA4A5),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
