import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:work/challenge/FreeTalk_Chat_Screen.dart';
import 'package:work/challenge/challenge_screen/navigation_bar.dart' as custom;
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_screen.dart';
import 'components/challenge_form.dart';
import 'free_talk_form.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({Key? key}) : super(key: key);

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFreeTalkTabSelected = false;

  Future<Map<String, dynamic>> _getUserInfo(String encodedEmail) async {
    try {
      String decodedEmail =
      encodedEmail.replaceAll('_at_', '@').replaceAll('_dot_', '.');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(decodedEmail)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        return {
          'nickname': data['nickname'] ?? '익명',
          'profileImageUrl': data['profileImageUrl'] ?? '',
        };
      }
    } catch (e) {
      print("사용자 정보 가져오기 실패: $e");
    }
    return {'nickname': '익명', 'profileImageUrl': ''};
  }

  Future<int> _getLikeCount(String postId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('freeTalks')
        .doc(postId)
        .collection('likes')
        .get();
    return snapshot.size;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isFreeTalkTabSelected = _tabController.index == 1;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 챌린지 게시물 빌드
  Widget _buildChallengePost(
      DocumentSnapshot challenge, String nickname, String profileImageUrl, BuildContext context) {
    final challengeId = challenge.id;
    final String title = challenge['name'] ?? '제목 없음';
    final String subtitle =
        "기간: ${challenge['duration']} | 거리: ${challenge['distance']}";
    final String time = (challenge['timestamp'] as Timestamp?)
        ?.toDate()
        .toLocal()
        .toString()
        .substring(0, 16) ??
        "날짜 없음";

    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(challengeId: challengeId)),
            );
          },
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey[300],
                      child: profileImageUrl.isNotEmpty
                          ? null
                          : Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(nickname,
                        style:
                        TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(time,
                        style:
                        TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 0.5, color: Colors.grey[300]),
      ],
    );
  }

  // 자유게시판 게시물 빌드
  Widget _buildFreeTalkPost(DocumentSnapshot post, String nickname,
      String profileImageUrl, int likeCount) {
    final data = post.data() as Map<String, dynamic>;
    final String title = data['title'] ?? '제목 없음';
    final String content = data['content'] ?? '';
    final String time = (data['timestamp'] as Timestamp?)
        ?.toDate()
        .toLocal()
        .toString()
        .substring(0, 16) ??
        "날짜 없음";
    final String imageUrl = data.containsKey('imageUrl')
        ? data['imageUrl'] ?? ''
        : '';

    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FreeTalkDetailScreen(
                  postId: post.id,
                  nickname: nickname,
                  title: title,
                  content: content,
                  timestamp: data['timestamp'],
                  postAuthorEmail: data['userEmail'],
                  imageUrl: imageUrl,
                ),
              ),
            );
          },
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(content,
                    style: const TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey[300],
                      child: profileImageUrl.isNotEmpty
                          ? null
                          : Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(nickname,
                        style:
                        TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(time,
                        style:
                        TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(width: 8),
                    const Icon(Icons.thumb_up, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('$likeCount',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    if (imageUrl.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.image, size: 14, color: Colors.grey),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 0.5, color: Colors.grey[300]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const custom.NavigationBar(),
              TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                indicatorColor: Colors.black,
                tabs: const [
                  Tab(text: "챌린지"),
                  Tab(text: "자유게시판"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('challenges')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data!.docs;
                        return ListView(
                          children: [
                            ...docs.map((doc) {
                              return FutureBuilder<Map<String, dynamic>>(
                                future: _getUserInfo(doc['userEmail']),
                                builder: (context, snapshot) {
                                  final nickname =
                                      snapshot.data?['nickname'] ?? '익명';
                                  final profileImageUrl =
                                      snapshot.data?['profileImageUrl'] ?? '';
                                  return _buildChallengePost(
                                      doc, nickname, profileImageUrl, context);
                                },
                              );
                            }).toList(),
                            const SizedBox(height: 80),
                          ],
                        );
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('freeTalks')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data!.docs;
                        return ListView(
                          children: [
                            ...docs.map((doc) {
                              return FutureBuilder<Map<String, dynamic>>(
                                future: _getUserInfo(doc['userEmail']),
                                builder: (context, userSnap) {
                                  final nickname =
                                      userSnap.data?['nickname'] ?? '익명';
                                  final profileImageUrl =
                                      userSnap.data?['profileImageUrl'] ?? '';
                                  return FutureBuilder<int>(
                                    future: _getLikeCount(doc.id),
                                    builder: (context, likeSnap) {
                                      final likeCount = likeSnap.data ?? 0;
                                      return _buildFreeTalkPost(
                                          doc, nickname, profileImageUrl, likeCount);
                                    },
                                  );
                                },
                              );
                            }).toList(),
                            const SizedBox(height: 80),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        floatingActionButton: _isFreeTalkTabSelected
            ? FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const FreeTalkForm()),
            );
          },
          label: const Text("글쓰기"),
          icon: const Icon(Icons.edit),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        )
            : null,
        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}