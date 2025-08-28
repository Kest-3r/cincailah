import 'package:flutter/material.dart';
import '../widgets/nav.dart';

class Diary extends StatelessWidget {
  const Diary({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Welcome to Diary"),
      ),
      bottomNavigationBar: Nav(),
    );
  }
}
