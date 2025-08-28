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
      color: Colors.grey[200], // background color for the nav bar
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Image.asset("images/Home.png", width: 80, height: 80),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Home()),
              );
            },
          ),
          IconButton(
            icon: Image.asset("images/Diary.png", width: 80, height: 80),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Diary()),
              );
            },
          ),
          IconButton(
            icon: Image.asset("images/Relax.png", width: 80, height: 80),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Relax()),
              );
            },
          ),
          IconButton(
            icon: Image.asset("images/Profile.png", width: 80, height: 80),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Profile()),
              );
            },
          ),
        ],
      ),
    );
  }
}
