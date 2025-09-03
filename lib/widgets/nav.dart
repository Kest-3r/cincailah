import 'package:flutter/material.dart';

// Distinct prefixes for clarity
import '../pages/home.dart' as home_page;
import '../pages/diary.dart' as diary_page;
import '../pages/relax.dart' as relax_page;
import '../pages/profile.dart' as profile_page;

/// Bottom navigation bar (image-first; falls back to Icon+text if image missing)
class Nav extends StatelessWidget {
  /// Current index (0: Home, 1: Diary, 2: Relax, 3: Profile)
  final int currentIndex;
  const Nav({super.key, this.currentIndex = -1});

  void _go(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(12),
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
          children: const [
            _NavItem(
              index: 0,
              assetPath: 'images/Home.png',
              label: 'Home',
              fallbackIcon: Icons.home_outlined,
            ),
            _NavItem(
              index: 1,
              assetPath: 'images/Diary.png',
              label: 'Diary',
              fallbackIcon: Icons.edit_calendar_outlined,
            ),
            _NavItem(
              index: 2,
              assetPath: 'images/Relax.png',
              label: 'Relax',
              fallbackIcon: Icons.spa_outlined,
            ),
            _NavItem(
              index: 3,
              assetPath: 'images/Profile.png',
              label: 'Profile',
              fallbackIcon: Icons.person_outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final String assetPath;
  final String label;
  final IconData fallbackIcon;

  const _NavItem({
    required this.index,
    required this.assetPath,
    required this.label,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Read selected state from parent via constructor if you prefer; here we infer from Nav.currentIndex
    final nav = context.findAncestorWidgetOfExactType<Nav>();
    final selected = nav?.currentIndex == index;
    final Color color = selected ? Colors.black : Colors.black87;

    void _go(Widget page) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }

    return Expanded(
      child: InkWell(
        onTap: () {
          switch (index) {
            case 0:
              _go(home_page.Home());
              break;
            case 1:
              _go(diary_page.Diary());
              break;
            case 2:
              _go(relax_page.Relax());
              break;
            case 3:
              _go(profile_page.Profile());
              break;
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF5FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          // Key trick: FittedBox scales DOWN the entire row (icon+text) if it barely overflows.
          // This keeps full labels visible and removes the 4.4 px overflow.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  assetPath,
                  width: 24, // slightly smaller to give breathing room
                  height: 24,
                  errorBuilder: (_, __, ___) =>
                      Icon(fallbackIcon, size: 22, color: color),
                ),
                const SizedBox(width: 6),
                // Full label, no ellipsis; FittedBox will downscale slightly if needed
                Text(
                  label,
                  softWrap: false,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
