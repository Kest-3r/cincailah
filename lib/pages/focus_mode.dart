import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/nav.dart';
import 'profile.dart' as profile_page; // for navigation back to Profile

class FocusModeSetupPage extends StatefulWidget {
  const FocusModeSetupPage({super.key});
  @override
  State<FocusModeSetupPage> createState() => _FocusModeSetupPageState();
}

class _FocusModeSetupPageState extends State<FocusModeSetupPage> {
  int _minutes = 25;

  void _start() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FocusSessionPage(minutes: _minutes)),
    );
  }

  void _returnToProfile() {
    // Prefer popping back to existing Profile if present, else go to a new one.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const profile_page.Profile()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Mode'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Return',
          icon: const Icon(Icons.arrow_back),
          onPressed: _returnToProfile,
        ),
      ),
      bottomNavigationBar: const Nav(currentIndex: 3),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Set a focus duration', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Slider(
                value: _minutes.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                label: '$_minutes min',
                onChanged: (v) => setState(() => _minutes = v.round()),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                '$_minutes min',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const Text(
            'Note: Locks usage inside this app during the session.',
            style: TextStyle(color: Colors.grey),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Focus'),
            ),
          ),
        ]),
      ),
    );
  }
}

class FocusSessionPage extends StatefulWidget {
  final int minutes;
  const FocusSessionPage({super.key, required this.minutes});
  @override
  State<FocusSessionPage> createState() => _FocusSessionPageState();
}

class _FocusSessionPageState extends State<FocusSessionPage> {
  late Duration _left;
  Timer? _t;
  bool _canLeave = false; // block back unless allowed

  @override
  void initState() {
    super.initState();
    _left = Duration(minutes: widget.minutes);

    _t = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _left -= const Duration(seconds: 1));
      if (_left.inSeconds <= 0) {
        timer.cancel();
        _exitToSetup(showMsg: 'Focus session complete!');
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<bool> _onWillPop() async => _canLeave;

  void _exitToSetup({String? showMsg}) {
    _t?.cancel();
    _canLeave = true;            // allow pop through WillPopScope
    Navigator.of(context).pop(); // back to setup
    if (showMsg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(showMsg)));
    }
  }

  void _onReturn() => _exitToSetup(showMsg: 'Returned to Focus setup.');

  void _onStopToProfile() {
    // Stop timer and go straight to Profile (clear stack to avoid back into session)
    _t?.cancel();
    _canLeave = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const profile_page.Profile()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mins = _left.inMinutes;
    final secs = _left.inSeconds % 60;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Focus Mode'),
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Return',
            icon: const Icon(Icons.arrow_back),
            onPressed: _onReturn,
          ),
          actions: [
            IconButton(
              tooltip: 'Stop',
              icon: const Icon(Icons.stop),
              onPressed: _onStopToProfile,
            ),
          ],
        ),
        // No bottom nav during session
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.timer, size: 72),
            const SizedBox(height: 12),
            Text(
              '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            const Text('Stay focused! You’ve got this 💪'),
          ]),
        ),
      ),
    );
  }
}
