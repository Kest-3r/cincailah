// lib/pages/ai.dart
import 'package:flutter/material.dart';

class Ai extends StatefulWidget {
  const Ai({super.key});
  @override
  State<Ai> createState() => _AiState();
}

class _AiState extends State<Ai> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Companion")),
      body: const Center(child: Text("Hello, I am your AI Companion!")),
    );
  }
}
