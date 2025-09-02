import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // 新增：画折线图
import '../widgets/nav.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();
  Mood _selected = Mood.veryHappy;
  bool _saving = false;
  String? _error;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('moods');

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _col.add({
        'text': _ctrl.text.trim(),
        'mood': _selected.name,
        'ts': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _ctrl.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved!')));
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFBFD9FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF8BB7D7),
          title: const Text("Diary"),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== 新增大标题 =====
                const Center(
                  child: Text(
                    "Mood Diary",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ===== 一周心情曲线 + AI 分析 =====
                _WeeklyMoodChart(col: _col),

                const SizedBox(height: 24),

                // ===== 输入区 =====
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MoodChips(
                        selected: _selected,
                        onChanged: (m) => setState(() => _selected = m),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ctrl,
                        minLines: 5,
                        maxLines: 10,
                        decoration: InputDecoration(
                          labelText: "Write something...",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please write something' : null,
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                      ],
                      Center(
                        child: SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8BB7D7),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const Nav(currentIndex: 1),
      ),
    );
  }
}

/// 一周心情曲线 + AI 分析
class _WeeklyMoodChart extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> col;
  const _WeeklyMoodChart({required this.col});

  int _score(Mood m) {
    switch (m) {
      case Mood.veryHappy:
        return 2;
      case Mood.calm:
        return 1;
      case Mood.neutral:
        return 0;
      case Mood.sad:
        return -1;
      case Mood.verySad:
        return -2;
    }
  }

  Mood _moodFromName(String name) {
    return Mood.values.firstWhere(
          (m) => m.name == name,
      orElse: () => Mood.neutral,
    );
  }

  @override
  Widget build(BuildContext context) {
    final since = DateTime.now().subtract(const Duration(days: 7));
    final q = col.where('ts', isGreaterThanOrEqualTo: since).orderBy('ts');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        // 最近7天
        final days = List<DateTime>.generate(7, (i) {
          final d = DateTime.now().subtract(Duration(days: 6 - i));
          return DateTime(d.year, d.month, d.day);
        });

        // 每天心情得分平均值
        final Map<DateTime, List<int>> byDay = {for (final d in days) d: []};
        for (final d in docs) {
          final data = d.data();
          final ts = (data['ts'] as Timestamp?)?.toDate();
          final moodName = (data['mood'] as String?) ?? 'neutral';
          final mood = _moodFromName(moodName);
          if (ts != null) {
            final key = DateTime(ts.year, ts.month, ts.day);
            if (byDay.containsKey(key)) {
              byDay[key]!.add(_score(mood));
            }
          }
        }
        final avgScores = days.map((d) {
          final list = byDay[d]!;
          if (list.isEmpty) return 0.0;
          return list.reduce((a, b) => a + b) / list.length;
        }).toList();

        // AI 分析文字
        String feedback;
        final avgAll = avgScores.isEmpty ? 0.0 : avgScores.reduce((a, b) => a + b) / avgScores.length;
        if (avgAll >= 1) {
          feedback = "This week looks positive! Keep your good habits going 🌟";
        } else if (avgAll <= -0.8) {
          feedback = "It’s been a tough week 😔 Be kind to yourself and take some rest.";
        } else {
          feedback = "A mixed week — notice your patterns, reflect and adjust 💡";
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "This Week's Mood",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) return const SizedBox();
                          final d = days[i];
                          const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                          return Text(weekdays[d.weekday - 1], style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(),
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true, horizontalInterval: 1),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: List.generate(
                        avgScores.length,
                            (i) => FlSpot(i.toDouble(), avgScores[i]),
                      ),
                      barWidth: 3,
                      color: Colors.indigo,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              feedback,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        );
      },
    );
  }
}

/// Mood 选择区
class _MoodChips extends StatelessWidget {
  final Mood selected;
  final ValueChanged<Mood> onChanged;
  const _MoodChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: Mood.values.map((m) {
        return ChoiceChip(
          label: Text(_moodEmoji[m]!),
          selected: m == selected,
          onSelected: (_) => onChanged(m),
        );
      }).toList(),
    );
  }
}
