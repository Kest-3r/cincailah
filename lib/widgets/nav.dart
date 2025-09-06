import 'package:flutter/material.dart';

// 每个页面用不同别名
import '../pages/home.dart' as home;
import '../pages/diary.dart' as diary;
import '../pages/relax.dart' as relax;
import '../pages/profile.dart' as profile;

/// 底部导航
class Nav extends StatelessWidget {
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 瘦身：减少左右内边距
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Image.asset(
              assetPath,
              width: 24,   // 瘦身：图标由 28 → 24
              height: 24,  // 瘦身：图标由 28 → 24
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, size: 18, color: color), // 瘦身：Icon 由 20 → 18
            ),
            const SizedBox(width: 4), // 瘦身：间距由 6 → 4
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13, // 瘦身：字体稍微小一点（默认 14）
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      child: Container(
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
            _navButton(
              context: context,
              assetPath: 'images/Home.png',
              fallbackIcon: Icons.home_outlined,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => _go(context, home.Home()),
            ),
            _navButton(
              context: context,
              assetPath: 'images/Diary.png',
              fallbackIcon: Icons.edit_calendar_outlined,
              label: 'Diary',
              selected: currentIndex == 1,
              onTap: () => _go(context, diary.Diary()),
            ),
            _navButton(
              context: context,
              assetPath: 'images/Relax.png',
              fallbackIcon: Icons.spa_outlined,
              label: 'Relax',
              selected: currentIndex == 2,
              onTap: () => _go(context, relax.Relax()),
            ),
            _navButton(
              context: context,
              assetPath: 'images/Profile.png',
              fallbackIcon: Icons.person_outline,
              label: 'Profile',
              selected: currentIndex == 3,
              onTap: () => _go(context, profile.Profile()),
            ),
          ],
        ),
      ),
    );
  }
}
