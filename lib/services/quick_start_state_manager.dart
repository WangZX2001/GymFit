import 'package:flutter/material.dart';
import 'package:gymfit/models/exercise_set.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/services/custom_workout_service.dart';
import 'package:gymfit/services/workout_service.dart';

class QuickStartStateManager extends ChangeNotifier {
  List<QuickStartExercise> _selectedExercises = [];
  String? _customWorkoutName;
  List<CustomWorkout> _customWorkouts = [];
  bool _loadingCustomWorkouts = false;
  bool _isEditingWorkoutName = false;
  bool _isAnyFieldFocused = false;
  bool _preventAutoFocus = false;
  bool _showWorkoutNameInAppBar = false;
  bool _isReordering = false;
  int? _currentlyReorderingIndex;
  bool _isInReorderMode = false;
  final Set<QuickStartExercise> _newlyAddedExercises = {};
  bool _hasReorderedExercises = false;

  // Getters
  List<QuickStartExercise> get selectedExercises => _selectedExercises;
  String? get customWorkoutName => _customWorkoutName;
  List<CustomWorkout> get customWorkouts => _customWorkouts;
  bool get loadingCustomWorkouts => _loadingCustomWorkouts;
  bool get isEditingWorkoutName => _isEditingWorkoutName;
  bool get isAnyFieldFocused => _isAnyFieldFocused;
  bool get preventAutoFocus => _preventAutoFocus;
  bool get showWorkoutNameInAppBar => _showWorkoutNameInAppBar;
  bool get isReordering => _isReordering;
  int? get currentlyReorderingIndex => _currentlyReorderingIndex;
  bool get isInReorderMode => _isInReorderMode;
  Set<QuickStartExercise> get newlyAddedExercises => _newlyAddedExercises;

  // Check if an exercise is newly added
  bool isExerciseNewlyAdded(QuickStartExercise exercise) {
    return _newlyAddedExercises.contains(exercise);
  }

  // Clear newly added flag for an exercise
  void clearNewlyAddedFlag(QuickStartExercise exercise) {
    _newlyAddedExercises.remove(exercise);
    notifyListeners();
  }

  // Initialize state
  void initialize({
    required List<QuickStartExercise> initialExercises,
    String? initialWorkoutName,
  }) {
    _selectedExercises =
        initialExercises
            .map((e) => QuickStartExercise(title: e.title, sets: e.sets))
            .toList();
    _customWorkoutName = initialWorkoutName;
    _setupFocusListeners();

    // Mark all initial exercises as newly added to trigger unfolding animations
    // when starting a saved workout
    if (_selectedExercises.isNotEmpty) {
      _newlyAddedExercises.addAll(_selectedExercises);
    }

    if (_selectedExercises.isEmpty) {
      _loadCustomWorkouts();
    }
  }

  // Focus management
  void _setupFocusListeners() {
    for (var exercise in _selectedExercises) {
      for (var set in exercise.sets) {
        set.addFocusListeners(_updateFocusState);
      }
    }
  }

  void _removeFocusListeners() {
    for (var exercise in _selectedExercises) {
      for (var set in exercise.sets) {
        set.removeFocusListeners(_updateFocusState);
      }
    }
  }

  void _updateFocusState() {
    bool anyFieldFocused = false;
    for (var exercise in _selectedExercises) {
      for (var set in exercise.sets) {
        if (set.weightFocusNode.hasFocus || set.repsFocusNode.hasFocus) {
          anyFieldFocused = true;
          break;
        }
      }
      if (anyFieldFocused) break;
    }

    if (_isAnyFieldFocused != anyFieldFocused) {
      _isAnyFieldFocused = anyFieldFocused;
      notifyListeners();
    }
  }

  // Custom workouts management
  Future<void> _loadCustomWorkouts() async {
    _loadingCustomWorkouts = true;
    notifyListeners();

    try {
      final workouts = await CustomWorkoutService.getPinnedCustomWorkouts();
      _customWorkouts = workouts;
      _loadingCustomWorkouts = false;
      notifyListeners();
    } catch (e) {
      _loadingCustomWorkouts = false;
      notifyListeners();
    }
  }

  void loadCustomWorkout(CustomWorkout workout) {
    final exercises =
        workout.exercises.map((customExercise) {
          final sets =
              customExercise.sets
                  .map(
                    (customSet) => ExerciseSet(
                      weight: customSet.weight,
                      reps: customSet.reps,
                      isWeightPrefilled: false,
                      isRepsPrefilled: false,
                      previousWeight: null,
                      previousReps: null,
                    ),
                  )
                  .toList();

          return QuickStartExercise(title: customExercise.name, sets: sets);
        }).toList();

    _selectedExercises = exercises;
    _customWorkoutName = workout.name;

    // Add focus listeners to loaded exercises
    for (var exercise in _selectedExercises) {
      for (var set in exercise.sets) {
        set.addFocusListeners(_updateFocusState);
      }
    }

    // Mark all loaded exercises as newly added to trigger unfolding animations
    _newlyAddedExercises.addAll(_selectedExercises);

    notifyListeners();
  }

  // Exercise management
  void addExercise(QuickStartExercise exercise) {
    // Add focus listeners to new exercise
    for (var set in exercise.sets) {
      set.addFocusListeners(_updateFocusState);
    }
    _selectedExercises.add(exercise);
    _newlyAddedExercises.add(exercise);
    notifyListeners();
  }

  void removeExercise(QuickStartExercise exercise) {
    // Dispose focus listeners before removing
    for (var set in exercise.sets) {
      set.removeFocusListeners(_updateFocusState);
      set.dispose();
    }
    _selectedExercises.remove(exercise);
    _newlyAddedExercises.remove(exercise);

    // Clear newly added flags for all remaining exercises to prevent animation on deletion
    _newlyAddedExercises.clear();

    notifyListeners();
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final QuickStartExercise item = _selectedExercises.removeAt(oldIndex);
    _selectedExercises.insert(newIndex, item);

    // Track that reordering has occurred
    _hasReorderedExercises = true;

    // Clear newly added flags when reordering to prevent animation during reorder
    _newlyAddedExercises.clear();

    notifyListeners();
  }

  void setReorderingState(bool isReordering) {
    _isReordering = isReordering;
    notifyListeners();
  }

  void setCurrentlyReorderingIndex(int? index) {
    _currentlyReorderingIndex = index;
    notifyListeners();
  }

  void setReorderMode(bool isInReorderMode) {
    _isInReorderMode = isInReorderMode;

    // Automatically show workout name in app bar when entering reorder mode
    if (isInReorderMode) {
      _showWorkoutNameInAppBar = true;
    }

    // If exiting reorder mode, treat all exercises as newly added to trigger unfolding animations
    if (!isInReorderMode) {
      _newlyAddedExercises.addAll(_selectedExercises);
      _hasReorderedExercises = false; // Reset the flag
      
      // Don't automatically reset workout name app bar state when exiting reorder mode
      // Let the scroll position check determine the correct state
    }

    notifyListeners();
  }

  // Set management
  void addSetToExercise(QuickStartExercise exercise) async {
    ExerciseSet newSet;
    if (exercise.sets.isNotEmpty) {
      // Use data from the last set in current exercise
      final lastSet = exercise.sets.last;
      newSet = ExerciseSet(
        weight: lastSet.weight,
        reps: lastSet.reps,
        isWeightPrefilled: true,
        isRepsPrefilled: true,
        previousWeight: lastSet.previousWeight,
        previousReps: lastSet.previousReps,
      );
    } else {
      // Fallback to previous workout data
      try {
        final previousData = await WorkoutService.getLastExerciseData(
          exercise.title,
        );
        if (previousData != null && previousData['sets'] != null) {
          final previousSetsData = previousData['sets'] as List<dynamic>;
          if (previousSetsData.isNotEmpty) {
            // Use the last set from previous workout
            final lastSetData = previousSetsData.last;
            final weight = (lastSetData['weight'] as num?)?.toDouble() ?? 0.0;
            final reps = (lastSetData['reps'] as int?) ?? 0;
            newSet = ExerciseSet(
              weight: weight,
              reps: reps,
              isWeightPrefilled: true,
              isRepsPrefilled: true,
              previousWeight: weight,
              previousReps: reps,
            );
          } else {
            newSet = ExerciseSet();
          }
        } else {
          newSet = ExerciseSet();
        }
      } catch (e) {
        newSet = ExerciseSet();
      }
    }

    newSet.addFocusListeners(_updateFocusState);
    exercise.sets.add(newSet);
    notifyListeners();
  }

  void removeSetFromExercise(QuickStartExercise exercise, ExerciseSet set) {
    set.removeFocusListeners(_updateFocusState);
    set.dispose();
    exercise.sets.remove(set);
    notifyListeners();
  }

  void updateSetChecked(
    QuickStartExercise exercise,
    ExerciseSet set,
    bool value,
  ) {
    set.isChecked = value;
    notifyListeners();
  }

  void updateAllSetsChecked(QuickStartExercise exercise, bool value) {
    for (var set in exercise.sets) {
      set.isChecked = value;
    }
    notifyListeners();
  }

  // Workout name management
  void setCustomWorkoutName(String? name) {
    _customWorkoutName = name;
    notifyListeners();
  }

  void setEditingWorkoutName(bool editing) {
    _isEditingWorkoutName = editing;
    notifyListeners();
  }

  // Focus management
  void setPreventAutoFocus(bool prevent) {
    _preventAutoFocus = prevent;
    notifyListeners();
  }

  void setShowWorkoutNameInAppBar(bool show) {
    // Don't change workout name app bar state during reorder mode
    // The workout name should stay in the app bar during reorder mode
    if (_isInReorderMode) {
      return;
    }
    
    _showWorkoutNameInAppBar = show;
    notifyListeners();
  }

  // Cleanup
  @override
  void dispose() {
    _removeFocusListeners();
    super.dispose();
  }
}
