import 'package:flutter/material.dart';
import 'package:gymfit/pages/quick_start_page.dart';

class QuickStartOverlay {
  static OverlayEntry? _minibarEntry;
  static List<QuickStartExercise> selectedExercises = [];
  static bool _wasMinibarVisible = false;
  static double? _originalBottomOffset;

  /// Checks if the minibar is currently visible
  static bool get isMinibarVisible => _minibarEntry != null;

  /// Hides the minibar and remembers if it was visible
  static void hideMinibarWithMemory() {
    // Only update the flag if we're not already tracking a hidden state
    if (!_wasMinibarVisible) {
      _wasMinibarVisible = _minibarEntry != null;
    }
    hideMinibar();
  }

  /// Shows the minibar only if it was previously visible
  static void restoreMinibarIfNeeded(BuildContext context) {
    if (_wasMinibarVisible) {
      // Add a small delay to ensure we're in the right context
      Future.delayed(const Duration(milliseconds: 100), () {
        // Use root navigator context to ensure consistent positioning
        final rootContext = Navigator.of(context, rootNavigator: true).context;
        _showMinibarWithStoredPosition(rootContext);
        _wasMinibarVisible = false; // Reset the flag
        _originalBottomOffset = null; // Reset stored position
      });
    }
  }

  /// Internal method to show minibar with consistent positioning
  static void _showMinibarWithStoredPosition(BuildContext context) {
    hideMinibar();
    final overlayState = Navigator.of(context, rootNavigator: true).overlay!;
    
    // Calculate bottom offset using the root context
    final mediaQuery = MediaQuery.of(context);
    final bottomOffset = mediaQuery.padding.bottom + kBottomNavigationBarHeight;
    
    _minibarEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16.0,
        right: 16.0,
        bottom: bottomOffset,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Main tap area for opening Quick Start
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      hideMinibar();
                      openQuickStart(context);
                    },
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
                // Cancel button
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => _showCancelConfirmation(context),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlayState.insert(_minibarEntry!);
  }

  /// Force show minibar for testing purposes
  static void forceShowMinibar(BuildContext context) {
    showMinibar(context);
  }

  /// Opens the full Quick Start page without the persistent nav bar, sliding up from bottom.
  static void openQuickStart(BuildContext context) {
    hideMinibar();
    // Open Quick Start page without nav bar, sliding up over 200ms
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) => QuickStartPage(initialSelectedExercises: selectedExercises),
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
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Main tap area for opening Quick Start
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      hideMinibar();
                      openQuickStart(ctx);
                    },
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
                // Cancel button
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => _showCancelConfirmation(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
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
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Main tap area for opening Quick Start
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      hideMinibar();
                      openQuickStart(context);
                    },
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
                // Cancel button
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => _showCancelConfirmation(context),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
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

  /// Shows confirmation dialog before canceling Quick Start session
  static Future<void> _showCancelConfirmation(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Workout'),
          content: const Text('Are you sure you want to end workout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Cancel the Quick Start session
      selectedExercises.clear();
      hideMinibar();
      _wasMinibarVisible = false; // Reset state
    }
  }

  /// Public method to show cancel confirmation (for use in Quick Start page)
  static Future<void> showCancelConfirmation(BuildContext context) async {
    await _showCancelConfirmation(context);
  }
} 