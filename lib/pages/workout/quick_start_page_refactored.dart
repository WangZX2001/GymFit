import 'package:flutter/material.dart';
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

class QuickStartPage extends StatefulWidget {
  final List<QuickStartExercise> initialSelectedExercises;
  final String? initialWorkoutName;
  final bool showMinibarOnMinimize;

  const QuickStartPage({
    super.key,
    this.initialSelectedExercises = const <QuickStartExercise>[],
    this.initialWorkoutName,
    this.showMinibarOnMinimize = true,
  });

  @override
  State<QuickStartPage> createState() => _QuickStartPageState();
}

class _QuickStartPageState extends State<QuickStartPage> {
  late ScrollController _scrollController;
  late QuickStartStateManager _stateManager;

  @override
  void initState() {
    super.initState();
    
    // Initialize state manager
    _stateManager = QuickStartStateManager();
    _stateManager.initialize(
      initialExercises: widget.initialSelectedExercises,
      initialWorkoutName: widget.initialWorkoutName,
    );

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
    // Show workout name in app bar when scrolled past the workout name card (approximately 100 pixels)
    const double threshold = 100.0;
    bool shouldShow = _scrollController.offset > threshold;

    if (shouldShow != _stateManager.showWorkoutNameInAppBar) {
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
  }

  void _handleWorkoutNameToggle() {
    _stateManager.setEditingWorkoutName(!_stateManager.isEditingWorkoutName);
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
  }

  void _handleRemoveExercise(QuickStartExercise exercise) {
    _stateManager.removeExercise(exercise);
  }

  void _handleRemoveSet(QuickStartExercise exercise, ExerciseSet set) {
    _stateManager.removeSetFromExercise(exercise, set);
  }

  void _handleWeightChanged(QuickStartExercise exercise, ExerciseSet set, double weight) {
    set.updateWeight(weight);
    QuickStartOverlay.selectedExercises = _stateManager.selectedExercises;
  }

  void _handleRepsChanged(QuickStartExercise exercise, ExerciseSet set, int reps) {
    set.updateReps(reps);
    QuickStartOverlay.selectedExercises = _stateManager.selectedExercises;
  }

  void _handleSetCheckedChanged(QuickStartExercise exercise, ExerciseSet set, bool checked) {
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
      }
    });

    // Re-enable interaction after ensuring new fields are built
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _stateManager.setPreventAutoFocus(false);
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
          content: const Text(
            'Are you sure you want to cancel this workout?',
          ),
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

  @override
  void dispose() {
    // Clear the page update callback
    QuickStartOverlay.setPageUpdateCallback(null);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _stateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _stateManager,
      child: Consumer<QuickStartStateManager>(
        builder: (context, stateManager, child) {
          return Scaffold(
            backgroundColor: Colors.grey.shade200,
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: Colors.grey.shade200,
              elevation: 0,
              leading: IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.chevronDown,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: _handleMinimize,
              ),
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutQuart,
                switchOutCurve: Curves.easeInQuart,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.5),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: stateManager.showWorkoutNameInAppBar
                    ? WorkoutNameEditor(
                        key: const ValueKey('workout-name'),
                        currentWorkoutName: WorkoutNameGenerator.generateWorkoutName(
                          customWorkoutName: stateManager.customWorkoutName,
                          selectedExercises: stateManager.selectedExercises,
                        ),
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
                          const FaIcon(
                            FontAwesomeIcons.stopwatch,
                            color: Colors.black,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DurationFormatter.formatDuration(QuickStartOverlay.elapsedTime),
                            style: const TextStyle(
                              color: Colors.black,
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
                        const FaIcon(
                          FontAwesomeIcons.stopwatch,
                          color: Colors.black54,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DurationFormatter.formatDuration(QuickStartOverlay.elapsedTime),
                          style: const TextStyle(
                            color: Colors.black54,
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
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _handleCancel,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const FaIcon(
                            FontAwesomeIcons.xmark,
                            color: Colors.black,
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
                            child: stateManager.showWorkoutNameInAppBar
                                ? const SizedBox.shrink()
                                : WorkoutNameEditor(
                                    currentWorkoutName: WorkoutNameGenerator.generateWorkoutName(
                                      customWorkoutName: stateManager.customWorkoutName,
                                      selectedExercises: stateManager.selectedExercises,
                                    ),
                                    isEditing: stateManager.isEditingWorkoutName,
                                    showInAppBar: false,
                                    onToggleEditing: _handleWorkoutNameToggle,
                                    onNameChanged: _handleWorkoutNameChanged,
                                    onSubmitted: _handleWorkoutNameSubmitted,
                                  ),
                          ),
                          Expanded(
                            child: stateManager.selectedExercises.isEmpty
                                ? SingleChildScrollView(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 120),
                                        const FaIcon(
                                          FontAwesomeIcons.dumbbell,
                                          size: 48,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Let\'s get moving!',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add an exercise to get started',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        // Custom workout suggestions
                                        if (stateManager.loadingCustomWorkouts) ...[
                                          const SizedBox(height: 80),
                                          const CircularProgressIndicator(),
                                        ] else ...[
                                          CustomWorkoutList(
                                            customWorkouts: stateManager.customWorkouts,
                                            loadingCustomWorkouts: stateManager.loadingCustomWorkouts,
                                            onWorkoutSelected: _handleCustomWorkoutSelected,
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    controller: _scrollController,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        ReorderableListView(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          onReorder: (int oldIndex, int newIndex) {
                                            _stateManager.reorderExercises(oldIndex, newIndex);
                                            QuickStartOverlay.selectedExercises = _stateManager.selectedExercises;
                                          },
                                          children: stateManager.selectedExercises.asMap().entries.map((entry) {
                                            final index = entry.key;
                                            final exercise = entry.value;
                                            return ExerciseCard(
                                              key: Key('exercise_${exercise.title}_$index'),
                                              exercise: exercise,
                                              exerciseIndex: index,
                                              preventAutoFocus: stateManager.preventAutoFocus,
                                              onRemoveExercise: _handleRemoveExercise,
                                              onRemoveSet: _handleRemoveSet,
                                              onWeightChanged: _handleWeightChanged,
                                              onRepsChanged: _handleRepsChanged,
                                              onSetCheckedChanged: _handleSetCheckedChanged,
                                              onAllSetsCheckedChanged: _handleAllSetsCheckedChanged,
                                              onAddSet: () => _handleAddSet(exercise),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 16),
                                        FinishWorkoutButton(
                                          completedExercises: stateManager.selectedExercises,
                                          workoutDuration: QuickStartOverlay.elapsedTime,
                                          customWorkoutName: stateManager.customWorkoutName,
                                        ),
                                        const SizedBox(height: 100),
                                      ],
                                    ),
                                  ),
                          ),
                          // Add Exercises button with keyboard-aware visibility
                          AddExerciseButton(
                            isAnyFieldFocused: stateManager.isAnyFieldFocused,
                            isEditingWorkoutName: stateManager.isEditingWorkoutName,
                            onExercisesAdded: _handleExercisesAdded,
                            onExercisesLoaded: _handleExercisesLoaded,
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