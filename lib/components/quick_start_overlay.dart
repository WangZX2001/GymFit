import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:gymfit/pages/workout/quick_start_page_optimized.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class QuickStartOverlay {
  static OverlayEntry? _minibarEntry;
  static List<QuickStartExercise> selectedExercises = [];
  static String? customWorkoutName;

  static Timer? _timer;
  static Duration _elapsedTime = Duration.zero;
  static DateTime? _startTime;
  static VoidCallback? _pageUpdateCallback;
  static VoidCallback? _stateUpdateCallback;
  static bool _isPaused = false;
  static Duration _pausedTime = Duration.zero;
  static bool _shouldShowIntegratedMinibar = false; // Track integrated minibar state

  /// Get current elapsed time
  static Duration get elapsedTime => _elapsedTime;

  /// Get current pause state
  static bool get isPaused => _isPaused;

  /// Get workout start time
  static DateTime? get startTime => _startTime;

  /// Get whether integrated minibar should be shown
  static bool get shouldShowIntegratedMinibar => _shouldShowIntegratedMinibar && _timer != null;

  /// Set callback for page updates
  static void setPageUpdateCallback(VoidCallback? callback) {
    _pageUpdateCallback = callback;
  }

  /// Set callback for state updates (for navigation bar)
  static void setStateUpdateCallback(VoidCallback? callback) {
    _stateUpdateCallback = callback;
  }



  /// Update integrated minibar visibility
  static void _updateIntegratedMinibarState(bool visible) {
    if (_shouldShowIntegratedMinibar != visible) {
      _shouldShowIntegratedMinibar = visible;
      _stateUpdateCallback?.call();
    }
  }

  /// Checks if the minibar is currently visible
  static bool get isMinibarVisible => _minibarEntry != null || _shouldShowIntegratedMinibar;

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
    // Also update integrated minibar
    _stateUpdateCallback?.call();
  }

  /// Widget builder for the timer display
  static Widget _buildTimerDisplay() {
    return Builder(
      builder: (context) {
        final themeService = Provider.of<ThemeService>(context, listen: false);
        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.stopwatch,
                color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDuration(_elapsedTime),
                style: TextStyle(
                  color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build integrated minibar widget for navigation bar
  static Widget buildIntegratedMinibar(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _updateIntegratedMinibarState(false);
        openQuickStart(context);
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            // Up arrow on the far left
            Container(
              width: 32,
              height: 44,
              alignment: Alignment.center,
              child: Icon(
                Icons.keyboard_arrow_up,
                color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                size: 22,
              ),
            ),
            // Main tap area for opening Quick Start
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.stopwatch,
                      color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(_elapsedTime),
                      style: TextStyle(
                        color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Pause/Resume button
            Container(
              width: 36,
              height: 44,
              alignment: Alignment.center,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => togglePause(),
                  child: Container(
                    padding: const EdgeInsets.all(6.0),
                    child: FaIcon(
                      _isPaused ? FontAwesomeIcons.play : FontAwesomeIcons.pause,
                      color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            // Cancel button
            Container(
              width: 36,
              height: 44,
              alignment: Alignment.center,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showCancelConfirmation(context),
                  child: Container(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.close,
                      color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  /// Shows minibar if there's an active Quick Start and no minibar is currently visible
  static void showMinibarIfNeeded(BuildContext context) {
    if (selectedExercises.isNotEmpty && !isMinibarVisible) {
      showMinibar(context);
    }
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
        pageBuilder: (ctx, animation, secondaryAnimation) => QuickStartPageOptimized(
          initialSelectedExercises: selectedExercises,
          initialWorkoutName: customWorkoutName,
        ),
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

  /// Minimizes the Quick Start page without showing the minibar
  static Future<void> minimizeWithoutMinibar(BuildContext context) async {
    hideMinibar();

    
    // Capture navigator before async gap
    final navigator = Navigator.of(context, rootNavigator: true);
    
    // Pop the Quick Start page
    navigator.pop();
    
    // Delay to allow slide-down animation to complete
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Don't show the minibar - just return
  }

  /// Minimizes the Quick Start page and shows a non-blocking minibar above the bottom nav bar.
  static Future<void> minimize(BuildContext context) async {
    hideMinibar();
    
    // Capture navigator before async gap
    final navigator = Navigator.of(context, rootNavigator: true);
    
    // Pop the Quick Start page
    navigator.pop();
    
    // Delay to allow slide-down animation to complete
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Show integrated minibar in navigation bar
    _updateIntegratedMinibarState(true);
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
          child: Builder(
            builder: (context) {
              final themeService = Provider.of<ThemeService>(context, listen: false);
              return Container(
                height: 60,
                decoration: BoxDecoration(
                  color: themeService.currentTheme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    hideMinibar();
                    openQuickStart(context);
                  },
                  child: Row(
                    children: [
                      // Up arrow on the far left
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Builder(
                          builder: (context) {
                            final themeService = Provider.of<ThemeService>(context, listen: false);
                            return Icon(
                              Icons.keyboard_arrow_up,
                              color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                              size: 26,
                            );
                          },
                        ),
                      ),
                      // Main tap area for opening Quick Start
                      Expanded(
                        child: _buildTimerDisplay(),
                      ),
                      // Pause/Resume button
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => togglePause(),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              child: Builder(
                                builder: (context) {
                                  final themeService = Provider.of<ThemeService>(context, listen: false);
                                  return FaIcon(
                                    _isPaused ? FontAwesomeIcons.play : FontAwesomeIcons.pause,
                                    color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                                    size: 22,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Cancel button
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showCancelConfirmation(context),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              child: Builder(
                                builder: (context) {
                                  final themeService = Provider.of<ThemeService>(context, listen: false);
                                  return Icon(
                                    Icons.close,
                                    color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                                    size: 26,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
    _updateIntegratedMinibarState(false);
  }

  /// Shows confirmation dialog before canceling Quick Start session
  static Future<void> _showCancelConfirmation(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Workout'),
          content: const Text('Are you sure you want to cancel this workout?'),
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

      _updateIntegratedMinibarState(false); // Reset integrated minibar state
    }
  }

  /// Public method to show cancel confirmation (for use in Quick Start page)
  static Future<void> showCancelConfirmation(BuildContext context) async {
    await _showCancelConfirmation(context);
  }
} 