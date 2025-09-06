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

  Future<void> addMessage(String userId, String text, String role) async {
    await _db
        .collection("ai_conversations")
        .doc(userId)
        .collection("messages")
        .add({
          "text": text,
          "role": role, //"user" or "assistant"
          "timestamp": FieldValue.serverTimestamp(),
        });
  }

  Future<void> updateSummary(String userId, String summary) async {
    await _db.collection("ai_conversations").doc(userId).set({
      "summary": summary,
    }, SetOptions(merge: true));
  }

  Future<String?> getSummary(String userId) async {
    final doc = await _db.collection("ai_conversations").doc(userId).get();
    return doc.data()?["summary"] as String?;
  }

  Future<int> getMessageCount(String userId) async {
    final snapshot = await _db
        .collection("ai_conversations")
        .doc(userId)
        .collection("messages")
        .get();

    return snapshot.docs.length;
  }

  Future<List<String>> getRecentMessages(
    String userId, {
    int limit = 20,
  }) async {
    final snapshot = await _db
        .collection("ai_conversations")
        .doc(userId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => "${doc['role']}: ${doc['text']}")
        .toList()
        .reversed
        .toList();
  }
}
