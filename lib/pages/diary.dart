// lib/pages/diary.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/nav.dart'; // ✅ 导入底部导航

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

class _DiaryState extends State<Diary> {
  Mood _selected = Mood.veryHappy;
  final _ctrl = TextEditingController();

  // 假数据（可换成 Firestore 数据）
  final List<double> _stats = [1, 2, 1, 3, 2];

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

      // ✅ 底部导航；1 表示 Diary 选中
      bottomNavigationBar: const Nav(currentIndex: 1),

      body: SafeArea(
        child: ListView(
          // ✅ 给底部留出空间，避免被 Nav 挡住
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).padding.bottom + 90,
          ),
          children: [
            // ==== Emoji Row ====
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
                    child: Text(
                      _moodEmoji[m]!,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ==== Write Something ====
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

            const SizedBox(height: 24),

            // ==== Line Chart ====
            const Text(
              "Mood Statistics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles:
                      SideTitles(showTitles: true, reservedSize: 30),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) =>
                            Text("Day ${v.toInt() + 1}"),
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true, horizontalInterval: 1),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _stats
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==== Save Button ====
            ElevatedButton(
              onPressed: () {
                debugPrint("Mood: $_selected, Text: ${_ctrl.text}");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
