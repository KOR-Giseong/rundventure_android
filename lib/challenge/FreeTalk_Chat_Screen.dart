

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FreeTalkDetailScreen extends StatefulWidget {
  final String postId;
  final String nickname;
  final String title;
  final String content;
  final Timestamp timestamp;
  final String postAuthorEmail;
  final String? imageUrl;

  const FreeTalkDetailScreen({
    Key? key,
    required this.postId,
    required this.nickname,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.postAuthorEmail,
    this.imageUrl,

  }) : super(key: key);

  @override
  State<FreeTalkDetailScreen> createState() => _FreeTalkDetailScreenState();
}

class _FreeTalkDetailScreenState extends State<FreeTalkDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool isAnonymous = true;
  String? nickname;
  String? postAuthorProfileImageUrl;
  bool hasLiked = false;
  bool hasDisliked = false;
  int likeCount = 0;
  int dislikeCount = 0;
  String? replyingToCommentId;
  String? replyingToNickname;
  bool isImageExpanded = false;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _loadPostAuthorProfileImage();
    _loadLikeDislikeState();
  }

  // 이미지 클릭 시 원본 크기와 설정된 크기 간에 전환
  void _toggleImageSize() {
    setState(() {
      isImageExpanded = !isImageExpanded; // 상태를 반전시켜서 크기를 전환
    });
  }

  List<DocumentSnapshot> _getNestedReplies(String parentId, List<DocumentSnapshot> allReplies) {
    List<DocumentSnapshot> nestedReplies = [];

    // 주어진 parentId에 해당하는 대댓글들을 찾고, 재귀적으로 자식 댓글을 찾아냄
    for (var reply in allReplies) {
      final replyData = reply.data() as Map<String, dynamic>;
      if (replyData['parentId'] == parentId) {
        nestedReplies.add(reply);
        // 자식 대댓글도 확인
        nestedReplies.addAll(_getNestedReplies(reply.id, allReplies));
      }
    }

    return nestedReplies;
  }


  Future<void> _loadNickname() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.email).get();
    setState(() {
      nickname = doc.data()?['nickname'] ?? '익명';
    });
  }

  Future<void> _loadPostAuthorProfileImage() async {
    final postAuthorEmail = widget.postAuthorEmail;
    final userInfo = await _getUserInfo(postAuthorEmail);

    setState(() {
      postAuthorProfileImageUrl = userInfo['profileImageUrl'];
    });
  }

  Future<Map<String, String>> _getUserInfo(String encodedEmail) async {
    try {
      String decodedEmail = encodedEmail.replaceAll('_at_', '@').replaceAll('_dot_', '.');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(decodedEmail).get();
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

  // 예시 코드: 댓글 제출 시 이미지 URL 포함
  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (commentText.isEmpty || user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.email).get();
    final userNickname = userDoc.exists ? userDoc['nickname'] ?? '익명' : '익명';

    // 사진 URL (이미 업로드된 URL을 가져온다고 가정)
    String imageUrl = '이미지_URL_여기';

    await FirebaseFirestore.instance
        .collection('freeTalks')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'userEmail': user.email,
      'isAnonymous': isAnonymous,
      'nickname': isAnonymous ? '익명' : userNickname,
      'content': commentText,
      'timestamp': FieldValue.serverTimestamp(),
      'parentId': replyingToCommentId,
      'imageUrl': imageUrl,  // 이미지 URL 저장
    });

    setState(() {
      replyingToCommentId = null;
      replyingToNickname = null;
    });

    _commentController.clear();
  }


  Future<void> _loadLikeDislikeState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email!;
    final postRef = FirebaseFirestore.instance.collection('freeTalks').doc(widget.postId);

    final likeSnap = await postRef.collection('likes').doc(email).get();
    final dislikeSnap = await postRef.collection('dislikes').doc(email).get();

    final likeCountSnap = await postRef.collection('likes').get();
    final dislikeCountSnap = await postRef.collection('dislikes').get();

    setState(() {
      hasLiked = likeSnap.exists;
      hasDisliked = dislikeSnap.exists;
      likeCount = likeCountSnap.size;
      dislikeCount = dislikeCountSnap.size;
    });
  }

  Future<void> _handleLikeDislike(bool isLike) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email!;
    final postRef = FirebaseFirestore.instance.collection('freeTalks').doc(widget.postId);

    final likeDoc = postRef.collection('likes').doc(email);
    final dislikeDoc = postRef.collection('dislikes').doc(email);

    final likeSnap = await likeDoc.get();
    final dislikeSnap = await dislikeDoc.get();

    if (isLike) {
      if (likeSnap.exists) {
        await likeDoc.delete();
      } else {
        await likeDoc.set({
          'userEmail': email,
          'timestamp': FieldValue.serverTimestamp(),
        });
        if (dislikeSnap.exists) await dislikeDoc.delete();
      }
    } else {
      if (dislikeSnap.exists) {
        await dislikeDoc.delete();
      } else {
        await dislikeDoc.set({
          'userEmail': email,
          'timestamp': FieldValue.serverTimestamp(),
        });
        if (likeSnap.exists) await likeDoc.delete();
      }
    }

    await _loadLikeDislikeState();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dt = timestamp.toDate();
    return DateFormat('MM/dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final postRef = FirebaseFirestore.instance.collection('freeTalks').doc(widget.postId);
    final commentsRef = postRef.collection('comments');
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    final decodedPostAuthorEmail = widget.postAuthorEmail.replaceAll('_at_', '@').replaceAll('_dot_', '.');
    final isPostAuthor = currentUserEmail == decodedPostAuthorEmail;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('자유게시판', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset('assets/images/Back-Navs.png', width: 70, height: 70),
          onPressed: () => Navigator.of(context).pop(),
          padding: const EdgeInsets.only(left: 8),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: Column(  // Column으로 전체를 감싸고
        children: [
          Expanded(  // Expanded로 본문과 댓글 영역을 스크롤되게 처리
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 게시물 본문
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (postAuthorProfileImageUrl != null && postAuthorProfileImageUrl!.isNotEmpty)
                              Image.network(
                                postAuthorProfileImageUrl!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const CircleAvatar(radius: 16, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white, size: 18));
                                },
                              )
                            else
                              const CircleAvatar(radius: 16, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white, size: 18)),
                            const SizedBox(width: 8),
                            Text(widget.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_formatTimestamp(widget.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 12),
                        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 6),
                        Text(widget.content, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 12),
                        // ✅ 이미지가 있을 경우 표시
                        if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isExpanded = !isExpanded;  // 이미지를 클릭할 때마다 크기를 변경
                                });
                              },
                              child: InteractiveViewer(
                                panEnabled: true,  // 이미지를 드래그하여 이동 가능
                                boundaryMargin: EdgeInsets.all(20),
                                minScale: 0.1,
                                maxScale: isExpanded ? 3.0 : 1.0,  // isExpanded에 따라 최대 크기를 조절
                                child: Image.network(
                                  widget.imageUrl!,
                                  fit: BoxFit.contain, // 이미지를 축소하거나 확대할 때 비율 유지
                                  width: isExpanded ? double.infinity : 450, // 확대 시 원본 크기로 변경
                                  height: isExpanded ? double.infinity : 450, // 확대 시 원본 크기로 변경
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Text('이미지를 불러올 수 없습니다', style: TextStyle(color: Colors.grey));
                                  },
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.thumb_up, color: hasLiked ? Colors.red : Colors.grey),
                                  onPressed: () => _handleLikeDislike(true),
                                ),
                                Text('$likeCount'),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: Icon(Icons.thumb_down, color: hasDisliked ? Colors.blue : Colors.grey),
                                  onPressed: () => _handleLikeDislike(false),
                                ),
                                Text('$dislikeCount'),
                              ],
                            ),
                            if (isPostAuthor)
                              GestureDetector(
                                onTap: () async {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: const Text('게시물 삭제'),
                                      content: const Text('정말 이 게시물을 삭제하시겠습니까?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (shouldDelete == true) {
                                    await FirebaseFirestore.instance.collection('freeTalks').doc(widget.postId).delete();
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // 댓글 및 대댓글 리스트
                  StreamBuilder<QuerySnapshot>(
                    stream: commentsRef.orderBy('timestamp').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allComments = snapshot.data!.docs;

                      // 데이터를 확인하기 위한 로그
                      print("All Comments: ${allComments.map((doc) => doc.data()).toList()}");

                      // 부모 댓글과 대댓글을 나누기
                      final parentComments = allComments.where((doc) => (doc.data() as Map<String, dynamic>)['parentId'] == null).toList();
                      final replyComments = allComments.where((doc) => (doc.data() as Map<String, dynamic>)['parentId'] != null).toList();

                      // 부모 댓글 로그
                      print("Parent Comments: ${parentComments.map((doc) => doc.data()).toList()}");
                      // 대댓글 로그
                      print("Reply Comments: ${replyComments.map((doc) => doc.data()).toList()}");

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shrinkWrap: true,  // 내용에 맞게 크기 조절
                        physics: const NeverScrollableScrollPhysics(),  // 스크롤 비활성화
                        itemCount: parentComments.length,
                        itemBuilder: (context, index) {
                          final parent = parentComments[index];
                          final parentData = parent.data() as Map<String, dynamic>;
                          final parentId = parent.id;

                          // 부모 댓글 아래에 달린 대댓글 찾기
                          final children = _getNestedReplies(parentId, replyComments);

                          // 부모 댓글 + 대댓글 표시
                          return Column(
                            children: [
                              _buildCommentItem(parent, parentData, commentsRef),
                              // 대댓글을 중첩 표시
                              for (final reply in children)
                                Padding(
                                  padding: const EdgeInsets.only(left: 30), // 대댓글 들여쓰기
                                  child: _buildCommentItem(reply, reply.data() as Map<String, dynamic>, commentsRef),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                ],
              ),
            ),
          ),
          // 댓글 입력창을 화면 하단에 고정
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (replyingToCommentId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Text("답글을 달고 있습니다. "),
                          Text(
                            '(${replyingToNickname ?? "알 수 없음"})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                replyingToCommentId = null;
                                replyingToNickname = null; // 답글을 취소할 때 닉네임도 초기화
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isAnonymous = !isAnonymous;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(isAnonymous ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.red),
                            const SizedBox(width: 4),
                            const Text('익명'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: replyingToCommentId == null ? '댓글을 입력하세요...' : '답글을 입력하세요...',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _submitComment,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  }

  // 답글 달려는 댓글의 닉네임을 가져오는 함수
  void _setReplyingToNickname(String commentId) async {
    final commentsRef = FirebaseFirestore.instance.collection('freeTalks').doc(widget.postId).collection('comments');
    final commentSnapshot = await commentsRef.doc(commentId).get();

    if (commentSnapshot.exists) {
      final commentData = commentSnapshot.data() as Map<String, dynamic>;
      setState(() {
        replyingToNickname = commentData['nickname'];
      });
    }
  }

  // 댓글을 클릭할 때 호출하는 함수 (답글 달려고 할 때)
  void _startReply(String commentId) {
    setState(() {
      replyingToCommentId = commentId;
      _setReplyingToNickname(commentId); // 댓글 닉네임 설정
    });
  }


  Widget _buildCommentItem(DocumentSnapshot doc, Map<String, dynamic> data, CollectionReference commentsRef) {
    final timestamp = (data['timestamp'] is Timestamp) ? data['timestamp'] as Timestamp : Timestamp.now();
    final commentEmail = data['userEmail'];
    final isAnonymousComment = data['isAnonymous'] == true;
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    final isAuthor = commentEmail == widget.postAuthorEmail;
    final isMyComment = commentEmail == currentUserEmail;
    final commentNickname = data['nickname'] ?? '익명';
    final displayName = isAnonymousComment ? '익명' : commentNickname;
    final fullName = isAuthor ? '$displayName (글쓴이)' : displayName;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(commentEmail).get(),
      builder: (context, snapshot) {
        String profileImageUrl = '';
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          profileImageUrl = userData['profileImageUrl'] ?? '';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isAnonymousComment || profileImageUrl.isEmpty)
                      const CircleAvatar(radius: 16, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white, size: 18))
                    else
                      CircleAvatar(radius: 16, backgroundImage: NetworkImage(profileImageUrl), backgroundColor: Colors.transparent),
                    const SizedBox(width: 8),
                    Text(fullName, style: TextStyle(fontWeight: FontWeight.bold, color: isAuthor ? Colors.cyan : Colors.black)),
                    const Spacer(),
                    if (isMyComment)
                      GestureDetector(
                        onTap: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: const Text('댓글 삭제'),
                              content: const Text('정말 이 댓글을 삭제하시겠습니까?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (shouldDelete == true) {
                            await commentsRef.doc(doc.id).delete();
                          }
                        },
                        child: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                      ),
                    if (!isMyComment)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            replyingToCommentId = doc.id;
                            replyingToNickname = data['nickname'];
                          });
                          FocusScope.of(context).requestFocus(FocusNode()); // 키보드 포커스 해제
                          Future.delayed(const Duration(milliseconds: 100), () {
                            FocusScope.of(context).requestFocus(FocusNode()); // 한번 더 시도
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.reply, color: Colors.grey, size: 20),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(data['content'] ?? ''),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(_formatTimestamp(timestamp), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
