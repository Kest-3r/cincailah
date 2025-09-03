import 'package:flutter/material.dart';
import '../widgets/nav.dart';

/// ===== 动态 Tag 定义 =====
class TagDef {
  String name;
  IconData icon;
  Color color;
  TagDef({required this.name, required this.icon, required this.color});
}

/// ===== 任务（保存 tag 名称）=====
class TaskItem {
  final String title;
  final DateTime dateTime;
  final String tag; // 与 TagDef.name 对应
  TaskItem({
    required this.title,
    required this.dateTime,
    required this.tag,
  });
}

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

  // 当前选中 tag（用于新建任务）
  String _selectedTag = 'Other';

  // 过滤（null = All）
  String? _filterTag;

  // 动态标签库（不含“All”）
  final List<TagDef> _tags = [
    TagDef(name: 'Exam',   icon: Icons.school_rounded,     color: Colors.red),
    TagDef(name: 'Meeting',icon: Icons.groups_rounded,     color: Colors.blue),
    TagDef(name: 'Remind', icon: Icons.notifications_none, color: Colors.orange),
    TagDef(name: 'Time',   icon: Icons.timer_outlined,     color: Colors.green),
    TagDef(name: 'Other',  icon: Icons.label_rounded,      color: Colors.purple),
  ];

  // 任务
  final List<TaskItem> _items = <TaskItem>[];

  TagDef _tagOf(String name) => _tags.firstWhere(
        (t) => t.name.toLowerCase() == name.toLowerCase(),
        orElse: () => _tags.firstWhere((t) => t.name == 'Other'),
      );

  Widget _tagOption(TagDef t) => Row(
        children: [
          Icon(t.icon, size: 18, color: t.color),
          const SizedBox(width: 8),
          Text(t.name),
        ],
      );

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
      _items.add(TaskItem(title: title, dateTime: dt, tag: _selectedTag));
      _items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _text.clear();
    });
  }

  // 过滤 + 排序（近到远）
  List<TaskItem> get _visibleItems {
    final list = _items.where((e) {
      if (_filterTag == null || _filterTag == 'All') return true;
      return e.tag.toLowerCase() == _filterTag!.toLowerCase();
    }).toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  /// ===== 分组逻辑：同一天的任务归为一组 =====
  DateTime _dayKey(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}'; // 11/3/2025

  List<_Section> get _groupedVisible {
    final items = _visibleItems;
    final Map<DateTime, List<TaskItem>> map = {};
    for (final it in items) {
      final k = _dayKey(it.dateTime);
      map.putIfAbsent(k, () => []).add(it);
    }
    final dates = map.keys.toList()..sort((a, b) => a.compareTo(b)); // 近到远
    return dates
        .map((d) {
          final grouped = map[d]!..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return _Section(date: d, items: grouped);
        })
        .toList();
  }

  // ===== 过滤面板 & 标签管理 =====
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String? tempSelection = _filterTag ?? 'All';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tempSelection ?? 'All',
                    decoration: const InputDecoration(
                      labelText: 'Filter by tag',
                      border: OutlineInputBorder(),
                    ),
                    items: <String>['All', ..._tags.map((t) => t.name)]
                        .map((name) => DropdownMenuItem(
                              value: name,
                              child: name == 'All'
                                  ? const Text('All')
                                  : _tagOption(_tagOf(name)),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => tempSelection = val),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add new tag'),
                          onPressed: () async {
                            final added = await _promptAddTag();
                            if (added != null) {
                              setState(() => _tags.add(added));
                              setModalState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.settings),
                          label: const Text('Manage tags'),
                          onPressed: () => _openManageTagsSheet(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _filterTag =
                            tempSelection == 'All' ? null : tempSelection;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filter'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() => _filterTag = null);
                      Navigator.pop(context);
                    },
                    child: const Text('Reset to All'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<TagDef?> _promptAddTag() async {
    final ctrl = TextEditingController();
    return await showDialog<TagDef>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New tag'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Assignment, Lab, Personal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final raw = ctrl.text.trim();
              if (raw.isEmpty) return;
              final name = _normalizeTagName(raw);
              if (_tags.any((t) => t.name.toLowerCase() == name.toLowerCase())) {
                Navigator.pop(context); // 已存在，忽略
                return;
              }
              final suggestion = _suggestIconAndColor(name);
              Navigator.pop(
                context,
                TagDef(name: name, icon: suggestion.$1, color: suggestion.$2),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _openManageTagsSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Manage Tags',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ..._tags.map((t) {
                    final isOther = t.name == 'Other';
                    return ListTile(
                      leading: Icon(t.icon, color: t.color),
                      title: Text(t.name),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: isOther ? Colors.grey : Colors.red,
                        ),
                        onPressed: isOther
                            ? null
                            : () async {
                                final ok = await _confirmDeleteTag(t.name);
                                if (ok != true) return;
                                setState(() {
                                  // 迁移任务到 Other
                                  for (var i = 0; i < _items.length; i++) {
                                    if (_items[i].tag.toLowerCase() ==
                                        t.name.toLowerCase()) {
                                      _items[i] = TaskItem(
                                        title: _items[i].title,
                                        dateTime: _items[i].dateTime,
                                        tag: 'Other',
                                      );
                                    }
                                  }
                                  _tags.removeWhere((x) => x.name == t.name);
                                  if (_selectedTag.toLowerCase() ==
                                      t.name.toLowerCase()) {
                                    _selectedTag = 'Other';
                                  }
                                  if (_filterTag?.toLowerCase() ==
                                      t.name.toLowerCase()) {
                                    _filterTag = null;
                                  }
                                });
                                setSheetState(() {});
                              },
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add new tag'),
                    onPressed: () async {
                      final added = await _promptAddTag();
                      if (added != null) {
                        setState(() => _tags.add(added));
                        setSheetState(() {});
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDeleteTag(String name) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete tag?'),
        content: Text(
            'Delete “$name”? Tasks with this tag will be moved to “Other”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _normalizeTagName(String s) {
    if (s.isEmpty) return s;
    final t = s.trim();
    if (t.length == 1) return t.toUpperCase();
    return t[0].toUpperCase() + t.substring(1);
  }

  (IconData, Color) _suggestIconAndColor(String name) {
    final k = name.toLowerCase();
    if (k.contains('exam') || k.contains('test')) {
      return (Icons.school_rounded, Colors.red);
    }
    if (k.contains('meet') || k.contains('call') || k.contains('zoom')) {
      return (Icons.groups_rounded, Colors.blue);
    }
    if (k.contains('remind') || k.contains('todo') || k.contains('task')) {
      return (Icons.notifications_none, Colors.orange);
    }
    if (k.contains('time') || k.contains('timer') || k.contains('deadline')) {
      return (Icons.timer_outlined, Colors.green);
    }
    if (k.contains('assign') || k.contains('lab') || k.contains('report')) {
      return (Icons.description_outlined, Colors.teal);
    }
    if (k.contains('personal')) {
      return (Icons.person_outline, Colors.pink);
    }
    return (Icons.label_rounded, Colors.purple);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedVisible;

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6F0F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTag,
                        isDense: true,
                        items: _tags
                            .map(
                              (t) => DropdownMenuItem<String>(
                                value: t.name,
                                child: _tagOption(t),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedTag = v ?? 'Other'),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined, size: 16),
                          label: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule, size: 16),
                          label: Text(_selectedTime.format(context)),
                        ),
                        const SizedBox(width: 8),
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

            // ===== Title + Filter =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Tasks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.filter_list_rounded, size: 18),
                    label: Text(
                      _filterTag == null ? 'Filter' : 'Filter: $_filterTag',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _openFilterSheet,
                  ),
                ],
              ),
            ),

            // ===== 分组列表：日期标题 + 当天任务 =====
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: grouped.isEmpty
                      ? const Center(child: Text('No tasks yet.'))
                      : ListView.builder(
                          itemCount: grouped.length,
                          itemBuilder: (context, gi) {
                            final section = grouped[gi];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 日期标题（如：11/3/2025）
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                                    child: Text(
                                      _formatDate(section.date),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  // 当天任务
                                  ...section.items.map((t) {
                                    final tag = _tagOf(t.tag);
                                    final time = TimeOfDay.fromDateTime(t.dateTime).format(context);
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                      leading: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: tag.color.withOpacity(.12),
                                        child: Icon(tag.icon, color: tag.color),
                                      ),
                                      title: Text(t.title),
                                      subtitle: Text('$time  ·  #${tag.name}'),
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: const Nav(),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }
}

/// 分组模型
class _Section {
  final DateTime date;
  final List<TaskItem> items;
  _Section({required this.date, required this.items});
}
