import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/nav.dart';
import 'profile.dart' as profile_page; // <-- for fallback navigation to Profile

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _notifKey = 'notif_deadline';
  bool _deadlineNotif = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() => _deadlineNotif = sp.getBool(_notifKey) ?? true);
  }

  Future<void> _toggle(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_notifKey, v);
    setState(() => _deadlineNotif = v);
  }

  void _return() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // Fallback if opened directly
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const profile_page.Profile()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Return',
          icon: const Icon(Icons.arrow_back),
          onPressed: _return,
        ),
      ),
      bottomNavigationBar: const Nav(currentIndex: 3),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Deadline reminders'),
            subtitle: const Text('Enable notification reminders for deadlines'),
            value: _deadlineNotif,
            onChanged: _toggle,
          ),
          const Divider(height: 0),
          const ListTile(
            leading: Icon(Icons.lock_reset),
            title: Text('Change Password'),
            subtitle: Text('Implement Firebase reset if you’ve set it up'),
          ),
        ],
      ),
    );
  }
}
