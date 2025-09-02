import 'package:flutter/material.dart';

// 用别名，避免命名冲突
import '../pages/home.dart' as pages;
import '../pages/diary.dart' as pages;
import '../pages/relax.dart' as pages;
import '../pages/profile.dart' as pages;

/// 底部导航（图片优先，找不到图片时自动回退到 Icon+文字）
class Nav extends StatelessWidget {
  /// 当前索引（0:Home 1:Diary 2:Relax 3:Profile）
  final int currentIndex;
  const Nav({super.key, this.currentIndex = -1});

  void _go(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// 一个按钮：先尝试图片，失败就用 Icon+文字
  Widget _navButton({
    required BuildContext context,
    required String assetPath,
    required IconData fallbackIcon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final color = selected ? Colors.black : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Image.asset(
              assetPath,
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, size: 20, color: color),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Home
          _navButton(
            context: context,
            assetPath: 'images/Home.png',
            fallbackIcon: Icons.home_outlined,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => _go(context, pages.Home()),
          ),
          // Diary
          _navButton(
            context: context,
            assetPath: 'images/Diary.png',
            fallbackIcon: Icons.edit_calendar_outlined,
            label: 'Diary',
            selected: currentIndex == 1,
            onTap: () => _go(context, pages.Diary()), // ⚠️ 大写 D
          ),
          // Relax
          _navButton(
            context: context,
            assetPath: 'images/Relax.png',
            fallbackIcon: Icons.spa_outlined,
            label: 'Relax',
            selected: currentIndex == 2,
            onTap: () => _go(context, pages.Relax()),
          ),
          // Profile
          _navButton(
            context: context,
            assetPath: 'images/Profile.png',
            fallbackIcon: Icons.person_outline,
            label: 'Profile',
            selected: currentIndex == 3,
            onTap: () => _go(context, pages.Profile()),
          ),
        ],
      ),
    );
  }
}
