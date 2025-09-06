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

String emojiForValue(num v) {
  final iv = v.round().clamp(1, 5);
  switch (iv) {
    case 1:
      return _moodEmoji[Mood.verySad]!;
    case 2:
      return _moodEmoji[Mood.sad]!;
    case 3:
      return _moodEmoji[Mood.neutral]!;
    case 4:
      return _moodEmoji[Mood.calm]!;
    case 5:
      return _moodEmoji[Mood.veryHappy]!;
    default:
      return '—';
  }
}

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
        'mood': moodToValue(_selected), // 1..5
        'text': _ctrl.text.trim(),
        'ts': FieldValue.serverTimestamp(), // server time
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

  // Rolling last 7 days (ending today). Rightmost index = today.
  Query<Map<String, dynamic>> _last7DaysQuery(User u) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: 6)); // 6 days ago
    return _col(u)
        .where('ts', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('ts', descending: false);
  }

  // Build 7-point series (idx 0..6) aligned to [today-6, ..., today]
  // Returns averages per day; null = no data that day.
  List<double?> _buildSeries(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final sums = List<double>.filled(7, 0);
    final counts = List<int>.filled(7, 0);

    for (final d in docs) {
      final ts = (d['ts'] as Timestamp?)?.toDate();
      final val = (d['mood'] as num?)?.toDouble();
      if (ts == null || val == null) continue;
      final dayIdx = DateTime(ts.year, ts.month, ts.day).difference(start).inDays; // 0..6
      if (dayIdx < 0 || dayIdx > 6) continue;
      sums[dayIdx] += val.clamp(1, 5);
      counts[dayIdx] += 1;
    }
    return List<double?>.generate(7, (i) => counts[i] == 0 ? null : (sums[i] / counts[i]));
  }

  // Earliest diary entry (to compute Day N labels)
  Future<DateTime?> _firstEntryDate(User u) async {
    final q = await _col(u).orderBy('ts', descending: false).limit(1).get();
    if (q.docs.isEmpty) return null;
    final ts = (q.docs.first.data()['ts'] as Timestamp?)?.toDate();
    if (ts == null) return null;
    return DateTime(ts.year, ts.month, ts.day);
  }

  void _openHistory() async {
    final user = await _ensureUser();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DiaryHistoryPage(user: user)),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD9FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFBFD9FB),
        centerTitle: true,
        title: const Text("Mood Diary", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
          ),
        ],
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

              // ---- chart title ----
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Mood Trend (last 7 days • today on the right)",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              // ---- chart card ----
              Expanded(
                child: FutureBuilder<User>(
                  future: _ensureUser(),
                  builder: (_, userSnap) {
                    if (!userSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final user = userSnap.data!;

                    return FutureBuilder<DateTime?>(
                      future: _firstEntryDate(user),
                      builder: (_, firstSnap) {
                        final firstDate = firstSnap.data; // can be null (no entries yet)

                        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _last7DaysQuery(user).snapshots(),
                          builder: (_, snap) {
                            final series = _buildSeries(snap.data?.docs ?? const []);
                            final now = DateTime.now();
                            final start = DateTime(now.year, now.month, now.day)
                                .subtract(const Duration(days: 6)); // chart start date
                            final today = DateTime(now.year, now.month, now.day);

                            // Spots: null days show as gaps (won't pull curve down)
                            final spots = List<FlSpot>.generate(7, (i) {
                              final v = series[i];
                              return v == null
                                  ? FlSpot.nullSpot
                                  : FlSpot(i.toDouble(), v.clamp(1.0, 5.0));
                            });

                            // Label helper: Day N since first entry. Hide < 1.
                            String? dayLabelForIndex(int i) {
                              if (firstDate == null) {
                                // No entries yet -> only show D1 on "today" if any point exists
                                if (i == 6 && series[i] != null) return 'D1';
                                return null;
                              }
                              final dateAtI = start.add(Duration(days: i));
                              final n = dateAtI.difference(firstDate).inDays + 1; // Day 1..N
                              if (n < 1) return null; // before first day -> no label
                              return 'D$n';
                            }

                            return Container(
                              padding: const EdgeInsets.fromLTRB(20, 30, 25, 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: LineChart(
                                LineChartData(
                                  // Domain fixed to 0..6 (rightmost = today)
                                  minX: 0, maxX: 6,
                                  // Mood range
                                  minY: 1, maxY: 5,

                                  // Prevent rightmost dot cut-off
                                  clipData: const FlClipData(
                                    left: false, right: false, top: false, bottom: false,
                                  ),

                                  // Soft grid
                                  gridData: FlGridData(
                                    show: true,
                                    horizontalInterval: 1,
                                    drawVerticalLine: true,
                                    verticalInterval: 1,
                                    getDrawingHorizontalLine: (y) => FlLine(
                                      color: Colors.grey.withOpacity(0.18),
                                      strokeWidth: 1,
                                      dashArray: const [4, 4],
                                    ),
                                    getDrawingVerticalLine: (x) => FlLine(
                                      color: Colors.grey.withOpacity(0.10),
                                      strokeWidth: 1,
                                    ),
                                  ),

                                  // Titles
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        getTitlesWidget: (value, _) {
                                          final iv = value.round();
                                          if (iv < 1 || iv > 5) return const SizedBox.shrink();
                                          const emo = {1:'😢',2:'☹️',3:'😐',4:'😌',5:'😊'};
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 4),
                                            child: Text(emo[iv]!, style: const TextStyle(fontSize: 14)),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

                                    // Bottom: Day numbers, with Today highlighted on the rightmost tick
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 1,
                                        getTitlesWidget: (value, _) {
                                          // exact integers inside 0..6
                                          if (value != value.roundToDouble()) return const SizedBox.shrink();
                                          final i = value.toInt();
                                          if (i < 0 || i > 6) return const SizedBox.shrink();

                                          final label = dayLabelForIndex(i);
                                          if (label == null) return const SizedBox.shrink();

                                          final isToday = i == 6;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              isToday ? '$label' : label,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                                                color: isToday ? Colors.purple : Colors.black87,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  borderData: FlBorderData(show: false),

                                  // Neutral baseline
                                  extraLinesData: ExtraLinesData(horizontalLines: [
                                    HorizontalLine(
                                      y: 3,
                                      color: Colors.grey.withOpacity(0.28),
                                      strokeWidth: 1.2,
                                      dashArray: const [6, 6],
                                    ),
                                  ]),

                                  // Tooltips
                                  lineTouchData: LineTouchData(
                                    handleBuiltInTouches: true,
                                    touchTooltipData: LineTouchTooltipData(
                                      tooltipBgColor: Colors.black87,
                                      tooltipRoundedRadius: 8,
                                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      getTooltipItems: (touched) => touched.map((s) {
                                        final i = s.x.toInt().clamp(0, 6);
                                        final d = start.add(Duration(days: i));
                                        final dayN = (firstDate == null)
                                            ? (i == 6 ? 1 : null)
                                            : (d.difference(firstDate).inDays + 1);
                                        final dayLabel = (dayN == null || dayN < 1) ? '' : 'Day $dayN';
                                        final emo = emojiForValue(s.y);
                                        final dateStr = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
                                        return LineTooltipItem(
                                          '$emo  $dayLabel\n$dateStr',
                                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                        );
                                      }).toList(),
                                    ),
                                  ),

                                  // Pretty line
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      curveSmoothness: 0.28,
                                      preventCurveOverShooting: true,
                                      barWidth: 3,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF7C4DFF), Color(0xFFE91E63)],
                                      ),
                                      // Dots: white fill + colored ring; bigger on "today"
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (s, _, __, ___) {
                                          final isToday = s.x.round() == 6;
                                          return FlDotCirclePainter(
                                            radius: isToday ? 4.8 : 4.0,
                                            color: Colors.white,
                                            strokeWidth: 3,
                                            strokeColor: const Color(0xFF7C4DFF),
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF7C4DFF).withOpacity(.20),
                                            const Color(0xFFE91E63).withOpacity(0.0),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
                    backgroundColor: Colors.white,
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

/* ======================= History Page ======================= */

class DiaryHistoryPage extends StatelessWidget {
  final User user;
  const DiaryHistoryPage({super.key, required this.user});

  CollectionReference<Map<String, dynamic>> _col(User u) =>
      FirebaseFirestore.instance.collection('users').doc(u.uid).collection('moods');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFD9FB),
        title: const Text('Diary History', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col(user).orderBy('ts', descending: true).snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Center(child: Text('No diary entries yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final ts = (d['ts'] as Timestamp?)?.toDate();
              final mood = (d['mood'] as num?) ?? 0;
              final text = (d['text'] as String?)?.trim() ?? '';

              final subtitle = ts == null
                  ? '—'
                  : '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} '
                    '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(.12),
                    child: Text(
                      emojiForValue(mood),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  title: Text(
                    text.isEmpty ? '(No text)' : text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('Mood: ${mood.toString()}   •   $subtitle'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
