import 'package:flutter/material.dart';
import 'package:gymfit/pages/quick_start_page.dart';

class QuickStartOverlay {
  static OverlayEntry? _minibarEntry;

  /// Opens the full Quick Start page without the persistent nav bar, sliding up from bottom.
  static void openQuickStart(BuildContext context) {
    hideMinibar();
    // Open Quick Start page without nav bar, sliding up over 200ms
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) => const QuickStartPage(),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (ctx, animation, secAnim, child) {
          final tween = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero);
          return SlideTransition(
            position: tween.animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  /// Minimizes the Quick Start page and shows a non-blocking minibar above the bottom nav bar.
  static Future<void> minimize(BuildContext context) async {
    hideMinibar();
    // Capture overlay and padding before async gap
    final overlayState = Navigator.of(context, rootNavigator: true).overlay!;
    final paddingBottom = MediaQuery.of(context).padding.bottom;
    // Pop the Quick Start page
    Navigator.of(context, rootNavigator: true).pop();
    // Delay to allow slide-down animation to complete
    await Future.delayed(const Duration(milliseconds: 200));
    // Build and insert the minibar entry using stored values
    final bottomOffset = paddingBottom + kBottomNavigationBarHeight;
    _minibarEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 16.0,
        right: 16.0,
        bottom: bottomOffset,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onTap: () {
              hideMinibar();
              openQuickStart(ctx);
            },
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.keyboard_arrow_up, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'Quick Start',
                    style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlayState.insert(_minibarEntry!);
  }

  /// Shows the minimized Quick Start bar above the bottom nav bar.
  static void showMinibar(BuildContext context) {
    hideMinibar();
    final overlayState = Navigator.of(context, rootNavigator: true).overlay!;
    final bottomOffset = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;
    _minibarEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16.0,
        right: 16.0,
        bottom: bottomOffset,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onTap: () {
              hideMinibar();
              openQuickStart(context);
            },
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.keyboard_arrow_up, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'Quick Start',
                    style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlayState.insert(_minibarEntry!);
  }

  /// Hides the minimized Quick Start bar if present.
  static void hideMinibar() {
    _minibarEntry?.remove();
    _minibarEntry = null;
  }
} 