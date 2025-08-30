// lib/pages/relax.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/nav.dart';
import 'package:audioplayers/audioplayers.dart';

class Relax extends StatefulWidget {
  const Relax({super.key});
  @override
  State<Relax> createState() => _RelaxState();
}

class _RelaxState extends State<Relax> with TickerProviderStateMixin {
  // ========== 小熊呼吸（明显 + 文案同步） ==========
  late final AnimationController _breathCtrl;
  late final Animation<double> _breath;
  bool _breathing = false;

  // 吸/停/呼/停（毫秒）
  static const int _inhaleMs = 5000;
  static const int _holdTopMs = 300;
  static const int _exhaleMs = 6000;
  static const int _holdBottomMs = 300;
  static const int _totalMs =
      _inhaleMs + _holdTopMs + _exhaleMs + _holdBottomMs;

  // 用于测量小熊位置（供气球卡片计算目标高度）
  final GlobalKey _bearKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    // 0.88 -> 1.22 (吸) -> 1.22(停) -> 0.88(呼) -> 0.88(停)
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
            _breathCtrl.forward(from: 0); // 循环
          }
        });
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

  // ========== Fortune Sun 随机语录 ==========
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

  void _showMeditationTip() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('5 Minutes meditation'),
        content: const Text(
          'Music coming soon.\nFor now, take a slow deep breath and enjoy the moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _fortuneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD9FB),
      appBar: AppBar(
        title: const Text('Relax'),
        centerTitle: true,
        backgroundColor: const Color(0xFFBFD9FB),
        elevation: 0,
      ),
      bottomNavigationBar: const Nav(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const SizedBox(height: 84),

          // ===== 顶部小熊（带光圈） =====
          Center(
            child: GestureDetector(
              onTap: _toggleBreathing,
              child: Container(
                // 用于测量位置
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

          // ===== 两张方形卡片 =====
          Row(
            children: [
              Expanded(
                child: _SquareMeditationCard(
                  iconPath: 'images/Headset.png',
                  title: '5 Minutes',
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

          // Fortune 文案（放在气球卡片之上，避免遮挡）
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

          // ===== 气球：按钮 → 静止聚拢 → 起飞到小熊头顶停住 → 再点复位 =====
          BalloonToggleCard(bearKey: _bearKey),
        ],
      ),
    );
  }
}

// ================== 公用方形卡片 ==================
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

class _SquareMeditationCard extends StatefulWidget {
  final String iconPath;
  final String title;
  const _SquareMeditationCard({required this.title, required this.iconPath});

  @override
  State<_SquareMeditationCard> createState() => _SquareMeditationCardState();
}

class _SquareMeditationCardState extends State<_SquareMeditationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _soundAnimationController;
  late final AudioPlayer _audioPlayer;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _soundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _soundAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleMeditation() async {
    if (isPlaying) {
      _soundAnimationController.stop();
      //await _audioPlayer.stop();
    } else {
      _soundAnimationController.repeat();
      //await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      //await _audioPlayer.play(AssetSource('sounds/meditation.mp3'));
    }

    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _toggleMeditation,
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // soundAnimations only when playing (hidden otherwise)
              if (isPlaying)
                SizedBox(
                  width: 100,
                  height: 100,
                  child: AnimatedBuilder(
                    animation: _soundAnimationController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: List.generate(3, (index) {
                          final progress =
                              (_soundAnimationController.value + index / 3) %
                              1.0;
                          final size = 40 + (progress * 60);
                          final opacity = (1 - progress).clamp(0.0, 1.0);

                          return Opacity(
                            opacity: opacity,
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),

              // Original card layout (icon + title)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    widget.iconPath,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ================== 气球卡片（自适应飞行高度） ==================
enum _BalloonStage { button, ready, flying, docked }

class BalloonToggleCard extends StatefulWidget {
  const BalloonToggleCard({super.key, required this.bearKey});
  final GlobalKey bearKey; // 小熊位置 key

  @override
  State<BalloonToggleCard> createState() => _BalloonToggleCardState();
}

class _BalloonToggleCardState extends State<BalloonToggleCard>
    with TickerProviderStateMixin {
  _BalloonStage _stage = _BalloonStage.button;

  late final AnimationController _flyCtrl;
  late final Animation<double> _t;

  // 需要上升的像素（负值向上）
  double _risePx = -160.0;

  // 起飞基准位置（卡片内部可视区的底部）
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
        setState(() => _stage = _BalloonStage.docked); // 顶部停住
      }
    });
  }

  @override
  void dispose() {
    _flyCtrl.dispose();
    super.dispose();
  }

  // 计算“卡片底部 → 小熊顶部”的距离，得到上升像素
  void _computeRise() {
    final bearBox =
        widget.bearKey.currentContext?.findRenderObject() as RenderBox?;
    final originBox =
        _originKey.currentContext?.findRenderObject() as RenderBox?;
    if (bearBox == null || originBox == null) return;

    final bearTop = bearBox.localToGlobal(Offset.zero).dy + 6; // 稍微留白
    final originBottom = originBox
        .localToGlobal(Offset(0, originBox.size.height))
        .dy;

    setState(() => _risePx = (bearTop - originBottom) - 14); // 再上移一点
  }

  void _onTap() {
    if (_stage == _BalloonStage.button) {
      setState(() => _stage = _BalloonStage.ready); // 第一次：出现静止气球
    } else if (_stage == _BalloonStage.ready) {
      _computeRise();
      setState(() => _stage = _BalloonStage.flying); // 第二次：起飞
      _flyCtrl.forward(from: 0);
    } else if (_stage == _BalloonStage.docked) {
      setState(() {
        _stage = _BalloonStage.button; // 第三次：复位
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

                            double y(double base) => _risePx * t * base; // 上升
                            double spread(double maxDx) {
                              final s = Curves.easeInOut.transform(
                                (t - 0.1).clamp(0, 1),
                              );
                              return maxDx * s; // 左右散开
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
                const SizedBox(height: 6),
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

// =============== 单个气球（渐变 + 高光 + 弧线绳） ===============
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
          // 球体
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
          // 细绳
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
