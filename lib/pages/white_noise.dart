// lib/pages/white_noise.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/nav.dart';

class WhiteNoisePage extends StatefulWidget {
  const WhiteNoisePage({super.key});
  @override
  State<WhiteNoisePage> createState() => _WhiteNoisePageState();
}

class _NoiseItem {
  final String keyName;
  final String label;
  final IconData icon;
  double volume; // 0.0..1.0
  _NoiseItem(this.keyName, this.label, this.icon, this.volume);
}

class _WhiteNoisePageState extends State<WhiteNoisePage> {
  final List<_NoiseItem> _items = [
    _NoiseItem('noise_fan', 'Fan', Icons.toys, 0.0),
    _NoiseItem('noise_cricket', 'Cricket', Icons.bug_report, 0.0),
    _NoiseItem('noise_rain', 'Rain', Icons.water_drop, 0.0),
    _NoiseItem('noise_bonfire', 'Bonfire', Icons.local_fire_department, 0.0),
    _NoiseItem('noise_wave', 'Wave', Icons.waves, 0.0),
    _NoiseItem('noise_stream', 'Stream', Icons.water, 0.0),
    _NoiseItem('noise_bird', 'Bird', Icons.emoji_nature, 0.0),
    _NoiseItem('noise_train', 'Train', Icons.train, 0.0),
  ];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVolumes();
  }

  Future<void> _loadVolumes() async {
    final sp = await SharedPreferences.getInstance();
    for (final it in _items) {
      it.volume = sp.getDouble(it.keyName) ?? 0.0;
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _saveVolume(_NoiseItem it, double v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(it.keyName, v);
  }

  void _setAll(double v) async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      for (final it in _items) {
        it.volume = v;
        sp.setDouble(it.keyName, v);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('White Noise Mixer'),
        centerTitle: true,
        automaticallyImplyLeading: false, // keep consistent with your style
      ),
      bottomNavigationBar: const Nav(currentIndex: 2), // Relax tab
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _setAll(0.0),
                        icon: const Icon(Icons.volume_mute),
                        label: const Text('Mute All'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _setAll(0.5),
                        icon: const Icon(Icons.volume_down_alt),
                        label: const Text('50% All'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _setAll(1.0),
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Max All'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sliders (top-to-bottom)
                ..._items.map((it) => _NoiseSliderTile(
                      item: it,
                      onChanged: (v) {
                        setState(() => it.volume = v);
                        _saveVolume(it, v);
                      },
                    )),
              ],
            ),
    );
  }
}

class _NoiseSliderTile extends StatelessWidget {
  final _NoiseItem item;
  final ValueChanged<double> onChanged;
  const _NoiseSliderTile({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final percent = (item.volume * 100).round();
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(item.icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Text('$percent%'),
            ]),
            Slider(
              value: item.volume,
              onChanged: onChanged,
              min: 0.0,
              max: 1.0,
            ),
          ],
        ),
      ),
    );
  }
}
