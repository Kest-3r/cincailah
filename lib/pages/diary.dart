// lib/pages/diary.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/nav.dart';

class Diary extends StatefulWidget {
  const Diary({super.key});
  @override
  State<Diary> createState() => _DiaryState();
}

enum Mood { veryHappy, calm, neutral, sad, verySad }

const _moodEmoji = {
  Mood.veryHappy: '😊',
  Mood.calm: '😌',
  Mood.neutral: '😐',
  Mood.sad: '☹️',
  Mood.verySad: '😢',
};

int moodToValue(Mood m) => {
  Mood.verySad: 1,
  Mood.sad: 2,
  Mood.neutral: 3,
  Mood.calm: 4,
  Mood.veryHappy: 5,
}[m]!;

class _DiaryState extends State<Diary> {
  Mood _selected = Mood.veryHappy;
  final _ctrl = TextEditingController();
  bool _saving = false;

  // ---------- Firebase helpers ----------
  Future<User> _ensureUser() async {
    final auth = FirebaseAuth.instance;
    return auth.currentUser ?? (await auth.signInAnonymously()).user!;
  }

  CollectionReference<Map<String, dynamic>> _col(User u) =>
      FirebaseFirestore.instance.collection('users').doc(u.uid).collection('moods');

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final user = await _ensureUser();
      await _col(user).add({
        'mood': moodToValue(_selected),       // 1..5
        'text': _ctrl.text.trim(),
        'ts': FieldValue.serverTimestamp(),   // server time
      });
      _ctrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Query: last 7 days
  Query<Map<String, dynamic>> _last7DaysQuery(User u) {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    return _col(u)
        .where('ts', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('ts', descending: false);
  }

  // Build 7-point series (Day 1..Day 7)
  List<double> _buildSeries(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final sums = List<double>.filled(7, 0);
    final counts = List<int>.filled(7, 0);

    for (final d in docs) {
      final ts = (d['ts'] as Timestamp?)?.toDate();
      final val = (d['mood'] as num?)?.toDouble();
      if (ts == null || val == null) continue;
      final dayIdx = ts.difference(start).inDays;
      if (dayIdx < 0 || dayIdx > 6) continue;
      sums[dayIdx] += val;
      counts[dayIdx] += 1;
    }
    return List<double>.generate(7, (i) => counts[i] == 0 ? 0 : sums[i] / counts[i]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFD9FB),
        centerTitle: true,
        title: const Text("Mood Diary"),
        elevation: 0,
      ),
      bottomNavigationBar: const Nav(currentIndex: 1),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).padding.bottom + 90,
          ),
          child: Column(
            children: [
              // ---- emoji row ----
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: Mood.values.map((m) {
                  final selected = m == _selected;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = m),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected ? Colors.purple.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? Colors.purple : Colors.grey.shade400,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(_moodEmoji[m]!, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ---- text ----
              TextField(
                controller: _ctrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Write something...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ---- chart from Firestore (last 7 days) ----
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Mood Statistics",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<User>(
                  future: _ensureUser(),
                  builder: (_, userSnap) {
                    if (!userSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _last7DaysQuery(userSnap.data!).snapshots(),
                      builder: (_, snap) {
                        final series = _buildSeries(snap.data?.docs ?? const []);
                        return LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 5,
                            gridData: FlGridData(show: true, horizontalInterval: 1),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, meta) {
                                    final i = v.toInt();
                                    if (i < 0 || i > 6) return const SizedBox.shrink();
                                    return Text('Day ${i + 1}', style: const TextStyle(fontSize: 10));
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(7, (i) => FlSpot(i.toDouble(), series[i])),
                                isCurved: true,
                                color: Colors.purple,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ---- save button ----
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_saving ? "Saving..." : "Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
