// lib/pages/profile.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/nav.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _bioCtrl = TextEditingController();
  bool _dailyReminder = false;
  bool _relaxSounds = true;

  // Demo stats (replace with real data later)
  int _entries = 12;
  int _relaxMin = 47;
  int _streak = 5;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _bioCtrl.text = p.getString('profile_bio') ?? '';
      _dailyReminder = p.getBool('profile_daily_reminder') ?? false;
      _relaxSounds = p.getBool('profile_relax_sounds') ?? true;
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('profile_bio', _bioCtrl.text.trim());
    await p.setBool('profile_daily_reminder', _dailyReminder);
    await p.setBool('profile_relax_sounds', _relaxSounds);
  }

  Future<void> _editName() async {
    final nameCtrl = TextEditingController(text: _user?.displayName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Your display name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, nameCtrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      await _user?.updateDisplayName(newName);
      await _user?.reload();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFBFD9FB);
    const headerBg = Color(0xFFD7E8FF);
    const panelRadius = 24.0;

    final username = _user?.displayName ?? _user?.email?.split('@').first ?? 'User';

    return Scaffold(
      backgroundColor: pageBg,
      bottomNavigationBar: const Nav(currentIndex: 3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(panelRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ===== Header =====
                Container(
                  color: headerBg,
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        splashRadius: 24,
                        icon: const Icon(Icons.arrow_back, size: 22),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'PROFILE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.black.withValues(alpha: 0.06)),

                // ===== User card =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFFE2EDFF),
                          backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
                          child: _user?.photoURL == null
                              ? Text(
                            username.isNotEmpty ? username[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5D6AA1),
                            ),
                          )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      username,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit name',
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: _editName,
                                  ),
                                ],
                              ),
                              Text(
                                _user?.email ?? 'Anonymous user',
                                style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== Stats =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: const [
                      Expanded(child: _StatCard(label: 'Entries', value: '12', icon: Icons.book_outlined)),
                      SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'Relax (min)', value: '47', icon: Icons.self_improvement)),
                      SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'Streak', value: '5🔥', icon: Icons.local_fire_department_outlined)),
                    ],
                  ),
                ),

                // ===== Bio =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bioCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Write something about yourself…',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                          ),
                        ),
                        onChanged: (_) => _savePrefs(),
                      ),
                    ],
                  ),
                ),

                // ===== Settings =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Daily reminder'),
                          subtitle: const Text('Get a gentle nudge to write or relax'),
                          value: _dailyReminder,
                          onChanged: (v) {
                            setState(() => _dailyReminder = v);
                            _savePrefs();
                          },
                        ),
                        const Divider(height: 0),
                        SwitchListTile(
                          title: const Text('Relax sounds'),
                          subtitle: const Text('Play soothing sounds in Relax page'),
                          value: _relaxSounds,
                          onChanged: (v) {
                            setState(() => _relaxSounds = v);
                            _savePrefs();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== Actions =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Export coming soon ✨')),
                            );
                          },
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Export data'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign out'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* === Overflow-safe Stat Card === */
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5D6AA1)),
          const SizedBox(width: 8),
          // Constrain the text area to prevent overflow
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
