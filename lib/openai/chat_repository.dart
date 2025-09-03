import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String userId) {
    return _db
        .collection("ai_conversations")
        .doc(userId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  Future<void> addMessage(String userId, String content, String role) async {
    await _db
        .collection("ai_conversations")
        .doc(userId)
        .collection("messages")
        .add({
          "content": content,
          "role": role,
          "timestamp": FieldValue.serverTimestamp(),
        });
  }
}
