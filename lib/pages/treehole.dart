import 'package:flutter/material.dart';
import '../widgets/nav.dart';

class Treehole extends StatelessWidget {
  const Treehole({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Treehole"),
      ),
      bottomNavigationBar: Nav(),
    );
  }
}
