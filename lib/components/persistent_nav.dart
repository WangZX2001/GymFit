import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:gymfit/pages/home_page.dart';
import 'package:gymfit/pages/history_page.dart';
import 'package:gymfit/pages/workout/workout_page.dart';
import 'package:gymfit/pages/me_page.dart';
import 'package:persistent_bottom_nav_bar_v2/components/animated_icon_wrapper.dart';
import 'package:gymfit/components/quick_start_overlay.dart';

class PersistentNavBar extends StatefulWidget {
  final int initialIndex;

  const PersistentNavBar({super.key, this.initialIndex = 0});

  @override
  State<PersistentNavBar> createState() => _PersistentNavBarState();
}

class _PersistentNavBarState extends State<PersistentNavBar> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: widget.initialIndex);
  }

  List<PersistentTabConfig> _tabs() => [
        PersistentTabConfig(
          screen: const HomePage(),
          item: ItemConfig(
            icon: AnimatedIconWrapper(
              icon: AnimatedIcons.home_menu,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
            title: 'Home',
          ),
        ),
        PersistentTabConfig(
          screen: const HistoryPage(),
          item: ItemConfig(
            icon: const Icon(Icons.history),
            title: 'History',
          ),
        ),
        PersistentTabConfig(
          screen: const WorkoutPage(),
          item: ItemConfig(
            icon: const Icon(Icons.fitness_center),
            title: 'Workout',
          ),
        ),
        PersistentTabConfig(
          screen: const MePage(),
          item: ItemConfig(
            icon: const Icon(Icons.person),
            title: 'Me',
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      controller: _controller,
      tabs: _tabs(),
      navBarBuilder: (navBarConfig) => _NavBarWithIntegratedMinibar(
        navBarConfig: navBarConfig,
      ),
      screenTransitionAnimation: const ScreenTransitionAnimation(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }
}

class _NavBarWithIntegratedMinibar extends StatefulWidget {
  final NavBarConfig navBarConfig;

  const _NavBarWithIntegratedMinibar({
    required this.navBarConfig,
  });

  @override
  State<_NavBarWithIntegratedMinibar> createState() => _NavBarWithIntegratedMinibarState();
}

class _NavBarWithIntegratedMinibarState extends State<_NavBarWithIntegratedMinibar> {
  // Define consistent color for both navigation bar and minibar
  static const Color _navBarColor = Colors.white;

  @override
  void initState() {
    super.initState();
    // Listen for minibar state changes
    QuickStartOverlay.setStateUpdateCallback(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showQuickStartMinibar = QuickStartOverlay.shouldShowIntegratedMinibar;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _navBarColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Start Minibar (when active) with animation
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: showQuickStartMinibar
              ? Container(
                  height: 44,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  decoration: BoxDecoration(
                    color: _navBarColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QuickStartOverlay.buildIntegratedMinibar(context),
                )
              : const SizedBox.shrink(),
          ),
          
          // Divider line between minibar and navigation
          if (showQuickStartMinibar)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.grey.shade300,
            ),
          
          // Original Style2BottomNavBar
          Style2BottomNavBar(
            navBarConfig: widget.navBarConfig,
            navBarDecoration: NavBarDecoration(
              color: Colors.transparent, // Keep transparent to avoid double background
              borderRadius: BorderRadius.circular(0), // Match parent container
              boxShadow: [], // Parent container handles shadow
            ),
            itemAnimationProperties: const ItemAnimation(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
} 