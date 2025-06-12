import 'package:flutter/material.dart';
import 'package:work/challenge/components/header.dart';
import 'package:work/challenge/components/challenge_form.dart';

class ChallengeSetupScreen extends StatelessWidget {
  const ChallengeSetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            const ChallengeForm(),  // ChallengeForm에 이미 NextButton이 포함되어 있으므로 별도로 추가할 필요 없음
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
