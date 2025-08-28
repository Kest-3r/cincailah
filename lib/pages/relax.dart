import 'package:flutter/material.dart';
import '../widgets/nav.dart';

class Relax extends StatelessWidget {
  const Relax({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Welcome to Relax"),
      ),
      bottomNavigationBar: Nav(),
    );
  }
}
