import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FreeTalkForm extends StatefulWidget {
  const FreeTalkForm({Key? key}) : super(key: key);

  @override
  State<FreeTalkForm> createState() => _FreeTalkFormState();
}

class _FreeTalkFormState extends State<FreeTalkForm> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  File? _selectedImage;

  bool _showContentHint = true;

  bool get _isFormValid =>
      _titleController.text.trim().isNotEmpty &&
          _contentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateState);
    _contentController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {
      _showContentHint = _contentController.text.trim().isEmpty;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submitPost() async {
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String userEmail = user.email!;
    final String encodedEmail = userEmail.replaceAll('@', '_at_').replaceAll('.', '_dot_');

    String nickname = "닉네임 없음";

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(encodedEmail)
          .get();
      if (userDoc.exists && userDoc.data()?['nickname'] != null) {
        nickname = userDoc['nickname'];
      }
    } catch (e) {
      nickname = "닉네임 없음";
    }

    try {
      String imageUrl = '';
      if (_selectedImage != null) {
        imageUrl = await uploadImageToCloudinary(_selectedImage!); // 이미지 URL 업로드
      }

      final postData = {
        'userEmail': encodedEmail,
        'title': _titleController.text,
        'content': _contentController.text,
        'nickname': nickname,
        'imageUrl': imageUrl, // 이미지 URL 추가
        'timestamp': FieldValue.serverTimestamp(),
      };

      // posts 서브컬렉션에 게시물 저장
      await FirebaseFirestore.instance
          .collection('freeTalks')
          .add(postData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시물이 저장되었습니다!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류 발생: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  // Cloudinary에 이미지 업로드
  Future<String> uploadImageToCloudinary(File image) async {
    const String cloudinaryUrl = 'https://api.cloudinary.com/v1_1/dr2zrqasn/image/upload';
    const String cloudinaryPreset = 'freeTalksImage'; // Cloudinary에서 생성한 업로드 프리셋

    final uri = Uri.parse(cloudinaryUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryPreset
      ..fields['folder'] = 'freeTalks' // 'freeTalks' 폴더에 이미지 저장
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final data = json.decode(res.body);
      return data['secure_url']; // Cloudinary에 저장된 이미지의 URL 반환
    } else {
      throw Exception('이미지 업로드 실패: ${response.statusCode}');
    }
  }

  void _openPollDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('투표 기능은 아직 개발 중입니다.', style: TextStyle(fontSize: 16)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showContentHint = _contentController.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '글쓰기',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isFormValid ? _submitPost : null,
            child: Text(
              '완료',
              style: TextStyle(
                color: _isFormValid ? Colors.red : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // 제목 입력 필드
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // 본문 입력 필드
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    if (_showContentHint)
                      const Padding(
                        padding: EdgeInsets.only(top: 12, left: 4),
                        child: Text(
                          '자유롭게 얘기해보세요.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 이미지 미리보기
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      height: 150,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.black54),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // 하단 기능 바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.redAccent),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: const Icon(Icons.poll_outlined, color: Colors.blueAccent),
                  onPressed: _openPollDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
