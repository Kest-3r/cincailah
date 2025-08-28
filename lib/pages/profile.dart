import 'package:flutter/material.dart';
import '../widgets/nav.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Welcome to Profile"),
      ),
      bottomNavigationBar: Nav(),
    );
  }
}
