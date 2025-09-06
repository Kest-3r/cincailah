// lib/pages/home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/nav.dart';
import '../pages/deadline.dart';
import '../pages/treehole.dart';
import '../pages/sign_up.dart';
import '../pages/login.dart';
import '../pages/welcome.dart';
import '../pages/ai_companion.dart';
import 'ai.dart';
import 'deadline.dart';
import 'treehole.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ 获取当前用户
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? user?.email?.split('@')[0] ?? "User";

    return Scaffold(
      backgroundColor: const Color(0xFFBFD9FB),
      bottomNavigationBar: const Nav(currentIndex: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),

          // ==== 顶部问候 ====
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("images/Sun.png", width: 70, height: 70),
                const SizedBox(width: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hi, $username 👋", // ✅ 显示真实用户名
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "How are you today?",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ==== AI Companion ====
          _HomeCard(
            iconPath: 'images/AI.png',
            title: 'AI Companion',
            subtitle: 'Chat about study, mood, or anything',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AICompanion()),
              );
            },
          ),
          const SizedBox(height: 16),

          // ==== Deadlines ====
          _HomeCard(
            iconPath: 'images/Calender.png', // 注意文件名
            title: 'Deadlines',
            subtitle: 'The deadlines time will appear in here',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Deadline()),
              );
            },
          ),
          const SizedBox(height: 16),

          // ==== Treehole ====
          _HomeCard(
            iconPath: 'images/Tree.png',
            title: 'Tree hole',
            subtitle:
                'The place like childhood where you can write the things you want',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Treehole()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeCard({
    required this.iconPath,
    required this.title,
    required this.subtitle,
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(iconPath, width: 50, height: 50),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
