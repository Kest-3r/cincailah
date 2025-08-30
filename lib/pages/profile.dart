import 'package:flutter/material.dart';
import '../widgets/nav.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});
  @override
  State<Profile> createState() => _Profile();
}

class _Profile extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFBFD9FB),
      body: Center(child: Text("Welcome to Profile")),
      bottomNavigationBar: Nav(),
    );
  }
}
