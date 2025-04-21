import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

class MainNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MainNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onHomeTap() async {
    setState(() => _scale = 0.95);
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _scale = 1.0);

    widget.onTap(0);
  }

  @override
  Widget build(BuildContext context) {
    final iconList = <IconData>[
      Icons.person,
      Icons.settings,
    ];

    int getActiveIndex() {
      if (widget.currentIndex == 1) return 0;
      if (widget.currentIndex == 2) return 1;
      return -1;
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        AnimatedBottomNavigationBar(
          icons: iconList,
          activeIndex: getActiveIndex(),
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.defaultEdge,
          backgroundColor: Colors.grey[100],
          activeColor: const Color(0xFF69B5F1),
          inactiveColor: Colors.grey[400],
          onTap: (index) {
            widget.onTap(index == 0 ? 1 : 2);
          },
        ),
        Positioned(
          bottom: 10,
          child: GestureDetector(
            onTap: _onHomeTap,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 100),
              scale: _scale,
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    color: const Color(0xFF69B5F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Icon(Icons.home, size: 28, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
