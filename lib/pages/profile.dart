// lib/pages/profile.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/nav.dart';
import 'focus_mode.dart'; // Ensure this exists (FocusModeSetupPage)

class Profile extends StatefulWidget {
  const Profile({super.key});
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // --- Local pref keys ---
  static const _kBio = 'profile_bio';
  static const _kDailyReminder = 'profile_daily_reminder';
  static const _kPhotoPath = 'profile_photo_path';

  final _bioCtrl = TextEditingController();
  bool _dailyReminder = false;

  // Demo stats (replace with real data later)
  int _entries = 12;
  int _relaxMin = 47;
  int _streak = 5;

  // Locally picked avatar (highest priority for display)
  String? _photoPath;

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
      _bioCtrl.text = p.getString(_kBio) ?? '';
      _dailyReminder = p.getBool(_kDailyReminder) ?? false;
      _photoPath = p.getString(_kPhotoPath);
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBio, _bioCtrl.text.trim());
    await p.setBool(_kDailyReminder, _dailyReminder);
    if (_photoPath != null) {
      await p.setString(_kPhotoPath, _photoPath!);
    }
  }

  // ====== Edit name (same as your current flow) ======
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

  // ====== Edit photo (same “tap edit” pattern) ======
  Future<void> _editPhoto() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (_photoPath != null && _photoPath!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || choice == null) return;

    if (choice == 'remove') {
      setState(() => _photoPath = null);
      await _savePrefs();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo removed')));
      return;
    }

    if (choice == 'gallery') {
      try {
        final picker = ImagePicker();
        final res = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (res == null) return;
        setState(() => _photoPath = res.path);
        await _savePrefs();

        // Optional: If you later add Firebase Storage, upload & call _user?.updatePhotoURL(downloadUrl)
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo updated ✅')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  // ====== Focus Mode navigation ======
  void _openFocusMode() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FocusModeSetupPage()));
  }

  // ====== WhatsApp Helper ======
  Future<void> _openWhatsAppHelper() async {
    // Talian Kasih 15999
    final uriWeb = Uri.parse('https://wa.me/60192615999'); // +60 19-261 5999 (demo helper)
    final uriScheme = Uri.parse('whatsapp://send?phone=+60192615999');
    try {
      if (await canLaunchUrl(uriScheme)) {
        await launchUrl(uriScheme);
      } else if (await canLaunchUrl(uriWeb)) {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open WhatsApp: $e')));
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

  ImageProvider? _avatarProvider() {
    // Priority: local photoPath -> Firebase photoURL -> null
    if (_photoPath != null && _photoPath!.isNotEmpty && File(_photoPath!).existsSync()) {
      return FileImage(File(_photoPath!));
    }
    final url = _user?.photoURL;
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFBFD9FB);
    const headerBg = Color(0xFFD7E8FF);
    const panelRadius = 24.0;

    final username = _user?.displayName ?? _user?.email?.split('@').first ?? 'User';
    final avatarProvider = _avatarProvider();

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
                  color: Colors.black.withOpacity(0.06),
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
                  child: const Row(
                    children: [
                      Expanded(
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
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.black.withOpacity(0.06)),

                // ===== User card =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: const Color(0xFFE2EDFF),
                              backgroundImage: avatarProvider,
                              child: avatarProvider == null
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
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Material(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: _editPhoto,
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                                style: TextStyle(color: Colors.black.withOpacity(0.6)),
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
                    children: [
                      _StatCard(label: 'Entries', value: '$_entries', icon: Icons.book_outlined),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Relax', value: '$_relaxMin', icon: Icons.self_improvement),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Streak', value: '$_streak🔥', icon: Icons.local_fire_department_outlined),
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
                            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                          ),
                        ),
                        onChanged: (_) => _savePrefs(),
                      ),
                    ],
                  ),
                ),

                // ===== Settings / Focus Mode / Helper =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Column(
                      children: [
                        // Daily reminder (kept)
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

                        // Focus Mode
                        ListTile(
                          leading: const Icon(Icons.timer),
                          title: const Text('Focus Mode'),
                          subtitle: const Text('Lock this app for a set time'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _openFocusMode,
                        ),
                        const Divider(height: 0),

                        // Mental Health Helper
                        ListTile(
                          leading: const Icon(Icons.health_and_safety),
                          title: const Text('Mental Health Helper'),
                          subtitle: const Text('Chat via WhatsApp (Talian Kasih 15999)'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: _openWhatsAppHelper,
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
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
                    style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
