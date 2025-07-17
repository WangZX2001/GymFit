import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:gymfit/components/custom_workout_exercise_card.dart';
import 'package:gymfit/components/custom_workout_add_button.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/pages/workout/workout_name_description_page.dart';
import 'package:gymfit/services/custom_workout_configuration_state_manager.dart';

class CustomWorkoutConfigurationPage extends StatefulWidget {
  final List<String> exerciseNames;
  final CustomWorkout? existingWorkout; // For editing existing workouts

  const CustomWorkoutConfigurationPage({
    super.key,
    required this.exerciseNames,
    this.existingWorkout,
  });

  @override
  State<CustomWorkoutConfigurationPage> createState() =>
      _CustomWorkoutConfigurationPageState();
}

class _CustomWorkoutConfigurationPageState
    extends State<CustomWorkoutConfigurationPage> {
  late CustomWorkoutConfigurationStateManager _stateManager;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    // Initialize state manager
    _stateManager = CustomWorkoutConfigurationStateManager();
    _stateManager.initialize(
      exerciseNames: widget.exerciseNames,
      existingWorkout: widget.existingWorkout,
    );

    // Initialize scroll controller
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Clear newly added flags after initial animations complete
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        for (var exercise in _stateManager.exercises) {
          if (_stateManager.isExerciseNewlyAdded(exercise)) {
            _stateManager.markExerciseAsNotNewlyAdded(exercise);
          }
        }
      }
    });
  }

  void _onScroll() {
    // Clear newly added flags during scrolling to prevent animations
    if (_scrollController.position.isScrollingNotifier.value) {
      _stateManager.clearNewlyAddedFlagsForScrolling();
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

  // Add method to show confirmation dialog
  Future<bool> _showExitConfirmationDialog() async {
    if (!mounted) return false;

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                'Custom workout not saved, are you sure you want to leave? All progress will be lost.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Leave'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Add method to handle back navigation
  Future<bool> _handleBackNavigation() async {
    if (_stateManager.hasExercises) {
      return await _showExitConfirmationDialog();
    }
    return true; // Allow back navigation if no exercises
  }

  void _handleRequestReorderMode() {
    // Aggressively clear focus from any currently focused input fields
    _clearFocusAggressively();

    _stateManager.setPreventAutoFocus(true); // Temporarily disable interaction
    _stateManager.setReorderMode(true);

    // Additional focus clearing after state change
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

  void _handleDoneReorder() {
    // Aggressively clear focus from any currently focused input fields
    _clearFocusAggressively();

    _stateManager.setPreventAutoFocus(true); // Temporarily disable interaction
    _stateManager.setReorderMode(false);

    // Additional focus clearing after state change
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

  void _handleExercisesAdded() {
    // Aggressively clear focus from any currently focused input fields
    _clearFocusAggressively();

    _stateManager.setPreventAutoFocus(true); // Temporarily disable interaction
  }

  void _handleExercisesLoaded(List<String> newExerciseNames) {
    // Additional focus clearing after state change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _clearFocusAggressively();
      }
    });

    // Add exercises to state manager
    _stateManager.addExercises(newExerciseNames);

    // Mark exercises as no longer newly added after animation completes
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        for (var exercise in _stateManager.exercises) {
          if (_stateManager.isExerciseNewlyAdded(exercise)) {
            _stateManager.markExerciseAsNotNewlyAdded(exercise);
          }
        }
      }
    });

    // Re-enable interaction after ensuring new fields are built
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _stateManager.setPreventAutoFocus(false);
      }
    });
  }

  void _handleRemoveExercise(int index) {
    // Immediately clear focus to prevent errors
    if (mounted) {
      try {
        FocusScope.of(context).unfocus();
      } catch (e) {
        // Context might be invalid, use fallback
      }
    }

    _stateManager.removeExercise(index);
  }

  void _handleRemoveSet(ConfigExercise exercise, ConfigSet set) {
    _stateManager.removeSetFromExercise(exercise, set);
  }

  void _handleAddSet(ConfigExercise exercise) {
    _stateManager.addSetToExercise(exercise);
  }

  void _handleWeightChanged() {
    // Weight changed callback - can be used for future enhancements
  }

  void _handleRepsChanged() {
    // Reps changed callback - can be used for future enhancements
  }

  void _handleReorderStart(int index) {
    // Provide haptic feedback when starting to reorder
    HapticFeedback.mediumImpact();
    
    // Reorder start callback - can be used for future enhancements
  }

  void _handleReorderEnd(int index) {
    // Reorder end callback - can be used for future enhancements
    // Don't exit reorder mode when drag ends - user must tap "Done"
  }

  void _proceedToNameDescription() async {
    if (_stateManager.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise')),
      );
      return;
    }

    // Convert exercises to CustomWorkoutExercise format
    final customExercises = _stateManager.toCustomWorkoutExercises();

    // Navigate to name/description page
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => WorkoutNameDescriptionPage(
              exercises: customExercises,
              existingWorkout: widget.existingWorkout,
            ),
      ),
    );

    // Prevent auto-focus when returning from workout name description page
    if (mounted) {
      _stateManager.setPreventAutoFocus(true);

      // Re-enable interaction after build is complete
      Future.microtask(() {
        if (mounted) {
          _stateManager.setPreventAutoFocus(false);
          _clearFocusAggressively();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _stateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _stateManager,
      child: Consumer<CustomWorkoutConfigurationStateManager>(
        builder: (context, stateManager, child) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, dynamic result) async {
              if (didPop) return;

              final navigator = Navigator.of(context);
              final shouldPop = await _handleBackNavigation();
              if (shouldPop && mounted) {
                navigator.pop();
              }
            },
            child: Scaffold(
              backgroundColor: Colors.grey.shade200,
              appBar: AppBar(
                backgroundColor: Colors.grey.shade200,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final shouldPop = await _handleBackNavigation();
                    if (shouldPop && mounted) {
                      navigator.pop();
                    }
                  },
                ),
                title: const Text(
                  'Configure Workout',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: _proceedToNameDescription,
                    icon: const Icon(Icons.done, color: Colors.black, size: 24),
                  ),
                ],
              ),
              body: GestureDetector(
                onTap: () {
                  // Dismiss keyboard when tapping outside text fields
                  _clearFocusAggressively();
                },
                behavior: HitTestBehavior.translucent,
                child: Column(
                  children: [
                    Expanded(
                      child:
                          stateManager.isInReorderMode
                              ? ReorderableListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                itemCount: stateManager.exercises.length,
                                onReorder: (int oldIndex, int newIndex) {
                                  // Provide haptic feedback when reordering
                                  HapticFeedback.lightImpact();
                                  
                                  _stateManager.reorderExercises(
                                    oldIndex,
                                    newIndex,
                                  );
                                },
                                onReorderStart: (int index) {
                                  _handleReorderStart(index);
                                },
                                onReorderEnd: (int index) {
                                  _handleReorderEnd(index);
                                },
                                itemBuilder: (context, index) {
                                  final exercise =
                                      stateManager.exercises[index];
                                  return Card(
                                    key: Key('card_${exercise.id}'),
                                    color: Colors.white,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: CustomWorkoutExerciseCard(
                                      exercise: exercise,
                                      index: index,
                                      isCollapsed: true,
                                      isNewlyAdded: stateManager
                                          .isExerciseNewlyAdded(exercise),
                                      preventAutoFocus:
                                          stateManager.preventAutoFocus,
                                      onRequestReorderMode:
                                          _handleRequestReorderMode,
                                      onAddSet: () => _handleAddSet(exercise),
                                      onRemoveSet:
                                          (set) =>
                                              _handleRemoveSet(exercise, set),
                                      onWeightChanged: _handleWeightChanged,
                                      onRepsChanged: _handleRepsChanged,
                                    ),
                                  );
                                },
                              )
                              : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                itemCount: stateManager.exercises.length,
                                itemBuilder: (context, index) {
                                  final exercise =
                                      stateManager.exercises[index];
                                  return Dismissible(
                                    key: Key('exercise_${exercise.id}'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const FaIcon(
                                        FontAwesomeIcons.trash,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    onDismissed: (direction) {
                                      _handleRemoveExercise(index);
                                    },
                                    child: Card(
                                      key: Key('card_${exercise.id}'),
                                      color: Colors.white,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: CustomWorkoutExerciseCard(
                                        exercise: exercise,
                                        index: index,
                                        isCollapsed: false,
                                        isNewlyAdded: stateManager
                                            .isExerciseNewlyAdded(exercise),
                                        preventAutoFocus:
                                            stateManager.preventAutoFocus,
                                        onRequestReorderMode:
                                            _handleRequestReorderMode,
                                        onAddSet: () => _handleAddSet(exercise),
                                        onRemoveSet:
                                            (set) =>
                                                _handleRemoveSet(exercise, set),
                                        onWeightChanged: _handleWeightChanged,
                                        onRepsChanged: _handleRepsChanged,
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                    // Add Exercises button with animations
                    CustomWorkoutAddButton(
                      isAnyFieldFocused: stateManager.isAnyFieldFocused,
                      isInReorderMode: stateManager.isInReorderMode,
                      onExercisesAdded: _handleExercisesAdded,
                      onExercisesLoaded: _handleExercisesLoaded,
                      onDoneReorder: _handleDoneReorder,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
