import 'package:flutter/material.dart';
import '../openai/ai_companion_service.dart';
import '../openai/chat_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/typing_indicator.dart';

class AICompanion extends StatefulWidget {
  const AICompanion({super.key});

  @override
  State<AICompanion> createState() => _AiCompanionState();
}

class _AiCompanionState extends State<AICompanion> {
  final TextEditingController _controller = TextEditingController();
  final ChatRepository _chatRepo = ChatRepository();
  final List<Map<String, String>> _messages =
      []; // {role: user/assistant, content: text}
  bool _isSending = false;
  bool _isTyping = false;
  final userId = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";
  /*Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isSending) return;

    final text = _controller.text.trim();
    _controller.clear();

    setState(() {
      _isSending = true;
      _messages.add({"role": "user", "content": text});
    });

    try {
      final reply = await AICompanionService.getReply(text);
      setState(() {
        _messages.add({"role": "assistant", "content": reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "assistant", "content": "⚠️ Error: $e"});
      });
    } finally {
      setState(() => _isSending = false);
    }
  }*/
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isSending) return;

    final text = _controller.text.trim();
    _controller.clear();
    setState(() {
      _isSending = true;
      _isTyping = true;
    });

    try {
      // Save user message
      await _chatRepo.addMessage(userId, text, "user");

      // Get AI reply
      final summary = await _chatRepo.getSummary(userId);
      final reply = await AICompanionService.getReply(text, summary: summary);

      setState(() {
        _isTyping = false;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      // Save AI reply
      await _chatRepo.addMessage(userId, reply, "assistant");
      final count = await _chatRepo.getMessageCount(userId);
      if (count % 10 == 0) {
        final recent = await _chatRepo.getRecentMessages(userId, limit: 20);
        final newSummary = await AICompanionService.summarizeConversation(
          recent,
        );
        await _chatRepo.updateSummary(userId, newSummary);
      }
    } catch (e, st) {
      print("❌ AI error: $e\n$st");

      // Save a fallback message
      await _chatRepo.addMessage(
        userId,
        "Miu couldn’t reply right now 🐾",
        "assistant",
      );
    } finally {
      setState(() {
        _isSending = false;
        _isTyping = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    AICompanionService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD9FB), // light blue background
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back button on the left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Centered title + description
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "Miu - AI Companion",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Your personal AI friend\nhere to chat and assist you",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _chatRepo.getMessages(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount:
                            docs.length +
                            (_isTyping ? 1 : 0), // 👈 add extra slot
                        itemBuilder: (context, index) {
                          if (_isTyping && index == docs.length) {
                            return const TypingIndicator();
                          }
                          final msg = docs[index].data();
                          final role = msg["role"] ?? "";
                          final text = msg["text"] ?? "";

                          final isUser = role == "user";

                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.blueAccent.withValues(alpha: 0.8)
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            // Input field
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Say something to Miu...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isSending
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.send),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
