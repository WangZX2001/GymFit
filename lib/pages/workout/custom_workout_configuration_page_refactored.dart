import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:gymfit/components/generic_exercise_card.dart';
import 'package:gymfit/components/shared_adapters.dart';
import 'package:gymfit/components/custom_workout_add_button.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/pages/workout/workout_name_description_page.dart';
import 'package:gymfit/services/custom_workout_configuration_state_manager.dart';
import 'package:gymfit/services/theme_service.dart';





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
  final Map<String, GlobalKey> _exerciseKeys = {};

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

  Future<void> _handleExercisesLoaded(List<String> newExerciseNames) async {
    // Add exercises to state manager first (this is async)
    final newExercises = await _stateManager.addExercises(newExerciseNames);

    // Additional focus clearing after state change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _clearFocusAggressively();
      }
    });

    // Await robust scroll
    await _scrollToNewExercises(newExercises);

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

  void _handleRemoveExercise(ExerciseData exerciseData) {
    if (exerciseData is ConfigExerciseAdapter) {
      // Immediately clear focus to prevent errors
      if (mounted) {
        try {
          FocusScope.of(context).unfocus();
        } catch (e) {
          // Context might be invalid, use fallback
        }
      }

      final exercise = exerciseData.exercise;
      final index = _stateManager.exercises.indexOf(exercise);
      if (index != -1) {
        _exerciseKeys.remove(exercise.id); // Clean up key
        _stateManager.removeExercise(index);
      }
    }
  }

  void _handleRemoveSet(ExerciseData exerciseData, dynamic set) {
    if (exerciseData is ConfigExerciseAdapter && set is ConfigSetAdapter) {
      final exercise = exerciseData.exercise;
      final configSet = set.configSet;
      _stateManager.removeSetFromExercise(exercise, configSet);
    }
  }

  void _handleAddSet(ExerciseData exerciseData) {
    if (exerciseData is ConfigExerciseAdapter) {
      final exercise = exerciseData.exercise;
      _stateManager.addSetToExercise(exercise);
    }
  }

  void _handleWeightChanged(ExerciseData exerciseData, dynamic set, double weight) {
    // Weight changed callback - can be used for future enhancements
  }

  void _handleRepsChanged(ExerciseData exerciseData, dynamic set, int reps) {
    // Reps changed callback - can be used for future enhancements
  }

  void _handleSetCheckedChanged(ExerciseData exerciseData, dynamic set, bool checked) {
    // No checkboxes in custom workout configuration
  }

  void _handleAllSetsCheckedChanged(ExerciseData exerciseData, bool checked) {
    // No checkboxes in custom workout configuration
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

  Future<void> _scrollToNewExercises(List<ConfigExercise> newExercises) async {
    if (!mounted || newExercises.isEmpty) return;
    final firstNew = newExercises.first;
    const maxTries = 10;
    int tries = 0;
    while (tries < maxTries) {
      final key = _exerciseKeys[firstNew.id];
      if (key != null && key.currentContext != null) {
        await Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      await Future.delayed(const Duration(milliseconds: 50));
      tries++;
    }
    debugPrint('Failed to find key/context for exercise id: ${firstNew.id} after $maxTries tries');
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
            child: Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return Scaffold(
                  backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
                  resizeToAvoidBottomInset: false,
                  appBar: AppBar(
                    backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios, 
                        color: themeService.currentTheme.appBarTheme.foregroundColor,
                      ),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final shouldPop = await _handleBackNavigation();
                        if (shouldPop && mounted) {
                          navigator.pop();
                        }
                      },
                    ),
                    title: Text(
                      'Configure Workout',
                      style: themeService.currentTheme.appBarTheme.titleTextStyle,
                    ),
                    actions: [
                      IconButton(
                        onPressed: _proceedToNameDescription,
                        icon: Icon(
                          Icons.done, 
                          color: themeService.currentTheme.appBarTheme.foregroundColor, 
                          size: 24,
                        ),
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
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                                      child: ReorderableListView(
                                        shrinkWrap: true,
                                        physics: const AlwaysScrollableScrollPhysics(),
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
                                        children: stateManager.exercises.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final exercise = entry.value;
                                          return Container(
                                            key: Key('exercise_${exercise.title}_$index'),
                                            margin: const EdgeInsets.only(bottom: 6.0),
                                            child: GenericExerciseCard(
                                              exercise: ConfigExerciseAdapter(exercise),
                                              exerciseIndex: index,
                                              isCollapsed: true,
                                              isNewlyAdded: stateManager.isExerciseNewlyAdded(exercise),
                                              preventAutoFocus: stateManager.preventAutoFocus,
                                              onRemoveExercise: _handleRemoveExercise,
                                              onRemoveSet: _handleRemoveSet,
                                              onWeightChanged: _handleWeightChanged,
                                              onRepsChanged: _handleRepsChanged,
                                              onSetCheckedChanged: _handleSetCheckedChanged,
                                              onAllSetsCheckedChanged: _handleAllSetsCheckedChanged,
                                              onAddSet: () => _handleAddSet(ConfigExerciseAdapter(exercise)),
                                              onRequestReorderMode: _handleRequestReorderMode,
                                              rowHeight: 32.0, // Increased height for custom workout configuration
                                              headerSpacing: 8.0, // Add spacing between header and divider
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                    controller: _scrollController,
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                      children: [
                                        for (int index = 0; index < stateManager.exercises.length; index++) ...[
                                          Builder(
                                            builder: (context) {
                                              final exercise = stateManager.exercises[index];
                                              final cardKey = _exerciseKeys.putIfAbsent(exercise.id, () => GlobalKey());
                                              return Card(
                                                key: cardKey,
                                                color: themeService.currentTheme.cardTheme.color,
                                                margin: const EdgeInsets.symmetric(
                                                  vertical: 4,
                                                ),
                                                child: GenericExerciseCard(
                                                  exercise: ConfigExerciseAdapter(exercise),
                                                  exerciseIndex: index,
                                                  isCollapsed: false,
                                                  isNewlyAdded: stateManager.isExerciseNewlyAdded(exercise),
                                                  preventAutoFocus: stateManager.preventAutoFocus,
                                                  onRemoveExercise: _handleRemoveExercise,
                                                  onRemoveSet: _handleRemoveSet,
                                                  onWeightChanged: _handleWeightChanged,
                                                  onRepsChanged: _handleRepsChanged,
                                                  onSetCheckedChanged: _handleSetCheckedChanged,
                                                  onAllSetsCheckedChanged: _handleAllSetsCheckedChanged,
                                                  onAddSet: () => _handleAddSet(ConfigExerciseAdapter(exercise)),
                                                  onRequestReorderMode: _handleRequestReorderMode,
                                                  rowHeight: 32.0, // Increased height for custom workout configuration
                                                  headerSpacing: 8.0, // Add spacing between header and divider
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                        const SizedBox(height: 100), // bottom padding
                                      ],
                                    ),
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
