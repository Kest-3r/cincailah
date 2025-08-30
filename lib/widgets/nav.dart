import 'package:flutter/material.dart';
import '../../pages/home.dart';
import '../../pages/diary.dart';
import '../../pages/relax.dart';
import '../../pages/profile.dart';

class Nav extends StatelessWidget {
  const Nav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12), // space around the nav bar
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white, // background of the nav bar
        borderRadius: BorderRadius.circular(40), // 👈 curved edges
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            padding: EdgeInsets.zero, // 👈 removes extra space
            constraints: const BoxConstraints(), // 👈 removes default min size
            icon: Image.asset("images/Home.png", width: 60, height: 60),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Home()),
              );
            },
          ),
          IconButton(
            padding: EdgeInsets.zero, // 👈 removes extra space
            constraints: const BoxConstraints(), // 👈 removes default min size
            icon: Image.asset("images/Diary.png", width: 60, height: 60),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Diary()),
              );
            },
          ),
          IconButton(
            padding: EdgeInsets.zero, // 👈 removes extra space
            constraints: const BoxConstraints(), // 👈 removes default min size
            icon: Image.asset("images/Relax.png", width: 60, height: 60),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Relax()),
              );
            },
          ),
          IconButton(
            padding: EdgeInsets.zero, // 👈 removes extra space
            constraints: const BoxConstraints(), // 👈 removes default min size
            icon: Image.asset("images/Profile.png", width: 60, height: 60),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Profile()),
              );
            },
          ),
        ],
      ),
    );
  }
}
