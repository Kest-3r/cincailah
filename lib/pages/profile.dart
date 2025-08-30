// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/nav.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});
  @override
  State<Profile> createState() => _Profile();
}

class _Profile extends State<Profile> {
  final user = FirebaseAuth.instance.currentUser;
  final String email = FirebaseAuth.instance.currentUser?.email ?? 'No email';
  final String imagePath =
      FirebaseAuth.instance.currentUser?.photoURL ?? 'images/Sun.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFBFD9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFD9FB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "User Profile",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100), // spacing from top
                UserProfile(
                  image: imagePath,
                  line1: email,
                  line2: "Lorem: ipsum dolor sit amet",
                ),

                const SizedBox(height: 80), // spacing below header),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Nav(),
    );
  }
}

class UserProfile extends StatelessWidget {
  final String? image;
  final String line1;
  final String line2;

  const UserProfile({
    super.key,
    required this.image,
    required this.line1,
    required this.line2,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider avatarProvider;
    if (image != null && image!.startsWith('http')) {
      avatarProvider = NetworkImage(image!);
    } else {
      avatarProvider = AssetImage('images/Sun.png');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Profile Picture with placeholder
        // Two lines of user info
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture Placeholder
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: avatarProvider,
            ),
            const SizedBox(height: 20),
            //User Info
            Text(
              "Email: $line1",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              line2,
              style: const TextStyle(fontSize: 20, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}
