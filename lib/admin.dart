  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';

  class AdminScreen extends StatelessWidget {
    final CollectionReference users =
    FirebaseFirestore.instance.collection('users');

    // 계정 삭제 함수
    Future<void> _deleteUser(BuildContext context, String uid) async {
      try {
        await users.doc(uid).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("계정이 삭제되었습니다")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("삭제 오류: $e")),
        );
      }
    }

    // 전체 계정 삭제 경고창
    void _showDeleteAllDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("전체 계정 삭제"),
          content: Text("정말 모든 계정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다."),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAllUsers(context);
              },
              child: Text("삭제"),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );
    }

    // 전체 계정 삭제
    Future<void> _deleteAllUsers(BuildContext context) async {
      try {
        final QuerySnapshot snapshot = await users.get();
        final List<DocumentSnapshot> docs = snapshot.docs;

        for (var doc in docs) {
          await doc.reference.delete();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("모든 계정이 삭제되었습니다")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("전체 삭제 실패: $e")),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text("관리자 모드"),
          backgroundColor: Colors.redAccent,
          actions: [
            IconButton(
              icon: Icon(Icons.delete_forever),
              onPressed: () => _showDeleteAllDialog(context),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                "사용자 목록",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: users.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("데이터 로드 실패: ${snapshot.error}"));
                    }

                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final List<DocumentSnapshot> documents = snapshot.data!.docs;

                    if (documents.isEmpty) {
                      return Center(child: Text("등록된 사용자가 없습니다."));
                    }

                    return ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final DocumentSnapshot document = documents[index];
                        final data = document.data() as Map<String, dynamic>;
                        final String email = data['email'] ?? "이메일 없음";
                        final String uid = data['uid'] ?? document.id;

                        return ListTile(
                          title: Text(email),
                          subtitle: Text("UID: $uid"),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(context, document.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }