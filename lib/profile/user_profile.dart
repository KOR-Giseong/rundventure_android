import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:work/home_Screens/home_screen2.dart';
import 'package:work/main_screens/main_screen.dart';
import '../login_screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late String _selectedGender;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _birthdateController;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _emailController = TextEditingController();
    _selectedGender = '남자';
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _birthdateController = TextEditingController();
    _fetchUserData();
  }

  void _fetchUserData() {
    final User? user = _auth.currentUser;
    if (user != null) {
      final email = user.email;
      if (email != null) {
        _firestore.collection('users').doc(email).get().then((doc) {
          if (doc.exists) {
            final userData = doc.data();
            setState(() {
              _nicknameController.text = userData?['nickname'] ?? '';
              _selectedGender = userData?['gender'] ?? '남자';
              _weightController.text = userData?['weight'] ?? '';
              _heightController.text = userData?['height'] ?? '';
              _birthdateController.text = userData?['birthdate'] ?? '';
              _emailController.text = email;
              _profileImageUrl = userData?['profileImageUrl'];
            });
          }
        }).catchError((error) {
          print("Error fetching user data: $error");
        });
      }
    }
  }

  // 📸 이미지 선택 및 Cloudinary 업로드
  Future<void> _pickAndUploadImage() async {
    final User? user = _auth.currentUser;
    if (user == null) return;
    final email = user.email;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('갤러리에서 선택'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile == null) return;
                File imageFile = File(pickedFile.path);

                try {
                  final url = Uri.parse('https://api.cloudinary.com/v1_1/dr2zrqasn/image/upload');
                  var request = http.MultipartRequest('POST', url)
                    ..fields['upload_preset'] = 'Rundventure'
                    ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
                  var response = await request.send();

                  if (response.statusCode == 200) {
                    var responseData = await response.stream.bytesToString();
                    var jsonResponse = json.decode(responseData);
                    String imageUrl = jsonResponse['secure_url'] + '?v=${DateTime.now().millisecondsSinceEpoch}';

                    await _firestore.collection('users').doc(email).set({
                      'profileImageUrl': imageUrl,
                    }, SetOptions(merge: true));

                    setState(() {
                      _profileImageUrl = imageUrl;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('프로필 이미지가 업데이트되었습니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('이미지 업로드에 실패했습니다.')),
                    );
                  }
                } catch (e) {
                  print("Error uploading image: $e");
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.restore),
              title: Text('기본 이미지로 변경'),
              onTap: () async {
                Navigator.pop(context);

                // Firestore에 빈 문자열 저장
                await _firestore.collection('users').doc(email).set({
                  'profileImageUrl': null, // ✅ null로 설정
                }, SetOptions(merge: true));

                setState(() {
                  _profileImageUrl = null; // null 처리하여 기본 이미지 표시
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('기본 이미지로 변경되었습니다.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('로그아웃'),
          content: Text('로그아웃 하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('아니오'),
            ),
            TextButton(
              onPressed: () async {
                await _auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Home_screen2()),
                );
              },
              child: Text('예'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final email = user.email;
      try {
        double weight = double.tryParse(_weightController.text) ?? 0;
        double height = double.tryParse(_heightController.text) ?? 0;
        double bmi = height > 0 ? weight / ((height / 100) * (height / 100)) : 0;

        await _firestore.collection('users').doc(email).update({
          'nickname': _nicknameController.text,
          'gender': _selectedGender,
          'weight': _weightController.text,
          'height': _heightController.text,
          'birthdate': _birthdateController.text,
          'email': email,
          'bmi': bmi,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필이 업데이트 되었습니다.')),
        );
        _fetchUserData(); // 데이터 다시 불러오기
      } catch (error) {
        print("Error updating document: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 업데이트에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // 뒤로가기 버튼
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Image.asset(
                                  'assets/images/Back-Navs.png',
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            ),
                          ),
                          // 가운데 텍스트
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                '프로필',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                          ),
                          // 로그아웃 아이콘
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _logout,
                                child: Icon(
                                  Icons.exit_to_app,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Stack(
                        children: [
                          // 프로필 이미지
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipOval(
                              child: _profileImageUrl != null
                                  ? Image.network(
                                _profileImageUrl!,
                                key: UniqueKey(),
                                fit: BoxFit.cover,
                                width: 84,
                                height: 84,
                              )
                                  : Image.asset(
                                'assets/images/user.png',
                                fit: BoxFit.cover,
                                width: 84,
                                height: 84,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 84,
                                    height: 84,
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    child: Text(
                                      'No Image',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // 카메라 아이콘
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                _buildProfileForm(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          label: '취소',
                          isOutlined: true,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ActionButton(
                          label: '저장',
                          isOutlined: false,
                          onPressed: _saveProfile,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileTextField(
              label: '',
              icon: Icons.person,
              controller: _nicknameController,
              width: double.infinity,
              height: 60,
            ),
            const SizedBox(height: 16),
            ProfileTextField(
              label: '',
              icon: Icons.email,
              controller: _emailController,
              width: double.infinity,
              height: 60,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GenderButton(
                    label: '남자',
                    isSelected: _selectedGender == '남자',
                    onPressed: () {
                      setState(() {
                        _selectedGender = '남자';
                      });
                    },
                    width: double.infinity,
                    height: 60,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: GenderButton(
                    label: '여자',
                    isSelected: _selectedGender == '여자',
                    onPressed: () {
                      setState(() {
                        _selectedGender = '여자';
                      });
                    },
                    width: double.infinity,
                    height: 60,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _selectBirthdate(context),
              child: ProfileTextField(
                label: '',
                icon: Icons.calendar_today,
                controller: _birthdateController,
                width: double.infinity,
                height: 60,
                readOnly: true,
              ),
            ),
            const SizedBox(height: 16),
            // 키 입력 필드
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 13),
                        Image.asset(
                          'assets/images/Height.png',
                          width: 22,
                          height: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _heightController,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Pretendard',
                            ),
                            decoration: InputDecoration(
                              hintText: '키',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                UnitButton(
                  label: 'CM',
                  width: 60,
                  height: 60,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 체중 입력 필드
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 13),
                        Image.asset(
                          'assets/images/weight.png',
                          width: 22,
                          height: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Pretendard',
                            ),
                            decoration: InputDecoration(
                              hintText: '체중',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                UnitButton(
                  label: 'KG',
                  width: 60,
                  height: 60,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBirthdate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onSurface: Colors.black,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthdateController.text = '${picked.year}-${picked.month}-${picked.day}';
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final bool isOutlined;
  final VoidCallback onPressed;

  const ActionButton({
    Key? key,
    required this.label,
    required this.isOutlined,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 60)),
        backgroundColor: MaterialStateProperty.all(
            isOutlined ? Colors.white : Colors.black),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isOutlined ? Colors.black : Colors.transparent,
              width: 1,
            ),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: isOutlined ? Colors.black : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}

class GenderButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const GenderButton({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
          isSelected ? Colors.black : Colors.white,
        ),
        foregroundColor: MaterialStateProperty.all(
          isSelected ? Colors.white : Colors.black,
        ),
        minimumSize: MaterialStateProperty.all(Size(width, height)),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.black : Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}

class UnitButton extends StatelessWidget {
  final String label;
  final double width;
  final double height;

  const UnitButton({
    Key? key,
    required this.label,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFFF9F80),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard',
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class ProfileTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final double width;
  final double height;
  final bool readOnly;

  const ProfileTextField({
    Key? key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.width,
    required this.height,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 13),
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: 'Pretendard',
              ),
              readOnly: readOnly,
              decoration: InputDecoration(
                hintText: label,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}