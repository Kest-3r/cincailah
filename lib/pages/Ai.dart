// lib/pages/ai.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/nav.dart';

class Ai extends StatefulWidget {
  const Ai({super.key}); // ✅ const so `const Ai()` works

  @override
  State<Ai> createState() => _AiState();
}

class _AiState extends State<Ai> {
  final List<_Msg> _msgs = [
    _Msg.fromBot("Wish you good luck"),
  ];
  final _c = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  bool _typing = false;

  final _bot = _LocalChatService(); // swap with real API later

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _c.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _msgs.add(_Msg.fromUser(text));
      _c.clear();
    });
    _scrollToEnd();

    setState(() => _typing = true);
    try {
      final reply = await _bot.reply(text);
      if (!mounted) return;
      setState(() {
        _typing = false;
        _msgs.add(_Msg.fromBot(reply));
      });
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() => _typing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI error: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFBFD9FB);
    const headerBg = Color(0xFFD7E8FF);
    const panelRadius = 24.0;

    return Scaffold(
      backgroundColor: pageBg,
      bottomNavigationBar: const Nav(currentIndex: 0), // highlight Home tab
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
            child: Column(
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
                          'AI COMPANION',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // balance the back button
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.black.withOpacity(0.06)),

                // ===== Messages =====
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: ListView.builder(
                      controller: _scroll,
                      itemCount: _msgs.length + (_typing ? 1 : 0),
                      itemBuilder: (context, i) {
                        final isTypingItem = _typing && i == _msgs.length;
                        if (isTypingItem) {
                          return const _BotRow(child: _TypingBubble());
                        }
                        final m = _msgs[i];
                        return m.isUser
                            ? _UserRow(text: m.text)
                            : _BotRow(child: _BotBubble(text: m.text));
                      },
                    ),
                  ),
                ),

                // ===== Input bar =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _c,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Type a message…',
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: IconButton.filled(
                            onPressed: _sending ? null : _send,
                            icon: _sending
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.send_rounded),
                          ),
                        ),
                      ],
                    ),
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

/* ------------------------- Message rows ------------------------- */

class _UserRow extends StatelessWidget {
  final String text;
  const _UserRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Spacer(),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCF3FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Text(text, style: const TextStyle(fontSize: 14.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotRow extends StatelessWidget {
  final Widget child;
  const _BotRow({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar from your asset: images/AI.png
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'images/AI.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.smart_toy_outlined, size: 22, color: Color(0xFF5D6AA1)),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(child: child),
          const Spacer(),
        ],
      ),
    );
  }
}

class _BotBubble extends StatelessWidget {
  final String text;
  const _BotBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(right: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14.5)),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(right: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(), SizedBox(width: 4), _Dot(delayMs: 200),
          SizedBox(width: 4), _Dot(delayMs: 400),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delayMs;
  const _Dot({this.delayMs = 0});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void initState() {
    super.initState();
    if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _c.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.2, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: const CircleAvatar(radius: 3, backgroundColor: Colors.black54),
    );
  }
}

/* ------------------------- Local "AI" logic ------------------------- */

class _LocalChatService {
  Future<String> reply(String prompt) async {
    final p = prompt.toLowerCase();
    await Future.delayed(const Duration(milliseconds: 800)); // typing delay

    if (RegExp(r'\b(hi|hello|hey)\b').hasMatch(p)) {
      return "Hello! I’m your AI companion 🤖\nHow are you feeling today?";
    }
    if (p.contains("help")) {
      return "I’m here to help. Tell me what you need, and I’ll do my best!";
    }
    if (p.contains("sad") || p.contains("tired")|| p.contains("stress")) {
      return "I’m sorry you’re feeling that way. Try a slow deep breath: inhale 4s, hold 2s, exhale 6s 🌬️";
    }
    if (p.contains("joke")) {
      return "Why did the developer go broke?\nBecause they used up all their cache 😄";
    }
    if (p.contains("study") || p.contains("exam")) {
      return "Study tip: 25–5 focus cycles work great. 25 min focus + 5 min break. Want a checklist?";
    }
    if (p.contains("thanks") || p.contains("thank")) {
      return "You’re welcome! 🌟 Anything else I can do for you?";
    }
    if (p.contains("good luck") || p.contains("wish")) {
      return "Wishing you the best of luck! You’ve got this 💪✨";
    }

    return "Got it! Tell me more, or ask for a joke, a study tip, or a breathing guide.";
  }
}

/* ------------------------- Message model ------------------------- */

class _Msg {
  final String text;
  final bool isUser;
  final DateTime ts;
  _Msg(this.text, this.isUser, this.ts);
  _Msg.fromUser(String t) : this(t, true, DateTime.now());
  _Msg.fromBot(String t) : this(t, false, DateTime.now());
}
