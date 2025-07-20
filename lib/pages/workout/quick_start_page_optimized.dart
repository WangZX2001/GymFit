import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:gymfit/components/workout_name_editor.dart';
import 'package:gymfit/components/exercise_card.dart';
import 'package:gymfit/components/custom_workout_list.dart';
import 'package:gymfit/components/add_exercise_button.dart';
import 'package:gymfit/components/finish_workout_button.dart';
import 'package:gymfit/models/exercise_set.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/services/quick_start_state_manager.dart';
import 'package:gymfit/utils/workout_name_generator.dart';
import 'package:gymfit/utils/duration_formatter.dart';
import 'package:gymfit/services/theme_service.dart';

class QuickStartPageOptimized extends StatefulWidget {
  final List<QuickStartExercise> initialSelectedExercises;
  final String? initialWorkoutName;
  final bool showMinibarOnMinimize;

  const QuickStartPageOptimized({
    super.key,
    this.initialSelectedExercises = const <QuickStartExercise>[],
    this.initialWorkoutName,
    this.showMinibarOnMinimize = true,
  });

  @override
  State<QuickStartPageOptimized> createState() => _QuickStartPageOptimizedState();
}

class _QuickStartPageOptimizedState extends State<QuickStartPageOptimized> {
  late ScrollController _scrollController;
  late QuickStartStateManager _stateManager;
  final Map<QuickStartExercise, GlobalKey> _exerciseKeys = {};
  String? _cachedWorkoutName;
  bool _isWorkoutNameStable = false;


  @override
  void initState() {
    super.initState();

    // Initialize state manager
    _stateManager = QuickStartStateManager();
    _stateManager.initialize(
      initialExercises: widget.initialSelectedExercises,
      initialWorkoutName: widget.initialWorkoutName,
    );

    // Cache the initial workout name if provided
    if (widget.initialWorkoutName != null) {
      _cachedWorkoutName = widget.initialWorkoutName;
      _isWorkoutNameStable = true;
    }

    // Initialize scroll controller
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);



    // Start the shared timer in overlay if not already started
    QuickStartOverlay.startTimer();

    // Register for timer updates
    QuickStartOverlay.setPageUpdateCallback(() {
      if (mounted) {
        setState(() {});
      }
    });


  }

  void _onScroll() {
    // Don't change workout name app bar state during reorder mode
    if (_stateManager.isInReorderMode) {
      return;
    }

    // Show workout name in app bar when scrolled past the workout name card (approximately 100 pixels)
    const double threshold = 100.0;
    bool shouldShow = _scrollController.offset > threshold;

    if (shouldShow != _stateManager.showWorkoutNameInAppBar) {
      // Ensure workout name is stable before transition
      if (shouldShow && _stateManager.customWorkoutName != null) {
        _cachedWorkoutName = _stateManager.customWorkoutName;
        _isWorkoutNameStable = true;
      }
      
      // Auto-save workout name when it slides into the app bar during editing
      if (shouldShow && _stateManager.isEditingWorkoutName) {
        _stateManager.setEditingWorkoutName(false);
        _clearFocusAggressively();
        _stateManager.setPreventAutoFocus(true);

        // Re-enable interaction after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _stateManager.setPreventAutoFocus(false);
          }
        });
      }

      _stateManager.setShowWorkoutNameInAppBar(shouldShow);
      
      // Ensure workout name is cached when app bar becomes visible
      if (shouldShow && _cachedWorkoutName == null) {
        _cachedWorkoutName = _stateManager.customWorkoutName ?? 
            WorkoutNameGenerator.generateWorkoutName(
              customWorkoutName: _stateManager.customWorkoutName,
              selectedExercises: _stateManager.selectedExercises,
            );
        _isWorkoutNameStable = true;
      }
    }
  }

  void _clearFocusAggressively() {
    // Check if widget is still mounted and context is active
    if (!mounted) return;

    try {
      // Multiple approaches to ensure focus is completely cleared
      FocusScope.of(context).unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (e) {
      // Safely handle cases where context is no longer valid
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _handleWorkoutNameChanged(String name) {
    _stateManager.setCustomWorkoutName(name);
    // Cache the workout name to prevent shifting
    _cachedWorkoutName = name;
    _isWorkoutNameStable = true;
  }

  void _handleWorkoutNameToggle() {
    _stateManager.setEditingWorkoutName(!_stateManager.isEditingWorkoutName);
    
    // Reset cached name when starting to edit to allow dynamic updates
    if (_stateManager.isEditingWorkoutName) {
      _isWorkoutNameStable = false;
      _cachedWorkoutName = null;
    }
  }

  void _handleWorkoutNameSubmitted() {
    _stateManager.setEditingWorkoutName(false);
    _stateManager.setPreventAutoFocus(true);
    _clearFocusAggressively();

    // Re-enable interaction after a delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _stateManager.setPreventAutoFocus(false);
      }
    });
  }

  void _handleCustomWorkoutSelected(dynamic customWorkout) {
    _stateManager.loadCustomWorkout(customWorkout);
    
    // Cache the workout name immediately when loading a custom workout
    _cachedWorkoutName = customWorkout.name;
    _isWorkoutNameStable = true;
    
    // Scroll to the newly loaded exercises after the UI has been updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToNewExercises(_stateManager.selectedExercises);
      }
    });
  }

  void _handleRemoveExercise(QuickStartExercise exercise) {
    _stateManager.removeExercise(exercise);
    _exerciseKeys.remove(exercise); // Clean up key
  }

  void _handleRemoveSet(QuickStartExercise exercise, ExerciseSet set) {
    _stateManager.removeSetFromExercise(exercise, set);
  }

  void _handleWeightChanged(
    QuickStartExercise exercise,
    ExerciseSet set,
    double weight,
  ) {
    set.updateWeight(weight);
    QuickStartOverlay.selectedExercises = _stateManager.selectedExercises;
  }

  void _handleRepsChanged(
    QuickStartExercise exercise,
    ExerciseSet set,
    int reps,
  ) {
    set.updateReps(reps);
    QuickStartOverlay.selectedExercises = _stateManager.selectedExercises;
  }

  void _handleSetCheckedChanged(
    QuickStartExercise exercise,
    ExerciseSet set,
    bool checked,
  ) {
    _stateManager.updateSetChecked(exercise, set, checked);
    QuickStartOverlay.selectedExercises = _stateManager.selectedExercises;
  }

  void _handleAllSetsCheckedChanged(QuickStartExercise exercise, bool checked) {
    _stateManager.updateAllSetsChecked(exercise, checked);
    QuickStartOverlay.selectedExercises = _stateManager.selectedExercises;
  }

  void _handleAddSet(QuickStartExercise exercise) {
    _stateManager.addSetToExercise(exercise);
    QuickStartOverlay.selectedExercises = _stateManager.selectedExercises;
  }

  void _handleExercisesAdded() {
    _clearFocusAggressively();
    _stateManager.setPreventAutoFocus(true);
  }

  void _handleExercisesLoaded(List<QuickStartExercise> newExercises) {
    for (var exercise in newExercises) {
      _stateManager.addExercise(exercise);
    }
    QuickStartOverlay.selectedExercises = _stateManager.selectedExercises;

    // Clear focus again after state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _clearFocusAggressively();
        _scrollToNewExercises(newExercises);
      }
    });

    // Re-enable interaction after ensuring new fields are built
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _stateManager.setPreventAutoFocus(false);
      }
    });
  }

  void _scrollToNewExercises(List<QuickStartExercise> newExercises) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (newExercises.isEmpty) return;
      final firstNew = newExercises.first;
      final key = _exerciseKeys[firstNew];
      if (key != null && key.currentContext != null) {
        await Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleMinimize() {
    QuickStartOverlay.selectedExercises = _stateManager.selectedExercises;
    if (widget.showMinibarOnMinimize) {
      QuickStartOverlay.minimize(context);
    } else {
      QuickStartOverlay.minimizeWithoutMinibar(context);
    }
  }

  void _handleTogglePause() {
    QuickStartOverlay.togglePause();
  }

  Future<void> _handleCancel() async {
    if (!mounted) return;

    final navigator = Navigator.of(context);
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

    if (mounted && confirmed == true) {
      QuickStartOverlay.selectedExercises = [];
      QuickStartOverlay.resetTimer();
      navigator.pop();
    }
  }

  void _handleReorderStart(int index) {
    // Provide haptic feedback when starting to reorder
    HapticFeedback.mediumImpact();
    
    _stateManager.setCurrentlyReorderingIndex(index);
  }

  void _handleReorderEnd(int index) {
    _stateManager.setCurrentlyReorderingIndex(null);
    // Don't exit reorder mode when drag ends - user must tap "Done"
  }

  void _handleDoneReorder() {
    _stateManager.setReorderMode(false);
    
    // After exiting reorder mode, check the current scroll position
    // to determine if workout name should be shown in app bar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkScrollPositionForWorkoutName();
      }
    });
  }

  void _checkScrollPositionForWorkoutName() {
    // Show workout name in app bar when scrolled past the workout name card (approximately 100 pixels)
    const double threshold = 100.0;
    bool shouldShow = _scrollController.offset > threshold;
    
    if (shouldShow != _stateManager.showWorkoutNameInAppBar) {
      _stateManager.setShowWorkoutNameInAppBar(shouldShow);
    }
  }

  @override
  void dispose() {
    // Clear the page update callback
    QuickStartOverlay.setPageUpdateCallback(null);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _stateManager.dispose();
    super.dispose();
  }

  String _getStableWorkoutName() {
    // If we have a cached stable name, use it
    if (_isWorkoutNameStable && _cachedWorkoutName != null) {
      return _cachedWorkoutName!;
    }
    
    // Otherwise generate a new name and cache it
    final generatedName = WorkoutNameGenerator.generateWorkoutName(
      customWorkoutName: _stateManager.customWorkoutName,
      selectedExercises: _stateManager.selectedExercises,
    );
    
    // Cache the generated name if it's from a custom workout
    if (_stateManager.customWorkoutName != null) {
      _cachedWorkoutName = generatedName;
      _isWorkoutNameStable = true;
    }
    
    return generatedName;
  }

  // Get workout name specifically for app bar to prevent shifting
  String _getAppBarWorkoutName() {
    // For saved workouts, always use the custom workout name directly
    if (_stateManager.customWorkoutName != null) {
      return _stateManager.customWorkoutName!;
    }
    
    // For generated names, use cached version if available
    if (_cachedWorkoutName != null) {
      return _cachedWorkoutName!;
    }
    
    // Fallback to stable name
    return _getStableWorkoutName();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return ChangeNotifierProvider.value(
      value: _stateManager,
      child: Consumer<QuickStartStateManager>(
        builder: (context, stateManager, child) {
          return Scaffold(
            backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: FaIcon(
                  FontAwesomeIcons.chevronDown,
                  color: themeService.currentTheme.appBarTheme.foregroundColor,
                  size: 20,
                ),
                onPressed: _handleMinimize,
              ),
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutQuart,
                switchOutCurve: Curves.easeInQuart,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.5),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutQuart,
                      ),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child:
                    stateManager.showWorkoutNameInAppBar
                        ? WorkoutNameEditor(
                          key: const ValueKey('workout-name-app-bar'),
                          currentWorkoutName: _getAppBarWorkoutName(),
                          isEditing: stateManager.isEditingWorkoutName,
                          showInAppBar: true,
                          onToggleEditing: _handleWorkoutNameToggle,
                          onNameChanged: _handleWorkoutNameChanged,
                          onSubmitted: _handleWorkoutNameSubmitted,
                        )
                        : Row(
                          key: const ValueKey('timer'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.stopwatch,
                              color: themeService.currentTheme.appBarTheme.foregroundColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DurationFormatter.formatDuration(
                                QuickStartOverlay.elapsedTime,
                              ),
                              style: TextStyle(
                                color: themeService.currentTheme.appBarTheme.foregroundColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
              ),
              actions: [
                // Show timer when workout name is in app bar
                if (stateManager.showWorkoutNameInAppBar)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.stopwatch,
                          color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.black54,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DurationFormatter.formatDuration(
                            QuickStartOverlay.elapsedTime,
                          ),
                          style: TextStyle(
                            color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.black54,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _handleTogglePause,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                                                  child: FaIcon(
                          QuickStartOverlay.isPaused
                              ? FontAwesomeIcons.play
                              : FontAwesomeIcons.pause,
                          color: themeService.currentTheme.appBarTheme.foregroundColor,
                          size: 20,
                        ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _handleCancel,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                                                  child: FaIcon(
                          FontAwesomeIcons.xmark,
                          color: themeService.currentTheme.appBarTheme.foregroundColor,
                          size: 20,
                        ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: GestureDetector(
                onTap: () {
                  // Dismiss keyboard when tapping outside of input fields
                  _clearFocusAggressively();

                  // If workout name is being edited, save and exit editing mode
                  if (stateManager.isEditingWorkoutName) {
                    _stateManager.setEditingWorkoutName(false);
                    _stateManager.setPreventAutoFocus(true);
                  }
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 350;
                    final mainPadding = isSmallScreen ? 12.0 : 16.0;

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        mainPadding,
                        mainPadding,
                        mainPadding,
                        0.0,
                      ),
                      child: Column(
                        children: [
                          // Workout Name Display at the top with smooth transition
                          AnimatedSize(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutQuart,
                            child:
                                stateManager.showWorkoutNameInAppBar
                                    ? const SizedBox.shrink()
                                    : WorkoutNameEditor(
                                      key: const ValueKey('workout-name-body'),
                                      currentWorkoutName: _getStableWorkoutName(),
                                      isEditing:
                                          stateManager.isEditingWorkoutName,
                                      showInAppBar: false,
                                      onToggleEditing: _handleWorkoutNameToggle,
                                      onNameChanged: _handleWorkoutNameChanged,
                                      onSubmitted: _handleWorkoutNameSubmitted,
                                    ),
                          ),
                          Expanded(
                            child:
                                stateManager.selectedExercises.isEmpty
                                    ? SingleChildScrollView(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 120),
                                          FaIcon(
                                            FontAwesomeIcons.dumbbell,
                                            size: 48,
                                            color: themeService.currentTheme.textTheme.titleLarge?.color,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Let\'s get moving!',
                                            style: TextStyle(
                                              color: themeService.currentTheme.textTheme.titleLarge?.color,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add an exercise to get started',
                                            style: TextStyle(
                                              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          // Custom workout suggestions
                                          if (stateManager
                                              .loadingCustomWorkouts) ...[
                                            const SizedBox(height: 80),
                                            const CircularProgressIndicator(),
                                          ] else ...[
                                            CustomWorkoutList(
                                              customWorkouts:
                                                  stateManager.customWorkouts,
                                              loadingCustomWorkouts:
                                                  stateManager
                                                      .loadingCustomWorkouts,
                                              onWorkoutSelected:
                                                  _handleCustomWorkoutSelected,
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                    : stateManager.isInReorderMode
                                        ? ReorderableListView(
                                          shrinkWrap: true,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          onReorder: (
                                            int oldIndex,
                                            int newIndex,
                                          ) {
                                            // Provide haptic feedback when reordering
                                            HapticFeedback.lightImpact();
                                            
                                            _stateManager
                                                .reorderExercises(
                                                  oldIndex,
                                                  newIndex,
                                                );
                                            QuickStartOverlay
                                                    .selectedExercises =
                                                _stateManager
                                                    .selectedExercises;
                                          },
                                          onReorderStart: (int index) {
                                            _handleReorderStart(index);
                                          },
                                          onReorderEnd: (int index) {
                                            _handleReorderEnd(index);
                                          },
                                          children:
                                              stateManager.selectedExercises.asMap().entries.map((
                                                entry,
                                              ) {
                                                final index = entry.key;
                                                final exercise =
                                                    entry.value;
                                                return ExerciseCard(
                                                  key: Key(
                                                    'exercise_${exercise.title}_$index',
                                                  ),
                                                  exercise: exercise,
                                                  exerciseIndex: index,
                                                  preventAutoFocus:
                                                      stateManager
                                                          .preventAutoFocus,
                                                  isCollapsed:
                                                      stateManager
                                                          .isInReorderMode,
                                                  isNewlyAdded:
                                                      stateManager.isExerciseNewlyAdded(exercise),
                                                  onRemoveExercise:
                                                      _handleRemoveExercise,
                                                  onRemoveSet:
                                                      _handleRemoveSet,
                                                  onWeightChanged:
                                                      _handleWeightChanged,
                                                  onRepsChanged:
                                                      _handleRepsChanged,
                                                  onSetCheckedChanged:
                                                      _handleSetCheckedChanged,
                                                  onAllSetsCheckedChanged:
                                                      _handleAllSetsCheckedChanged,
                                                  onAddSet:
                                                      () => _handleAddSet(
                                                        exercise,
                                                      ),
                                                  onRequestReorderMode:
                                                      () => _stateManager
                                                          .setReorderMode(
                                                            true,
                                                          ),
                                                );
                                              }).toList(),
                                        )
                                        : SingleChildScrollView(
                                          controller: _scrollController,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // Exercise cards with simple animations
                                              ...stateManager.selectedExercises.asMap().entries.map((
                                                entry,
                                              ) {
                                                final index = entry.key;
                                                final exercise = entry.value;
                                                final cardKey = _exerciseKeys.putIfAbsent(exercise, () => GlobalKey());
                                                
                                                return ExerciseCard(
                                                  key: cardKey,
                                                  exercise: exercise,
                                                  exerciseIndex: index,
                                                  preventAutoFocus:
                                                      stateManager
                                                          .preventAutoFocus,
                                                  isCollapsed:
                                                      stateManager
                                                          .isInReorderMode,
                                                  isNewlyAdded:
                                                      stateManager.isExerciseNewlyAdded(exercise),
                                                  onRemoveExercise:
                                                      _handleRemoveExercise,
                                                  onRemoveSet:
                                                      _handleRemoveSet,
                                                  onWeightChanged:
                                                      _handleWeightChanged,
                                                  onRepsChanged:
                                                      _handleRepsChanged,
                                                  onSetCheckedChanged:
                                                      _handleSetCheckedChanged,
                                                  onAllSetsCheckedChanged:
                                                      _handleAllSetsCheckedChanged,
                                                  onAddSet:
                                                      () => _handleAddSet(
                                                        exercise,
                                                      ),
                                                  onRequestReorderMode:
                                                      () => _stateManager
                                                          .setReorderMode(
                                                            true,
                                                          ),
                                                );
                                              }),
                                              const SizedBox(height: 16),
                                              if (!stateManager.isInReorderMode)
                                                FinishWorkoutButton(
                                                  completedExercises:
                                                      stateManager
                                                          .selectedExercises,
                                                  workoutDuration:
                                                      QuickStartOverlay.elapsedTime,
                                                  customWorkoutName:
                                                      stateManager
                                                          .customWorkoutName,
                                                ),
                                              const SizedBox(height: 100),
                                            ],
                                          ),
                                        ),
                          ),
                          // Done button with identical animation to AddExerciseButton (hide when keyboard is up)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutQuart,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              opacity:
                                  (stateManager.isInReorderMode &&
                                          !stateManager.isAnyFieldFocused &&
                                          !stateManager.isEditingWorkoutName)
                                      ? 1.0
                                      : 0.0,
                              child:
                                  (stateManager.isInReorderMode &&
                                          !stateManager.isAnyFieldFocused &&
                                          !stateManager.isEditingWorkoutName)
                                      ? Column(
                                        children: [
                                          const SizedBox(height: 16),
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              final screenWidth =
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width;
                                              final buttonFontSize =
                                                  screenWidth < 350
                                                      ? 16.0
                                                      : 18.0;
                                              final buttonPadding =
                                                  screenWidth < 350
                                                      ? const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      )
                                                      : const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      );

                                              return SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: _handleDoneReorder,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        const StadiumBorder(),
                                                    padding: buttonPadding,
                                                  ),
                                                  child: Text(
                                                    'Done',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: buttonFontSize,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      )
                                      : const SizedBox.shrink(),
                            ),
                          ),
                          // Add Exercises button with identical animation to AddExerciseButton (positioned last for bottom-up animation)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutQuart,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              opacity: stateManager.isInReorderMode ? 0.0 : 1.0,
                              child:
                                  stateManager.isInReorderMode
                                      ? const SizedBox.shrink()
                                      : AddExerciseButton(
                                        isAnyFieldFocused:
                                            stateManager.isAnyFieldFocused,
                                        isEditingWorkoutName:
                                            stateManager.isEditingWorkoutName,
                                        onExercisesAdded: _handleExercisesAdded,
                                        onExercisesLoaded:
                                            _handleExercisesLoaded,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 