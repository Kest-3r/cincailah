import 'package:flutter/material.dart';
import '../widgets/nav.dart';

/// ===== 数据结构 =====
enum TaskType { exam, meeting, remind, time, other }

class TaskItem {
  final String title;
  final DateTime dateTime;
  final TaskType type;
  TaskItem({
    required this.title,
    required this.dateTime,
    required this.type,
  });
}

/// ===== 页面 =====
class Deadline extends StatefulWidget {
  const Deadline({super.key});

  @override
  State<Deadline> createState() => _DeadlineState();
}

class _DeadlineState extends State<Deadline> {
  // 输入控件
  final TextEditingController _text = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TaskType _selectedType = TaskType.other;

  // 过滤（null = All）
  TaskType? _filter;

  // 内存任务列表
  final List<TaskItem> _items = <TaskItem>[];

  /// 类型 → 标签
  String _labelOf(TaskType? t) {
    if (t == null) return 'All';
    switch (t) {
      case TaskType.exam:
        return 'Exam';
      case TaskType.meeting:
        return 'Meeting';
      case TaskType.remind:
        return 'Remind';
      case TaskType.time:
        return 'Time';
      case TaskType.other:
        return 'Other';
    }
  }

  /// 类型 → 颜色（只用彩色文字，不用图片）
  Color _colorOf(TaskType t) {
    switch (t) {
      case TaskType.exam:
        return Colors.red;
      case TaskType.meeting:
        return Colors.blue;
      case TaskType.remind:
        return Colors.orange;
      case TaskType.time:
        return Colors.green;
      case TaskType.other:
      default:
        return Colors.purple;
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (t != null) setState(() => _selectedTime = t);
  }

  void _addTask() {
    final title = _text.text.trim();
    if (title.isEmpty) return;

    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    setState(() {
      _items.add(TaskItem(title: title, dateTime: dt, type: _selectedType));
      _text.clear();
    });
  }

  List<TaskItem> get _visibleItems {
    final list = _items
        .where((e) => _filter == null ? true : e.type == _filter)
        .toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6F0F7),
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Calendar Sync',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Connected : Google Calendar',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ===== 输入卡片 =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _text,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'To-do list',
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // 类型选择
                        DropdownButton<TaskType>(
                          value: _selectedType,
                          underline: const SizedBox(),
                          items: TaskType.values
                              .map((t) => DropdownMenuItem<TaskType>(
                            value: t,
                            child: Text(_labelOf(t)),
                          ))
                              .toList(),
                          onChanged: (t) =>
                              setState(() => _selectedType = t ?? TaskType.other),
                        ),
                        const SizedBox(width: 8),
                        // 日期
                        TextButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined, size: 16),
                          label: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                        ),
                        const SizedBox(width: 4),
                        // 时间
                        TextButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule, size: 16),
                          label: Text(_selectedTime.format(context)),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _addTask,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ===== 筛选 Chips =====
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildChip(null, 'All'),
                  const SizedBox(width: 8),
                  _buildChip(TaskType.exam, 'Exam'),
                  const SizedBox(width: 8),
                  _buildChip(TaskType.meeting, 'Meeting'),
                  const SizedBox(width: 8),
                  _buildChip(TaskType.remind, 'Remind'),
                  const SizedBox(width: 8),
                  _buildChip(TaskType.time, 'Time'),
                ],
              ),
            ),

            const Divider(height: 20),

            // ===== 任务列表 =====
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _visibleItems.isEmpty
                      ? const Center(child: Text('No tasks yet.'))
                      : ListView.builder(
                    itemCount: _visibleItems.length,
                    itemBuilder: (context, i) {
                      final t = _visibleItems[i];
                      final time =
                      TimeOfDay.fromDateTime(t.dateTime).format(context);
                      return ListTile(
                        // 直接用彩色文字表示类型
                        leading: Text(
                          _labelOf(t.type),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _colorOf(t.type),
                          ),
                        ),
                        title: Text(t.title),
                        subtitle: Text(time),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ===== 底部导航（和 Diary 一样） =====
      bottomNavigationBar: const Nav(),
    );
  }

  Widget _buildChip(TaskType? type, String label) {
    final selected = _filter == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = type),
      selectedColor: const Color(0xFFCCE1FF),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }
}
