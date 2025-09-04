// lib/pages/relax.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

import '../widgets/nav.dart';
import 'white_noise.dart'; // White Noise Mixer page

class Relax extends StatefulWidget {
  const Relax({super.key});
  @override
  State<Relax> createState() => _RelaxState();
}

class _RelaxState extends State<Relax> with TickerProviderStateMixin {
  // ========== Bear breathing (animation + synced copy) ==========
  late final AnimationController _breathCtrl;
  late final Animation<double> _breath;
  bool _breathing = false;

  // inhale/hold/exhale/hold (ms)
  static const int _inhaleMs = 4000;
  static const int _holdTopMs = 4000;
  static const int _exhaleMs = 4000;
  static const int _holdBottomMs = 5000;
  static const int _totalMs =
      _inhaleMs + _holdTopMs + _exhaleMs + _holdBottomMs;

  // For measuring bear position (balloon card computes target height)
  final GlobalKey _bearKey = GlobalKey();

  // ========== Meditation audio ==========
  AudioPlayer? _medPlayer;
  bool _medPlaying = false;

  @override
  void initState() {
    super.initState();

    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    // 0.88 -> 1.22 (inhale) -> 1.22(hold) -> 0.88(exhale) -> 0.88(hold)
    _breath =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.88,
              end: 1.22,
            ).chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
            weight: _inhaleMs.toDouble(),
          ),
          TweenSequenceItem(
            tween: ConstantTween<double>(1.22),
            weight: _holdTopMs.toDouble(),
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 1.22,
              end: 0.88,
            ).chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
            weight: _exhaleMs.toDouble(),
          ),
          TweenSequenceItem(
            tween: ConstantTween<double>(0.88),
            weight: _holdBottomMs.toDouble(),
          ),
        ]).animate(_breathCtrl)..addStatusListener((s) {
          if (s == AnimationStatus.completed) {
            _breathCtrl.forward(from: 0); // loop
          }
        });
  }

  Future<void> _ensureMedPlayer() async {
    if (_medPlayer != null) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    final p = AudioPlayer();
    await p.setLoopMode(LoopMode.one);
    await p.setAudioSource(AudioSource.asset('audio/meditation.ogg'));
    await p.setVolume(0.7);
    _medPlayer = p;

    // (Optional) Keep UI in sync if playback changes outside your button
    _medPlayer!.playingStream.listen((isPlaying) {
      if (mounted) setState(() => _medPlaying = isPlaying);
    });
  }

  Future<void> _toggleMeditation() async {
    await _ensureMedPlayer();

    if (_medPlaying) {
      setState(() => _medPlaying = false); // flip label immediately
      _medPlayer!.stop(); // don't await
    } else {
      setState(() => _medPlaying = true); // flip label immediately
      _medPlayer!.play(); // don't await (starts playing)
    }
  }

  void _toggleBreathing() {
    if (_breathing) {
      _breathCtrl.stop();
    } else {
      _breathCtrl.forward(from: 0);
    }
    setState(() => _breathing = !_breathing);
  }

  String _phaseText() {
    final t = _breathCtrl.value; // 0..1
    final pInhaleEnd = _inhaleMs / _totalMs;
    final pHoldTopEnd = (_inhaleMs + _holdTopMs) / _totalMs;
    final pExhaleEnd = (_inhaleMs + _holdTopMs + _exhaleMs) / _totalMs;
    if (!_breathing) return 'Tap the Bear to start';
    if (t < pInhaleEnd) return 'Inhale...';
    if (t < pHoldTopEnd) return 'Hold';
    if (t < pExhaleEnd) return 'Exhale...';
    return 'Hold';
  }

  // ========== Fortune Sun random quotes ==========
  String? _fortuneText;
  Timer? _fortuneTimer;

  final List<String> _quotes = [
    "The sun will rise, and we will try again.",
    "Calm mind brings inner strength.",
    "Breathe deeply, let worries fade.",
    "Every sunset brings the promise of a new dawn.",
    "Peace begins with a smile.",
    "Happiness radiates from within.",
    "The present moment is all you need.",
    "Shine like the sun, even behind the clouds.",
    "Every breath is a chance to begin again.",
    "Serenity is the true power of life.",
    "The quiet morning carries endless hope.",
    "Gratitude turns little things into enough.",
    "The world is more beautiful when the heart is calm.",
    "Light comes after the darkest night.",
    "Sometimes silence is the best answer.",
    "Smiles are free yet priceless.",
    "Simple things bring the greatest joy.",
    "Storms teach us how to dance in the rain.",
    "Your heart knows the way, run in that direction.",
    "Kindness is never wasted.",
    "Peace is found within, not outside.",
    "The softest hearts carry the strongest souls.",
    "Even small lights can brighten the darkest places.",
    "Your breath is your anchor.",
    "Slow down, life is not a race.",
    "Nature whispers healing words.",
    "The sun shines even when clouds cover it.",
    "Every ending is a hidden beginning.",
    "Balance is the secret to happiness.",
    "Time heals what reason cannot.",
    "Patience grows beautiful things.",
    "Life is not perfect, but moments can be.",
    "The soul needs rest to bloom.",
    "Dreams grow in silence.",
    "Self-love is the seed of peace.",
    "No storm lasts forever.",
    "Hearts speak the language of truth.",
    "Change is the rhythm of life.",
    "Even the moon borrows light.",
    "You are enough, always.",
    "True wealth is a peaceful heart.",
    "Soft rain grows green fields.",
    "Joy is not found, it is created.",
    "When you pause, the world softens.",
    "Gratitude unlocks abundance.",
    "Inner calm reflects outer beauty.",
    "Listen more, worry less.",
    "The best journeys are inward.",
    "Gentleness conquers anger.",
    "Moments matter more than years.",
    "A calm ocean mirrors the sky.",
    "Hope is stronger than fear.",
    "Hearts heal in time.",
    "Every flower blooms in its season.",
    "The breeze carries forgotten dreams.",
    "Smiles are bridges between souls.",
    "Peaceful thoughts invite peaceful days.",
    "Courage is quiet strength.",
    "Contentment is the purest wealth.",
    "Life flows like water, let it be.",
    "Breathe, and let it go.",
    "Happiness begins with acceptance.",
    "Trust the timing of your life.",
    "Rest is also progress.",
    "The stars remind us we are not alone.",
    "Stillness is where wisdom lives.",
    "Every seed hides a forest.",
    "Gentle words build strong bonds.",
    "Healing takes patience, not haste.",
    "The simplest joys are the richest.",
    "Your light is needed in this world.",
    "Calm seas create clear reflections.",
    "Smiles open locked hearts.",
    "Every step matters, no matter how small.",
    "Let go, and grow.",
    "A kind word lingers forever.",
    "Silence sometimes speaks loudest.",
    "Inner peace is true success.",
    "Be the warmth you seek.",
    "The present moment is home.",
    "Even shadows prove there is light.",
    "Gentleness is strength under control.",
    "Hearts bloom in kindness.",
    "Your breath is your safe place.",
    "The future begins with this breath.",
    "Time flows like a quiet river.",
    "A grateful heart is a magnet for peace.",
    "Peace makes every place beautiful.",
    "Even whispers carry wisdom.",
    "The earth heals those who listen.",
    "Smiles are sunlight for the soul.",
    "Let your worries rest in silence.",
    "The sky never stops being blue above the clouds.",
    "Every calm breath builds strength.",
    "Small joys make a big life.",
    "The heart always finds its way home.",
    "Still waters run deep.",
    "Happiness blooms when shared.",
    "Your calmness is your crown.",
    "Every day is a new chance for peace.",
    "The quiet soul shines the brightest.",
  ];

  void _showFortuneSun() {
    final rng = Random();
    setState(() => _fortuneText = _quotes[rng.nextInt(_quotes.length)]);
    _fortuneTimer?.cancel();
    _fortuneTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _fortuneText = null);
    });
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _fortuneTimer?.cancel();
    _medPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD9FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Relax',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFBFD9FB),
        elevation: 0,
      ),
      bottomNavigationBar: const Nav(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const SizedBox(height: 84),

          // ===== Bear (with halo) =====
          Center(
            child: GestureDetector(
              onTap: _toggleBreathing,
              child: Container(
                // for measurement
                key: _bearKey,
                child: AnimatedBuilder(
                  animation: _breathCtrl,
                  builder: (_, __) {
                    final scale = _breath.value;
                    final haloScale = 1.0 + (scale - 1.0) * 0.25;
                    final haloOpacity =
                        (0.25 + (scale - 0.88) / (1.22 - 0.88) * 0.20).clamp(
                          0.25,
                          0.45,
                        );
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: haloOpacity,
                          child: Transform.scale(
                            scale: haloScale,
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD6EC),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: scale,
                          child: Image.asset(
                            'images/Bear.png',
                            width: 160,
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: AnimatedBuilder(
              animation: _breathCtrl,
              builder: (_, __) => Text(
                _phaseText(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ===== Two square cards =====
          Row(
            children: [
              Expanded(
                child: _SquareCard(
                  iconPath: 'images/Headset.png',
                  title: _medPlaying ? 'Stop Meditation' : 'Meditation',
                  onTap: _toggleMeditation,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SquareCard(
                  iconPath: 'images/Sun.png',
                  title: 'Fortune Sun',
                  onTap: _showFortuneSun,
                ),
              ),
            ],
          ),

          // Mini now-playing strip (visible only while meditation is active)
          /*
          if (_medPlaying) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.self_improvement),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Meditation is playing (loops)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _medLoading ? null : _toggleMeditation,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ],
              ),
            ),
          ],
          */
          if (_fortuneText != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _fortuneText!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // White Noise Mixer button (outside balloon card)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.graphic_eq),
              label: const Text('White Noise Mixer'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WhiteNoisePage()),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ===== Balloons: button → group still → fly to bear top → tap to reset =====
          BalloonToggleCard(bearKey: _bearKey),
        ],
      ),
    );
  }
}

// ================== Shared square card ==================
class _SquareCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback onTap;
  const _SquareCard({
    required this.iconPath,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(iconPath, width: 60, height: 60, fit: BoxFit.contain),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== Balloon card (auto target height) ==================
enum _BalloonStage { button, ready, flying, docked }

class BalloonToggleCard extends StatefulWidget {
  const BalloonToggleCard({super.key, required this.bearKey});
  final GlobalKey bearKey; // bear position key

  @override
  State<BalloonToggleCard> createState() => _BalloonToggleCardState();
}

class _BalloonToggleCardState extends State<BalloonToggleCard>
    with TickerProviderStateMixin {
  _BalloonStage _stage = _BalloonStage.button;

  late final AnimationController _flyCtrl;
  late final Animation<double> _t;

  // Rise pixels (positive moves up here so it's intuitive in code)
  double _risePx = 160.0;

  // Launch baseline (bottom of visible area inside card)
  final GlobalKey _originKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _flyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _t = CurvedAnimation(parent: _flyCtrl, curve: Curves.easeOutCubic);

    _flyCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _stage = _BalloonStage.docked); // dock at top
      }
    });
  }

  @override
  void dispose() {
    _flyCtrl.dispose();
    super.dispose();
  }

  // Compute distance "card bottom → bear top"
  void _computeRise() {
    final bearBox =
        widget.bearKey.currentContext?.findRenderObject() as RenderBox?;
    final originBox =
        _originKey.currentContext?.findRenderObject() as RenderBox?;
    if (bearBox == null || originBox == null) return;

    final bearTop = bearBox.localToGlobal(Offset.zero).dy + 6; // small margin
    final originBottom = originBox
        .localToGlobal(Offset(0, originBox.size.height))
        .dy;

    setState(() => _risePx = (originBottom - bearTop) + 29); // positive up
  }

  void _onTap() {
    if (_stage == _BalloonStage.button) {
      setState(
        () => _stage = _BalloonStage.ready,
      ); // first: show still balloons
    } else if (_stage == _BalloonStage.ready) {
      _computeRise();
      setState(() => _stage = _BalloonStage.flying); // second: fly
      _flyCtrl.forward(from: 0);
    } else if (_stage == _BalloonStage.docked) {
      setState(() {
        _stage = _BalloonStage.button; // third: reset
        _flyCtrl.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _onTap,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  key: _originKey,
                  height: _stage == _BalloonStage.button ? 0 : 140,
                  child: _stage == _BalloonStage.button
                      ? const SizedBox.shrink()
                      : AnimatedBuilder(
                          animation: _t,
                          builder: (_, __) {
                            final t = _stage == _BalloonStage.flying
                                ? _t.value
                                : (_stage == _BalloonStage.docked ? 1.0 : 0.0);

                            double y(double base) => -_risePx * t * base; // up
                            double spread(double maxDx) {
                              final s = Curves.easeInOut.transform(
                                (t - 0.1).clamp(0, 1),
                              );
                              return maxDx * s; // left-right spread
                            }

                            return Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                _BalloonSprite(
                                  dx: -spread(60),
                                  dy: y(1.00),
                                  colors: const [
                                    Color(0xFFFF9FB9),
                                    Color(0xFFFFC8D8),
                                  ],
                                  stringBend: -18,
                                ),
                                _BalloonSprite(
                                  dx: 0,
                                  dy: y(1.05),
                                  colors: const [
                                    Color(0xFFB7D7F8),
                                    Color(0xFFD8E9FF),
                                  ],
                                  stringBend: 0,
                                ),
                                _BalloonSprite(
                                  dx: spread(60),
                                  dy: y(0.95),
                                  colors: const [
                                    Color(0xFFFFEB99),
                                    Color(0xFFFFF5C7),
                                  ],
                                  stringBend: 18,
                                ),
                              ],
                            );
                          },
                        ),
                ),

                const SizedBox(height: 12),

                // Status text
                Text(
                  _stage == _BalloonStage.button
                      ? "Tap to show the balloons"
                      : (_stage == _BalloonStage.ready
                            ? "Tap again to let them fly"
                            : (_stage == _BalloonStage.flying
                                  ? "Flying…"
                                  : "Balloons docked – tap to reset")),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "and Relax",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
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

// =============== Single balloon (gradient + highlight + curved string) ===============
class _BalloonSprite extends StatelessWidget {
  final double dx, dy;
  final List<Color> colors;
  final double stringBend;
  const _BalloonSprite({
    required this.dx,
    required this.dy,
    required this.colors,
    required this.stringBend,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Body
          Stack(
            alignment: Alignment.topLeft,
            children: [
              Container(
                width: 46,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                top: 12,
                child: Container(
                  width: 10,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          // String
          SizedBox(
            width: 46,
            height: 50,
            child: CustomPaint(painter: _StringPainter(bendX: stringBend)),
          ),
        ],
      ),
    );
  }
}

class _StringPainter extends CustomPainter {
  final double bendX;
  _StringPainter({required this.bendX});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..quadraticBezierTo(
        size.width / 2 + bendX,
        size.height * 0.55,
        size.width / 2,
        size.height,
      );
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _StringPainter old) => old.bendX != bendX;
}
