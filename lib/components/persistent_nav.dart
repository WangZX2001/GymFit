import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:gymfit/pages/home_page_2.dart';
import 'package:gymfit/pages/history_page.dart';
import 'package:gymfit/pages/workout_page.dart';
import 'package:gymfit/pages/me_page.dart';
import 'package:persistent_bottom_nav_bar_v2/components/animated_icon_wrapper.dart';

class PersistentNavBar extends StatelessWidget {
  final int initialIndex;

  const PersistentNavBar({Key? key, this.initialIndex = 0}) : super(key: key);

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
    final controller = PersistentTabController(initialIndex: initialIndex);
    return PersistentTabView(
      controller: controller,
      tabs: _tabs(),
      navBarBuilder: (navBarConfig) => Style2BottomNavBar(
        navBarConfig: navBarConfig,
        navBarDecoration: NavBarDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10),
          ],
        ),
        //Some animation styles allow you to change the animation of the icon when you click on it.
        itemAnimationProperties: const ItemAnimation(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        ),
        //Comment out the above itemAnimationProperties if some styles are not working.
      ),
      screenTransitionAnimation: const ScreenTransitionAnimation(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ),
    );
  }
} 