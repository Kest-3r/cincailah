import 'package:flutter/material.dart';
import '../widgets/nav.dart';

class Deadline extends StatelessWidget {
  const Deadline({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Deadline"),
      ),
      bottomNavigationBar: Nav(),
    );
  }
}
