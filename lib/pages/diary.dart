import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/nav.dart';

//
enum Mood { veryHappy, calm, neutral, sad, verySad }

const _moodEmoji = {
  Mood.veryHappy: '😊',
  Mood.calm: '😌',
  Mood.neutral: '😐',
  Mood.sad: '☹️',
  Mood.verySad: '😢',
};

class Diary extends StatefulWidget {
  const Diary({super.key});
  @override
  State<Diary> createState() => _DiaryState();
}

class _DiaryState extends State<Diary> {
  final _ctrl = TextEditingController();
  bool _saving = false;
  Mood _selected = Mood.veryHappy; // 默认选中

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('moods');
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _selected == Mood.neutral) {
      // 可按需改：什么都没写且就是默认心情时不保存
    }

    setState(() => _saving = true);
    await _col.add({
      'text': text,
      'mood': _selected.name, // 👈 保存心情
      'ts': FieldValue.serverTimestamp(), // 服务器时间
    });
    _ctrl.clear();
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to Firebase')));
    }
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MoodHistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFD9FB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mood Diary',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: _openHistory,
            icon: const Icon(Icons.history, color: Colors.black87),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              // ====== 心情选择条（在输入框上方）======
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: Mood.values.map((m) {
                    final selected = m == _selected;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? const Color(0xFFEFF6FF)
                              : Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF3B82F6)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _moodEmoji[m]!,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ====== 卡片样式输入框 ======
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: TextField(
                  controller: _ctrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'You can type something......',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ====== 保存按钮 ======
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Save today's mood"),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Stored in Firebase (Firestore). Tap History to view previous records.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Nav(),
    );
  }
}

// =================== 历史页 ===================

class MoodHistoryPage extends StatelessWidget {
  const MoodHistoryPage({super.key});

  CollectionReference<Map<String, dynamic>> _col() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('moods');
  }

  Future<void> _clearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all records?'),
        content: const Text('This deletes all moods for this user.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final batch = FirebaseFirestore.instance.batch();
      final qs = await _col().get();
      for (final d in qs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _col().orderBy('ts', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFBFD9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFD9FB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'History',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () => _clearAll(context),
            icon: const Icon(Icons.delete_forever, color: Colors.black87),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No records yet'));
          }

          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final m = docs[i].data();
              final ts = (m['ts'] as Timestamp?)?.toDate();
              final text = (m['text'] as String?) ?? '';
              final moodName = (m['mood'] as String?) ?? Mood.neutral.name;
              final mood = Mood.values.firstWhere(
                (e) => e.name == moodName,
                orElse: () => Mood.neutral,
              );

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧表情
                    Text(
                      _moodEmoji[mood]!,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                    // 右侧文字
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ts != null)
                            Text(
                              _fmt(ts),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            text.isEmpty ? '(No text)' : text,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(DateTime ts) {
    final d = ts.toLocal();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}  ${_two(d.hour)}:${_two(d.minute)}';
  }

  String _two(int x) => x.toString().padLeft(2, '0');
}
