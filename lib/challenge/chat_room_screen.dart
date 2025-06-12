  import 'dart:io';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:firebase_storage/firebase_storage.dart';
  import 'package:flutter/material.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:intl/intl.dart';
  import 'package:uuid/uuid.dart';

  class ChatRoomScreen extends StatefulWidget {
    final String challengeId;
    const ChatRoomScreen({Key? key, required this.challengeId}) : super(key: key);

    @override
    State<ChatRoomScreen> createState() => _ChatRoomScreenState();
  }

  class _ChatRoomScreenState extends State<ChatRoomScreen> {
    final TextEditingController _messageController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final picker = ImagePicker();
  final uuid = Uuid();


  File? _selectedImage;
  String? _replyToCommentId;
  String? _replyingToNickname;

  // 답글을 달기 위한 텍스트 필드를 업데이트하는 로직
  void _startReplying(String commentId, String nickname) {
    setState(() {
      _replyToCommentId = commentId;
      _replyingToNickname = nickname; // 답글을 다는 댓글의 닉네임을 저장
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyingToNickname = null; // 답글 취소
    });
  }

  String decodeEmail(String encodedEmail) {
    return encodedEmail.replaceAll('_at_', '@').replaceAll('_dot_', '.');
  }

  Future<String> _getNickname(String email) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(email).get();
    if (doc.exists) {
      return doc['nickname'] ?? '알 수 없음';
    }
    return '알 수 없음';
  }

  Future<String> _getProfileImageUrl(String email) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(email).get();
    if (doc.exists) {
      return doc['profileImageUrl'] ?? '';
    }
    return '';
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String docId) async {
    if (_selectedImage == null) return null;
    final ref = FirebaseStorage.instance.ref().child('chat_images').child('$docId.jpg');
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _sendMessage() async {
    final message = _replyController.text.trim(); // ✅ 수정됨
    if (message.isEmpty && _selectedImage == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final encodedEmail = user.email!.replaceAll('.', '_dot_').replaceAll('@', '_at_');
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.email!).get();

    final userName = userDoc.exists ? userDoc['nickname'] ?? '알 수 없음' : '알 수 없음';
    final userEmail = user.email!;
    final docId = "${userEmail}_${DateTime.now().millisecondsSinceEpoch}_${uuid.v4()}";

    final imageUrl = await _uploadImage(docId) ?? '';

    await FirebaseFirestore.instance
        .collection('challenges')
        .doc(widget.challengeId)
        .collection('comments')
        .doc(docId)
        .set({
      'comment': message,
      'timestamp': FieldValue.serverTimestamp(),
      'userName': userName,
      'userEmail': userEmail,
      'imageUrl': imageUrl,
      'replyTo': null,
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'comment',
      'challengeId': widget.challengeId,
      'userEmail': userEmail,
      'userName': userName,
      'message': message,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _replyController.clear(); // ✅ 여기서도 replyController를 비움
    setState(() {
      _selectedImage = null;
    });
    _scrollToBottom();
  }



  Future<void> _sendReply(String commentId) async {
    final replyMessage = _replyController.text.trim();
    if (replyMessage.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final encodedEmail = user.email!.replaceAll('.', '_dot_').replaceAll('@', '_at_');
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.email!).get();

    final userName = userDoc.exists ? userDoc['nickname'] ?? '알 수 없음' : '알 수 없음';
    final userEmail = user.email!;
    final docId = "${userEmail}_${DateTime.now().millisecondsSinceEpoch}_${uuid.v4()}";
    final imageUrl = await _uploadImage(docId);

    // Firestore에 답글 추가 (replies 서브 컬렉션에 저장)
    await FirebaseFirestore.instance
        .collection('challenges')
        .doc(widget.challengeId)
        .collection('comments')
        .doc(commentId) // 부모 댓글 ID
        .collection('replies') // 댓글에 대한 답글을 replies 서브 컬렉션에 저장
        .doc(docId)
        .set({
      'comment': replyMessage,
      'timestamp': FieldValue.serverTimestamp(),
      'userName': userName,
      'userEmail': userEmail,
      'imageUrl': imageUrl,
    });

    // 알림 추가 (답글 알림)
    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'reply',
      'challengeId': widget.challengeId,
      'userEmail': userEmail,
      'userName': userName,
      'message': replyMessage,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'replyToCommentId': commentId, // 답글을 단 댓글 ID 추가
    });

    _replyController.clear();
    setState(() {
      _replyToCommentId = null;
    });
    _scrollToBottom();
  }



    Future<void> _toggleParticipation(bool join, List currentParticipants, DateTime endDate) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userEmail = user.email!;
      final now = DateTime.now();

      // 목표 종료일 전 3일 동안은 참여 취소 불가
      if (endDate.difference(now).inDays <= 3 && !join) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("목표 달성까지 3일 전에는 참여 취소가 불가능합니다."),
          backgroundColor: Colors.red,
        ));
        return;
      }

      if (endDate.difference(now).inDays > 3 && !join) {
        // 3일 전까지는 다이얼로그로 취소 확인
        bool? shouldCancel = await _showCancelDialog();
        if (shouldCancel == null || !shouldCancel) {
          return; // "아니오"를 선택하면 취소하지 않음
        }
      }

      final challengeRef = FirebaseFirestore.instance.collection('challenges').doc(widget.challengeId);
      final doc = await challengeRef.get();
      final data = doc.data() as Map<String, dynamic>;

      List<String> updatedParticipants = List<String>.from(currentParticipants);
      Map<String, dynamic> participantMap = Map<String, dynamic>.from(data['participantMap'] ?? {});
      Map<String, dynamic> participantDistances = Map<String, dynamic>.from(data['participantDistances'] ?? {});

      if (join) {
        if (!updatedParticipants.contains(userEmail)) {
          updatedParticipants.add(userEmail);
          final now = DateTime.now().toUtc().toIso8601String();
          participantMap[userEmail] = now;
          // 거리 데이터 초기화 (새로 참여하는 경우)
          participantDistances[userEmail] = 0;  // 기본값 0, 실제 실행 시에는 사용자 거리로 업데이트 필요
        }
      } else {
        updatedParticipants.remove(userEmail);
        participantMap.remove(userEmail);

        // 참여 취소 시 거리 보정: 이미 기록된 거리 차감
        if (participantDistances.containsKey(userEmail)) {
          // 예시: 취소 시 10% 거리 차감 (조정 가능)
          double originalDistance = participantDistances[userEmail] as double;
          double adjustedDistance = originalDistance * 0.9;  // 10% 차감
          participantDistances[userEmail] = adjustedDistance;

          // 취소 후 거리 데이터 반영
          await challengeRef.update({
            'participantDistances': participantDistances,
          });
        }
      }

      // Firestore 업데이트: 참여자 목록 및 정보 갱신
      await challengeRef.update({
        'participants': updatedParticipants,
        'participantMap': participantMap,
      });
    }

    Future<bool?> _showCancelDialog() async {
      return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white, // 배경 흰색
            title: Text('참여 취소'),
            content: Column(
              mainAxisSize: MainAxisSize.min, // 다이얼로그 높이 최소화
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('참여를 취소하시겠습니까?'),
                SizedBox(height: 8),
                Text(
                  '※ 참여 거리 값이 초기화됩니다.',
                  style: TextStyle(
                    color: Colors.red.shade200, // 연한 빨간색
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // "아니오"
                },
                child: Text(
                  '아니오',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // "예"
                },
                child: Text(
                  '예',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );
    }




    void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy.MM.dd HH:mm').format(date);
  }

  Widget _buildChallengeInfo(DocumentSnapshot challengeDoc) {
    final data = challengeDoc.data() as Map<String, dynamic>;
    final title = data['name'] ?? '제목 없음';
    final targetDistance = double.tryParse(data['distance'] ?? '0') ?? 0;
    final duration = data['duration'] ?? '';
    final slogan = data['slogan'] ?? '🔥 목표를 향해 함께 달려요!';
    final encodedEmail = data['userEmail'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final startDate = timestamp?.toDate() ?? DateTime.now();
    final formattedDate = timestamp != null ? _formatTimestamp(timestamp) : '';
    final userNameFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(decodeEmail(encodedEmail))
        .get();
    final participants = List<String>.from(data['participants'] ?? []);
    final endDate = startDate.add(Duration(days: int.tryParse(duration) ?? 7));
    final now = DateTime.now();
    final daysLeft = endDate.difference(now).inDays;

    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.email == decodeEmail(encodedEmail);
    final hasJoined = currentUser?.email != null && participants.contains(currentUser!.email);


    Future<double> getTotalRunningDistance() async {
      double totalDistance = 0;

      // 참여자가 없으면 0 반환
      if (participants.isEmpty) {
        return totalDistance;
      }

      // participantMap에서 이메일을 그대로 사용
      final participantMap = Map<String, dynamic>.from(data['participantMap'] ?? {});

      // 각 참여자에 대해 처리
      for (String userEmail in participants) {
        // 이메일을 그대로 사용하여 participantMap에서 시간 정보 찾기
        final joinDateTimeStr = participantMap[userEmail];  // 인코딩하지 않음

        if (joinDateTimeStr == null) continue;

        // UTC에서 로컬 시간으로 변환
        DateTime startDateTime = DateTime.tryParse(joinDateTimeStr)?.toLocal() ?? now;
        DateTime startDate = DateTime(startDateTime.year, startDateTime.month, startDateTime.day, startDateTime.hour, startDateTime.minute);
        DateTime currentDate = startDate;

        // 현재 날짜와 시간 이후의 데이터를 계산하기 위해서
        List<String> dateRange = [];

        // startDate부터 현재 날짜 및 시간까지 날짜 범위 생성
        while (currentDate.isBefore(now)) {  // 시간을 정확히 포함
          dateRange.add(DateFormat('yyyy-MM-dd').format(currentDate));
          currentDate = currentDate.add(Duration(days: 1)); // 날짜가 넘어갈 때마다 추가
        }

        // 각 날짜에 대해 데이터를 조회
        for (String date in dateRange) {
          try {
            QuerySnapshot recordsSnapshot = await FirebaseFirestore.instance
                .collection('userRunningData')
                .doc(userEmail) // 원래 이메일 그대로 사용
                .collection('workouts')
                .doc(date)
                .collection('records')
                .get();

            for (var doc in recordsSnapshot.docs) {
              Map<String, dynamic> recordData = doc.data() as Map<String, dynamic>;
              double distance = 0;
              var distanceData = recordData['kilometers'];
              var timestamp = recordData['timestamp'];  // 시간 정보

              // timestamp가 없다면 해당 기록을 건너뛰기
              if (timestamp != null) {
                DateTime recordTime = (timestamp is Timestamp)
                    ? timestamp.toDate()
                    : DateTime.tryParse(timestamp.toString()) ?? DateTime.now();

                // 기록이 참여자 시작 이후의 시간에 해당하는지 체크
                if (recordTime.isAfter(startDate)) {
                  if (distanceData is double) {
                    distance = distanceData;
                  } else if (distanceData is int) {
                    distance = distanceData.toDouble();
                  } else {
                    distance = double.tryParse(distanceData.toString()) ?? 0;
                  }

                  totalDistance += distance;
                }
              }
            }
          } catch (e) {
            print('Error fetching $userEmail\'s data on $date: $e');
          }
        }
      }

      print('Final total distance: $totalDistance km');

      // 목표 거리 기준 달성률 계산 (0.0 ~ 1.0 사이 값)
      final distanceProgress = (targetDistance > 0)
          ? (totalDistance / targetDistance).clamp(0.0, 1.0)
          : 0.0;

      // Firestore에 progress 저장
      await FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challengeId)
          .update({'progress': distanceProgress});

      return totalDistance;
    }



    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        userNameFuture,
        getTotalRunningDistance(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: EdgeInsets.all(16),
            color: Colors.blue[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // 데이터 로드 중 오류 발생 시
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Card(
            margin: EdgeInsets.all(16),
            color: Colors.red[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('데이터 로딩 중 오류가 발생했습니다'),
            ),
          );
        }

        // 사용자 정보와 총 달린 거리 데이터
        final userDoc = snapshot.data?[0] as DocumentSnapshot?;
        final totalDistance = snapshot.data?[1] as double? ?? 0;

        final writer = userDoc != null && userDoc.exists
            ? userDoc['nickname'] ?? '알 수 없음'
            : '알 수 없음';

        // 목표 거리 대비 진행률 계산
        final distanceProgress = (targetDistance > 0) ? (totalDistance / targetDistance).clamp(0.0, 1.0) : 0.0;

        return Card(
          margin: EdgeInsets.all(16),
          color: Colors.blue[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    if (isOwner)
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: Text('삭제 확인'),
                              content: Text('정말로 이 챌린지를 삭제하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('취소', style: TextStyle(color: Colors.blue)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('삭제', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await FirebaseFirestore.instance
                                .collection('challenges')
                                .doc(widget.challengeId)
                                .delete();
                            Navigator.pop(context); // 삭제 후 이전 화면으로 이동
                          }
                        },
                      ),
                  ],
                ),
                SizedBox(height: 10),
                Text("🎯 $slogan", style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text("🏁 목표 거리: $targetDistance km", style: TextStyle(fontSize: 15)),
                Text("⏱️ 기간: $duration일", style: TextStyle(fontSize: 15)),
                SizedBox(height: 8),

// 거리 기반 진행률
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🏃 달성 거리: ${totalDistance.toStringAsFixed(2)}/${targetDistance.toStringAsFixed(2)} km (${(distanceProgress * 100).toStringAsFixed(1)}%)",
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    // 진행률이 100%일 경우 다른 메시지 표시
                    if (distanceProgress == 1.0)
                      Text(
                        "🎉 목표 달성! 축하합니다!",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                      )
                    else
                    // 진행률이 100%가 아니면 진행률 바 표시
                      LinearProgressIndicator(
                        value: distanceProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                  ],
                ),


                SizedBox(height: 8),
                Text("⏳ 남은 기간: ${daysLeft >= 0 ? '$daysLeft일' : '완료됨'}"),
                SizedBox(height: 4),
                Text(
                  '⚠ 종료 3일 전에는 참여 취소가 불가능합니다 ⚠',
                  style: TextStyle(
                    fontSize: 12, // 작은 글씨
                    color: Colors.red.shade400, // 연한 빨간색
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("👥 참여 인원: ${participants.length}명"),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasJoined ? Colors.white : Colors.blueAccent,
                        foregroundColor: hasJoined ? Colors.redAccent : Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _toggleParticipation(!hasJoined, participants, endDate),
                      child: Text(hasJoined ? '참여 취소' : '참여하기'),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("글쓴이: $writer", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(formattedDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComment(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final comment = data['comment'] ?? '';
    final userEmail = data['userEmail'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final imageUrl = data['imageUrl'];
    final timeText = timestamp != null ? _formatTimestamp(timestamp) : '';
    final isMyComment = FirebaseAuth.instance.currentUser?.email == userEmail;

    return FutureBuilder<String>(
      future: _getNickname(userEmail),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? '알 수 없음';

        return FutureBuilder<String>(
          future: _getProfileImageUrl(userEmail),
          builder: (context, profileSnapshot) {
            final profileImageUrl = profileSnapshot.data ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (profileImageUrl.isNotEmpty)
                        CircleAvatar(
                          backgroundImage: NetworkImage(profileImageUrl),
                          radius: 16,
                        ),
                      SizedBox(width: 8),
                      Text(
                        userName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                      ),
                      Spacer(),
                      if (isMyComment)
                        GestureDetector(
                          onTap: () async {
                            await FirebaseFirestore.instance
                                .collection('challenges')
                                .doc(widget.challengeId)
                                .collection('comments')
                                .doc(doc.id)
                                .delete();
                          },
                          child: Icon(Icons.delete, size: 18, color: Colors.red),
                        ),
                      if (!isMyComment)
                        GestureDetector(
                          onTap: () {
                            _startReplying(doc.id, userName); // 답글 입력 상태로 변경
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(Icons.reply, size: 18, color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6),
                  // 이미지 URL이 존재할 때만 이미지를 표시
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                  if (imageUrl != null && imageUrl.isNotEmpty) SizedBox(height: 8),
                  if (comment.isNotEmpty)
                    Text(comment, style: TextStyle(fontSize: 15, height: 1.4)),
                  SizedBox(height: 6),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(timeText, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ),
                  Divider(height: 24, thickness: 0.5, color: Colors.grey[300]),

                  // 답글 처리
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('challenges')
                        .doc(widget.challengeId)
                        .collection('comments')
                        .doc(doc.id)
                        .collection('replies')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, replySnapshot) {
                      if (replySnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (replySnapshot.hasError) {
                        return Center(child: Text("답글을 불러오는 중 오류가 발생했습니다"));
                      }

                      final replies = replySnapshot.data?.docs ?? [];
                      List<Widget> replyWidgets = [];

                      for (var reply in replies) {
                        replyWidgets.add(_buildComment(reply)); // 답글도 댓글처럼 처리
                      }

                      return Column(
                        children: replyWidgets,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false, // 키보드에 의해 레이아웃을 자동으로 조정하지 않도록 설정
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Image.asset('assets/images/Back-Navs.png', width: 70, height: 70),
            onPressed: () => Navigator.pop(context),
            padding: const EdgeInsets.only(left: 8),
          ),
          title: Text("챌린지",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        body: SafeArea(
          child: SingleChildScrollView( // ScrollView로 전체를 감싸서 키보드에 의해 내용이 밀리지 않도록 처리
            child: Column(
              children: [
                // 챌린지 정보 및 댓글 목록
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('challenges')
                      .doc(widget.challengeId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("오류가 발생했습니다"));
                    }

                    final challengeDoc = snapshot.data;

                    return Column(
                      children: [
                        if (challengeDoc != null) _buildChallengeInfo(challengeDoc),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('challenges')
                              .doc(widget.challengeId)
                              .collection('comments')
                              .orderBy('timestamp', descending: false)
                              .snapshots(),
                          builder: (context, commentSnapshot) {
                            if (commentSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (commentSnapshot.hasError) {
                              return Center(child: Text("댓글을 불러오는 중 오류가 발생했습니다"));
                            }

                            final allDocs = commentSnapshot.data?.docs ?? [];

                            // 댓글을 트리 구조로 변환
                            Map<String?, List<DocumentSnapshot>> commentTree = {};
                            for (var doc in allDocs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final replyTo = data['replyTo'];
                              if (!commentTree.containsKey(replyTo)) {
                                commentTree[replyTo] = [];
                              }
                              commentTree[replyTo]!.add(doc);
                            }

                            List<Widget> buildNestedComments(String? parentId, int indent) {
                              final comments = commentTree[parentId] ?? [];
                              List<Widget> widgets = [];

                              for (var comment in comments) {
                                widgets.add(
                                  Padding(
                                    padding: EdgeInsets.only(left: 16.0 * indent),
                                    child: _buildComment(comment),
                                  ),
                                );
                                widgets.addAll(buildNestedComments(comment.id, indent + 1));
                              }

                              return widgets;
                            }

                            final nestedCommentWidgets = buildNestedComments(null, 0);

                            return ListView(
                              controller: _scrollController,
                              shrinkWrap: true, // 스크롤뷰 내에서만 화면을 밀도록 설정
                              padding: const EdgeInsets.only(bottom: 80),
                              children: nestedCommentWidgets,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // 키보드 높이만큼 패딩을 주어서 키보드 위로 필드를 올림
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_replyToCommentId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text("답글을 달고 있습니다. ", style: TextStyle(fontSize: 14)),
                      Text(
                        '($_replyingToNickname)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.blue),
                        onPressed: _cancelReply,
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: InputDecoration(
                          hintText: _replyToCommentId != null
                              ? "답글을 입력하세요..."
                              : "댓글을 입력하세요...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, size: 28, color: Colors.blue),
                      onPressed: () {
                        if (_replyToCommentId != null) {
                          _sendReply(_replyToCommentId!);
                        } else {
                          _sendMessage();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }


  }
