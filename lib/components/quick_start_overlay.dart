import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/pages/workout/quick_start_page.dart';

class QuickStartOverlay {
  static OverlayEntry? _minibarEntry;
  static List<QuickStartExercise> selectedExercises = [];
  static bool _wasMinibarVisible = false;
  static Timer? _timer;
  static Duration _elapsedTime = Duration.zero;
  static DateTime? _startTime;
  static VoidCallback? _pageUpdateCallback;
  static bool _isPaused = false;
  static Duration _pausedTime = Duration.zero;

  /// Get current elapsed time
  static Duration get elapsedTime => _elapsedTime;

  /// Get current pause state
  static bool get isPaused => _isPaused;

  /// Get workout start time
  static DateTime? get startTime => _startTime;

  /// Set callback for page updates
  static void setPageUpdateCallback(VoidCallback? callback) {
    _pageUpdateCallback = callback;
  }

  /// Checks if the minibar is currently visible
  static bool get isMinibarVisible => _minibarEntry != null;

  /// Start the timer
  static void startTimer() {
    if (_timer != null) return; // Don't start multiple timers
    _startTime = DateTime.now().subtract(_elapsedTime);
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _elapsedTime = DateTime.now().difference(_startTime!);
        _updateMinibar();
        _pageUpdateCallback?.call();
      }
    });
  }

  /// Pause the timer
  static void pauseTimer() {
    if (_timer != null && !_isPaused) {
      _isPaused = true;
      _pausedTime = _elapsedTime;
      _updateMinibar();
      _pageUpdateCallback?.call();
    }
  }

  /// Resume the timer
  static void resumeTimer() {
    if (_timer != null && _isPaused) {
      _isPaused = false;
      _startTime = DateTime.now().subtract(_pausedTime);
      _updateMinibar();
      _pageUpdateCallback?.call();
    }
  }

  /// Toggle pause/resume
  static void togglePause() {
    if (_isPaused) {
      resumeTimer();
    } else {
      pauseTimer();
    }
  }

  /// Stop the timer
  static void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isPaused = false;
  }

  /// Reset the timer
  static void resetTimer() {
    stopTimer();
    _elapsedTime = Duration.zero;
    _startTime = null;
    _isPaused = false;
    _pausedTime = Duration.zero;
  }

  /// Format duration for display
  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  /// Update the minibar to reflect current timer state
  static void _updateMinibar() {
    if (_minibarEntry != null) {
      _minibarEntry!.markNeedsBuild();
    }
  }

  /// Widget builder for the timer display
  static Widget _buildTimerDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FaIcon(
          FontAwesomeIcons.stopwatch,
          color: Colors.black,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          _formatDuration(_elapsedTime),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

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
      // Capture the context before the async operation
      final rootContext = Navigator.of(context, rootNavigator: true).context;
      
      // Add a small delay to ensure we're in the right context
      Future.delayed(const Duration(milliseconds: 100), () {
        if (rootContext.mounted) {
          _showMinibarWithStoredPosition(rootContext);
          _wasMinibarVisible = false; // Reset the flag
        }
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
                // Up arrow on the far left
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                // Main tap area for opening Quick Start
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      hideMinibar();
                      openQuickStart(context);
                    },
                    child: _buildTimerDisplay(),
                  ),
                ),
                // Pause/Resume button
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: GestureDetector(
                    onTap: () => togglePause(),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: FaIcon(
                        _isPaused ? FontAwesomeIcons.play : FontAwesomeIcons.pause,
                        color: Colors.black54,
                        size: 16,
                      ),
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
    final navigator = Navigator.of(context, rootNavigator: true);
    
    // Pop the Quick Start page
    navigator.pop();
    
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
                // Up arrow on the far left
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                // Main tap area for opening Quick Start
                Expanded(
                                      child: GestureDetector(
                      onTap: () {
                        hideMinibar();
                        openQuickStart(ctx);
                      },
                      child: _buildTimerDisplay(),
                    ),
                ),
                // Pause/Resume button
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: GestureDetector(
                    onTap: () => togglePause(),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: FaIcon(
                        _isPaused ? FontAwesomeIcons.play : FontAwesomeIcons.pause,
                        color: Colors.black54,
                        size: 16,
                      ),
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
                // Up arrow on the far left
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                // Main tap area for opening Quick Start
                Expanded(
                                      child: GestureDetector(
                      onTap: () {
                        hideMinibar();
                        openQuickStart(context);
                      },
                      child: _buildTimerDisplay(),
                    ),
                ),
                // Pause/Resume button
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: GestureDetector(
                    onTap: () => togglePause(),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: FaIcon(
                        _isPaused ? FontAwesomeIcons.play : FontAwesomeIcons.pause,
                        color: Colors.black54,
                        size: 16,
                      ),
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
          title: const Text('Delete Workout'),
          content: const Text('Are you sure you want to delete workout?'),
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
      resetTimer();
      hideMinibar();
      _wasMinibarVisible = false; // Reset state
    }
  }

  /// Public method to show cancel confirmation (for use in Quick Start page)
  static Future<void> showCancelConfirmation(BuildContext context) async {
    await _showCancelConfirmation(context);
  }
} 