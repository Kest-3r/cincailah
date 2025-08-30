import 'package:flutter/material.dart';
import '../widgets/nav.dart';
import '../pages/deadline.dart';
import '../pages/treehole.dart';
import '../pages/sign_up.dart';
import '../pages/login.dart';
import '../pages/welcome.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD9FB), // ✅ same background as Diary
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 100), // spacing from top
            ProfileHeader(
              iconPath: "images/Sun.png", // 🌞 give me your icon path
              line1: "Good Morning",
              line2: "Let’s make today great!",
            ),

            const SizedBox(height: 80), // spacing below header
            /*
            CustomButton(
              iconPath: "",
              title: "DEBUG",
              description: "testing",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Welcome()),
                );
              },
            ),
            */
            const SizedBox(height: 20),
            CustomButton(
              iconPath: "images/Calender.png",
              title: "Deadlines",
              description: "View deadlines",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Deadline()),
                );
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              iconPath: "images/Tree.png",
              title: "Treehole",
              description:
              "Write your thought anonymously\nNo names, just your feelings",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Treehole()),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Nav(), // ✅ stays at the bottom
    );
  }
}


class ProfileHeader extends StatelessWidget {
  final String iconPath;
  final String line1;
  final String line2;

  const ProfileHeader({
    super.key,
    required this.iconPath,
    required this.line1,
    required this.line2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🌞 Sun (or any icon you pass in via iconPath)
        Image.asset(
          iconPath,
          width: 120,
          height: 120,
        ),
        const SizedBox(width: 16),

        // Two lines of text
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              line1,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              line2,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CustomButton extends StatelessWidget {
  final String iconPath;
  final String title;
  final String description;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.iconPath,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        minimumSize: const Size(280, 80),
        alignment: Alignment.centerLeft,
      ),
      onPressed: onPressed,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            iconPath,
            width: 80,
            height: 80,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
