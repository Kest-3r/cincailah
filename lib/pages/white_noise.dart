import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import '../widgets/nav.dart';
import 'package:audio_session/audio_session.dart';

class WhiteNoisePage extends StatefulWidget {
  const WhiteNoisePage({super.key});
  @override
  State<WhiteNoisePage> createState() => _WhiteNoisePageState();
}

class _NoiseItem {
  final String keyName;
  final String label;
  final IconData icon;
  final String assetPath; // asset path for the audio
  double volume; // 0.0..1.0
  _NoiseItem(this.keyName, this.label, this.icon, this.assetPath, this.volume);
}

class _WhiteNoisePageState extends State<WhiteNoisePage> {
  final List<_NoiseItem> _items = [
    _NoiseItem('noise_fan', 'Fan', Icons.wind_power, 'audio/fan.ogg', 0.0),
    _NoiseItem(
      'noise_cricket',
      'Cricket',
      Icons.bug_report,
      'audio/cricket.ogg',
      0.0,
    ),
    _NoiseItem('noise_rain', 'Rain', Icons.water_drop, 'audio/rain.ogg', 0.0),
    _NoiseItem(
      'noise_bonfire',
      'Bonfire',
      Icons.local_fire_department,
      'audio/bonfire.ogg',
      0.0,
    ),
    _NoiseItem('noise_wave', 'Wave', Icons.waves, 'audio/wave.ogg', 0.0),
    _NoiseItem('noise_stream', 'Stream', Icons.water, 'audio/stream.ogg', 0.0),
    _NoiseItem('noise_bird', 'Bird', Icons.emoji_nature, 'audio/bird.ogg', 0.0),
    _NoiseItem('noise_train', 'Train', Icons.train, 'audio/train.ogg', 0.0),
  ];

  final Map<String, AudioPlayer> _players = {};
  final Map<String, String?> _errors = {}; // per-track error messages (if any)
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Make sure we have audio focus (prevents silent playback on some devices)
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Load saved volumes
      final sp = await SharedPreferences.getInstance();
      for (final it in _items) {
        it.volume = sp.getDouble(it.keyName) ?? 0.0;
      }

      // Prepare each player
      for (final it in _items) {
        final p = AudioPlayer();
        _players[it.keyName] = p;

        try {
          // Load the asset (OGG), then loop the single track forever
          await p
              .setAudioSource(AudioSource.asset(it.assetPath))
              .timeout(const Duration(seconds: 6));
          await p.setLoopMode(LoopMode.one); // <-- infinite loop
          await p.setVolume(it.volume);

          // Don't await play(); some emulators hang when awaiting
          if (it.volume > 0) {
            p.play(); // fire-and-forget
          }
        } catch (e, st) {
          _errors[it.keyName] = e.toString();
          debugPrint('WhiteNoise: failed ${it.assetPath}: $e\n$st');
          await p.stop();
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false); // spinner always stops
    }
  }

  Future<void> _saveVolume(_NoiseItem it, double v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(it.keyName, v);
  }

  Future<void> _setAll(double v) async {
    final sp = await SharedPreferences.getInstance();
    for (final it in _items) {
      it.volume = v;
      await sp.setDouble(it.keyName, v);

      final p = _players[it.keyName];
      if (p != null) {
        if (_errors[it.keyName] != null) continue; // skip errored tracks
        await p.setVolume(v);
        if (v > 0 && !p.playing) {
          await p.play();
        } else if (v == 0 && p.playing) {
          await p.pause();
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFD9FB),
        title: const Text('White Noise Mixer'),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      bottomNavigationBar: const Nav(currentIndex: 2),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _setAll(0.0),
                        icon: const Icon(Icons.volume_mute),
                        label: const Text('Mute All'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _setAll(0.5),
                        icon: const Icon(Icons.volume_down_alt),
                        label: const Text('50% All'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _setAll(1.0),
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Max All'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sliders
                ..._items.map((it) {
                  final hasError = _errors[it.keyName] != null;
                  return _NoiseSliderTile(
                    item: it,
                    errorText: hasError ? 'Asset/load error' : null,
                    onChanged: (v) async {
                      setState(() => it.volume = v);
                      await _saveVolume(it, v);

                      final p = _players[it.keyName];
                      if (p == null || hasError) return;

                      await p.setVolume(v);
                      if (v > 0) {
                        if (!p.playing) await p.play(); // keep looping
                      } else {
                        if (p.playing) await p.pause();
                      }
                    },
                  );
                }),
              ],
            ),
    );
  }
}

class _NoiseSliderTile extends StatelessWidget {
  final _NoiseItem item;
  final ValueChanged<double> onChanged;
  final String? errorText; // show small error if failed to load
  const _NoiseSliderTile({
    required this.item,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (item.volume * 100).round();
    final disabled = errorText != null;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.icon, color: disabled ? Colors.redAccent : null),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: disabled ? Colors.redAccent : null,
                    ),
                  ),
                ),
                if (!disabled) Text('$percent%'),
              ],
            ),
            if (disabled) ...[
              const SizedBox(height: 6),
              Text(
                errorText!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
            Slider(
              value: item.volume,
              onChanged: disabled ? null : onChanged,
              min: 0.0,
              max: 1.0,
            ),
          ],
        ),
      ),
    );
  }
}
