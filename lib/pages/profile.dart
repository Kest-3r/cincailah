import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

// Your bottom nav
import '../widgets/nav.dart';

// External pages
import 'settings_page.dart';
import 'focus_mode.dart'; // FocusModeSetupPage lives here

/// Local storage keys (username + photo)
class _Keys {
  static const username = 'profile_username';
  static const photoPath = 'profile_photo_path';
}

/// ===== Simple mood models (demo) =====
enum MoodRange { week, month, year }

class MoodEntry {
  final DateTime date;

  /// Mood score: 1 (low) .. 5 (great)
  final int score;
  MoodEntry(this.date, this.score);
}

List<MoodEntry> _generateMood(MoodRange range) {
  final now = DateTime.now();
  final rnd = now.millisecondsSinceEpoch % 5;

  switch (range) {
    case MoodRange.week:
      // 7 points (daily)
      return List.generate(7, (i) {
        final d = now.subtract(Duration(days: 6 - i));
        final s = 2 + ((i + rnd) % 4); // 2..5
        return MoodEntry(d, s);
      });
    case MoodRange.month:
      // 30 days (sample every 2 days -> 15 pts)
      return List.generate(15, (i) {
        final d = now.subtract(Duration(days: 28 - i * 2));
        final s = 1 + ((i + rnd) % 5); // 1..5
        return MoodEntry(d, s);
      });
    case MoodRange.year:
      // 12 months (mid-month)
      return List.generate(12, (i) {
        final d = DateTime(now.year, now.month - (11 - i), 15);
        final s = 1 + ((i + rnd) % 5); // 1..5
        return MoodEntry(d, s);
      });
  }
}

/// ===== Profile (root) =====
class Profile extends StatefulWidget {
  const Profile({super.key});
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _username = 'Your Name';
  String? _photoPath;

  MoodRange _range = MoodRange.week;
  late List<MoodEntry> _moodData;

  @override
  void initState() {
    super.initState();
    _moodData = _generateMood(_range);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _username = sp.getString(_Keys.username) ?? 'Your Name';
      _photoPath = sp.getString(_Keys.photoPath);
    });
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  void _openFocusMode() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FocusModeSetupPage()));
  }

  Future<void> _openWhatsAppHelper() async {
    final uriWeb = Uri.parse('https://wa.me/60192615999'); // +60 19-261 5999
    final uriScheme = Uri.parse('whatsapp://send?phone=+60192615999');
    if (await canLaunchUrl(uriScheme)) {
      await launchUrl(uriScheme);
    } else if (await canLaunchUrl(uriWeb)) {
      await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }

  void _openEditProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EditProfilePage()));
    _loadProfile(); // refresh after edit
  }

  void _onRangeChanged(MoodRange r) {
    if (r == _range) return;
    setState(() {
      _range = r;
      _moodData = _generateMood(_range);
    });
  }

  String _labelForRange(MoodRange r) {
    switch (r) {
      case MoodRange.week:
        return '7 days';
      case MoodRange.month:
        return '30 days';
      case MoodRange.year:
        return '12 months';
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600);

    return Scaffold(
      backgroundColor: const Color(0xFFBFD9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFD9FB),
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: _openEditProfile,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      bottomNavigationBar: const Nav(currentIndex: 3),

      // OPTION A: keep ListView but disable scrolling
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        physics: const NeverScrollableScrollPhysics(), // ⬅️ unscrollable
        children: [
          // Header
          Center(
            child: Column(
              children: [
                _Avatar(photoPath: _photoPath),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_username, style: titleStyle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mood trend with range chips ABOVE the graph
          Card(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Mood Trend',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_labelForRange(_range)})',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Chips row (moved above graph)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RangeChip(
                        label: 'Week',
                        selected: _range == MoodRange.week,
                        onTap: () => _onRangeChanged(MoodRange.week),
                      ),
                      const SizedBox(width: 6),
                      _RangeChip(
                        label: 'Month',
                        selected: _range == MoodRange.month,
                        onTap: () => _onRangeChanged(MoodRange.month),
                      ),
                      const SizedBox(width: 6),
                      _RangeChip(
                        label: 'Year',
                        selected: _range == MoodRange.year,
                        onTap: () => _onRangeChanged(MoodRange.year),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  // Smaller graph
                  SizedBox(height: 140, child: _MoodChart(data: _moodData)),
                  const SizedBox(height: 6),
                  const Text(
                    'Scale: 1 (sad) → 5 (happy)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Keep the three action tiles BELOW the card
          // Settings tile
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                subtitle: const Text('Notifications & password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openSettings,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Focus Mode tile
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                leading: const Icon(Icons.timer),
                title: const Text('Focus Mode'),
                subtitle: const Text('Lock this app for a set time'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openFocusMode,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Mental Health Helper tile
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                leading: const Icon(Icons.health_and_safety),
                title: const Text('Mental Health Helper'),
                subtitle: const Text('Chat via WhatsApp (Talian Kasih 15999)'),
                trailing: const Icon(Icons.open_in_new),
                onTap: _openWhatsAppHelper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===== Edit Profile (username + photo) =====
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameCtrl = TextEditingController();
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    final sp = await SharedPreferences.getInstance();
    _nameCtrl.text = sp.getString(_Keys.username) ?? '';
    _photoPath = sp.getString(_Keys.photoPath);
    if (mounted) setState(() {});
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final res = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (res != null) {
      _photoPath = res.path;
      setState(() {});
    }
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    final name = _nameCtrl.text.trim().isEmpty
        ? 'Your Name'
        : _nameCtrl.text.trim();
    await sp.setString(_Keys.username, name);
    if (_photoPath != null) {
      await sp.setString(_Keys.photoPath, _photoPath!);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const radius = 44.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      bottomNavigationBar: const Nav(currentIndex: 3),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                (_photoPath != null &&
                        _photoPath!.isNotEmpty &&
                        File(_photoPath!).existsSync())
                    ? CircleAvatar(
                        radius: radius,
                        backgroundImage: FileImage(File(_photoPath!)),
                      )
                    : const CircleAvatar(
                        radius: radius,
                        child: Icon(Icons.person, size: 44),
                      ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _pickPhoto,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}

/// ===== Small Avatar =====
class _Avatar extends StatelessWidget {
  final String? photoPath;
  const _Avatar({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    const radius = 44.0;
    final color = Theme.of(context).colorScheme.primary;
    if (photoPath != null &&
        photoPath!.isNotEmpty &&
        File(photoPath!).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(photoPath!)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white70,
      child: Icon(Icons.person, size: 44, color: color),
    );
  }
}

/// ===== Range chip =====
class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// ===== Mood chart (1..5 scale) =====
class _MoodChart extends StatelessWidget {
  final List<MoodEntry> data;
  const _MoodChart({required this.data});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MoodChartPainter(data),
      child: const SizedBox.expand(),
    );
  }
}

class _MoodChartPainter extends CustomPainter {
  final List<MoodEntry> data;
  _MoodChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    final grid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    final line = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = Colors.blue.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    const left = 36.0, right = 12.0, top = 12.0, bottom = 24.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    final origin = Offset(left, size.height - bottom);

    // Axes
    canvas.drawLine(
      origin,
      Offset(size.width - right, size.height - bottom),
      axis,
    ); // x
    canvas.drawLine(origin, Offset(left, top), axis); // y

    // y grid + labels
    TextPainter _labelPainter(String t) {
      final tp = TextPainter(
        text: TextSpan(
          text: t,
          style: const TextStyle(fontSize: 10, color: Color(0xFF555555)),
        ),
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: left - 6);
      return tp;
    }

    for (int v = 1; v <= 5; v++) {
      final y = origin.dy - (v - 1) / 4 * h;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
      final tp = _labelPainter('$v');
      tp.paint(canvas, Offset(left - tp.width - 6, y - tp.height / 2));
    }

    if (data.isEmpty) return;

    // Polyline
    final n = data.length;
    final dx = n <= 1 ? w : w / (n - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < n; i++) {
      final score = data[i].score.clamp(1, 5);
      final x = left + dx * i;
      final y = origin.dy - (score - 1) / 4 * h;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, origin.dy);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    final lastX = left + dx * (n - 1);
    fillPath.lineTo(lastX, origin.dy);
    fillPath.close();

    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, line);

    // Dots
    final dot = Paint()..color = Colors.blue;
    for (int i = 0; i < n; i++) {
      final score = data[i].score.clamp(1, 5);
      final x = left + dx * i;
      final y = origin.dy - (score - 1) / 4 * h;
      canvas.drawCircle(Offset(x, y), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodChartPainter oldDelegate) =>
      oldDelegate.data != data;
}
