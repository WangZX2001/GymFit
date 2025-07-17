import 'package:flutter/material.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/services/workout_service.dart';

// Model to track individual set data for configuration
class ConfigSet {
  final String id;
  double weight = 0.0;
  int reps = 0;
  late final TextEditingController weightController;
  late final TextEditingController repsController;
  late final FocusNode weightFocusNode;
  late final FocusNode repsFocusNode;
  bool weightSelected = false;
  bool repsSelected = false;
  bool isWeightPrefilled =
      false; // Track if weight was prefilled from previous data
  bool isRepsPrefilled =
      false; // Track if reps was prefilled from previous data
  double? previousWeight; // Previous workout weight for reference
  int? previousReps; // Previous workout reps for reference

  static int _counter = 0;

  // Helper to format weight display (strip trailing .0)
  static String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  // Helper to format previous data as "20kg x 5"
  String get previousDataFormatted {
    if (previousWeight != null && previousReps != null) {
      return '${_fmt(previousWeight!)}kg x $previousReps';
    }
    return '-';
  }

  ConfigSet({
    this.weight = 0.0,
    this.reps = 0,
    this.isWeightPrefilled = false,
    this.isRepsPrefilled = false,
    this.previousWeight,
    this.previousReps,
  }) : id = '${DateTime.now().millisecondsSinceEpoch}_${++_counter}' {
    weightController = TextEditingController(text: _fmt(weight));
    repsController = TextEditingController(text: reps.toString());
    weightFocusNode = FocusNode();
    repsFocusNode = FocusNode();
  }

  void addFocusListeners(VoidCallback onFocusChange) {
    weightFocusNode.addListener(onFocusChange);
    repsFocusNode.addListener(onFocusChange);
  }

  void removeFocusListeners(VoidCallback onFocusChange) {
    weightFocusNode.removeListener(onFocusChange);
    repsFocusNode.removeListener(onFocusChange);
  }

  void updateWeight(double newWeight) {
    // Always mark as manually edited when user types, even if same value
    isWeightPrefilled = false;
    if (weight != newWeight) {
      weight = newWeight;
      final formatted = _fmt(newWeight);
      if (weightController.text != formatted) {
        weightController.text = formatted;
      }
    }
  }

  void updateReps(int newReps) {
    // Always mark as manually edited when user types, even if same value
    isRepsPrefilled = false;
    if (reps != newReps) {
      reps = newReps;
      if (repsController.text != newReps.toString()) {
        repsController.text = newReps.toString();
      }
    }
  }

  void dispose() {
    weightController.dispose();
    repsController.dispose();
    weightFocusNode.dispose();
    repsFocusNode.dispose();
  }
}

class ConfigExercise {
  final String title;
  List<ConfigSet> sets;

  ConfigExercise({required this.title, List<ConfigSet>? sets})
    : sets = sets ?? [ConfigSet()];
}

class CustomWorkoutConfigurationStateManager extends ChangeNotifier {
  List<ConfigExercise> _exercises = [];
  bool _preventAutoFocus = false;
  bool _isAnyFieldFocused = false;
  bool _isInReorderMode = false;
  CustomWorkout? _existingWorkout;

  // Getters
  List<ConfigExercise> get exercises => _exercises;
  bool get preventAutoFocus => _preventAutoFocus;
  bool get isAnyFieldFocused => _isAnyFieldFocused;
  bool get isInReorderMode => _isInReorderMode;
  bool get hasExercises => _exercises.isNotEmpty;
  CustomWorkout? get existingWorkout => _existingWorkout;

  // Initialize state
  void initialize({
    required List<String> exerciseNames,
    CustomWorkout? existingWorkout,
  }) {
    _existingWorkout = existingWorkout;

    // If editing an existing workout, pre-populate with its data
    if (existingWorkout != null) {
      _exercises =
          existingWorkout.exercises.map((exercise) {
            final configExercise = ConfigExercise(title: exercise.name);
            // Replace the default empty set with the actual sets from the workout
            configExercise.sets.clear();
            for (var set in exercise.sets) {
              final configSet = ConfigSet();
              configSet.weight = set.weight;
              configSet.reps = set.reps;
              configSet.weightController.text = ConfigSet._fmt(set.weight);
              configSet.repsController.text = set.reps.toString();
              configSet.addFocusListeners(_updateFocusState);
              configExercise.sets.add(configSet);
            }
            return configExercise;
          }).toList();
      notifyListeners();
    } else {
      // Creating new workout - use exercise names and try to load previous data
      _loadExercisesWithPreviousData(exerciseNames);
    }
  }

  // Focus management

  void _removeFocusListeners() {
    for (var exercise in _exercises) {
      for (var set in exercise.sets) {
        set.removeFocusListeners(_updateFocusState);
      }
    }
  }

  void _updateFocusState() {
    bool anyFieldFocused = false;
    for (var exercise in _exercises) {
      for (var set in exercise.sets) {
        if (set.weightFocusNode.hasFocus || set.repsFocusNode.hasFocus) {
          anyFieldFocused = true;
          break;
        }
      }
      if (anyFieldFocused) break;
    }

    if (anyFieldFocused != _isAnyFieldFocused) {
      _isAnyFieldFocused = anyFieldFocused;
      notifyListeners();
    }
  }

  Future<void> _loadExercisesWithPreviousData(
    List<String> exerciseNames,
  ) async {
    List<ConfigExercise> exercises = [];

    for (final name in exerciseNames) {
      try {
        // Try to get previous exercise data
        final previousData = await WorkoutService.getLastExerciseData(name);

        List<ConfigSet> sets;
        if (previousData != null && previousData['sets'] != null) {
          // Create sets based on previous workout data
          final previousSetsData = previousData['sets'] as List<dynamic>;

          sets =
              previousSetsData.map((setData) {
                final weight = (setData['weight'] as num?)?.toDouble() ?? 0.0;
                final reps = (setData['reps'] as int?) ?? 0;
                final configSet = ConfigSet(
                  weight: weight,
                  reps: reps,
                  isWeightPrefilled: true,
                  isRepsPrefilled: true,
                  previousWeight: weight,
                  previousReps: reps,
                );
                configSet.addFocusListeners(_updateFocusState);
                return configSet;
              }).toList();
        } else {
          // No previous data, use default
          final configSet = ConfigSet();
          configSet.addFocusListeners(_updateFocusState);
          sets = [configSet];
        }

        exercises.add(ConfigExercise(title: name, sets: sets));
      } catch (e) {
        // If there's an error fetching data, use default
        final configExercise = ConfigExercise(title: name);
        // Add focus listeners to the default set
        for (var set in configExercise.sets) {
          set.addFocusListeners(_updateFocusState);
        }
        exercises.add(configExercise);
      }
    }

    _exercises = exercises;
    notifyListeners();
  }

  // Exercise management
  void addExercises(List<String> exerciseNames) async {
    final List<ConfigExercise> newExercises = [];

    for (final title in exerciseNames) {
      try {
        // Try to get previous exercise data
        final previousData = await WorkoutService.getLastExerciseData(title);

        List<ConfigSet> sets;
        if (previousData != null && previousData['sets'] != null) {
          // Create sets based on previous workout data
          final previousSetsData = previousData['sets'] as List<dynamic>;

          sets =
              previousSetsData.map((setData) {
                final weight = (setData['weight'] as num?)?.toDouble() ?? 0.0;
                final reps = (setData['reps'] as int?) ?? 0;
                final configSet = ConfigSet(
                  weight: weight,
                  reps: reps,
                  isWeightPrefilled: true,
                  isRepsPrefilled: true,
                  previousWeight: weight,
                  previousReps: reps,
                );
                configSet.addFocusListeners(_updateFocusState);
                return configSet;
              }).toList();
        } else {
          // No previous data, use default
          final configSet = ConfigSet();
          configSet.addFocusListeners(_updateFocusState);
          sets = [configSet];
        }

        newExercises.add(ConfigExercise(title: title, sets: sets));
      } catch (e) {
        // If there's an error fetching data, use default
        final configExercise = ConfigExercise(title: title);
        // Add focus listeners to the default set
        for (var set in configExercise.sets) {
          set.addFocusListeners(_updateFocusState);
        }
        newExercises.add(configExercise);
      }
    }

    _exercises.addAll(newExercises);
    notifyListeners();
  }

  void removeExercise(int index) {
    if (index < _exercises.length) {
      final exerciseToRemove = _exercises[index];
      for (var set in exerciseToRemove.sets) {
        set.removeFocusListeners(_updateFocusState);
        set.dispose();
      }

      _exercises.removeAt(index);
      notifyListeners();
    }
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final ConfigExercise item = _exercises.removeAt(oldIndex);
    _exercises.insert(newIndex, item);
    notifyListeners();
  }

  // Set management
  void addSetToExercise(ConfigExercise exercise) async {
    ConfigSet newSet;
    if (exercise.sets.isNotEmpty) {
      // Use data from the last set in current exercise
      final lastSet = exercise.sets.last;
      newSet = ConfigSet(
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

            newSet = ConfigSet(
              weight: weight,
              reps: reps,
              isWeightPrefilled: true,
              isRepsPrefilled: true,
              previousWeight: weight,
              previousReps: reps,
            );
          } else {
            newSet = ConfigSet();
          }
        } else {
          newSet = ConfigSet();
        }
      } catch (e) {
        newSet = ConfigSet();
      }
    }

    newSet.addFocusListeners(_updateFocusState);
    exercise.sets.add(newSet);
    notifyListeners();
  }

  void removeSetFromExercise(ConfigExercise exercise, ConfigSet set) {
    if (exercise.sets.length > 1) {
      set.removeFocusListeners(_updateFocusState);
      set.dispose();
      exercise.sets.remove(set);
      notifyListeners();
    }
  }

  // Reorder mode management
  void setReorderMode(bool isInReorderMode) {
    _isInReorderMode = isInReorderMode;
    _isAnyFieldFocused = false; // Ensure button stays visible
    notifyListeners();
  }

  void setPreventAutoFocus(bool preventAutoFocus) {
    _preventAutoFocus = preventAutoFocus;
    notifyListeners();
  }

  // Convert to CustomWorkout format
  List<CustomWorkoutExercise> toCustomWorkoutExercises() {
    return _exercises.map((exercise) {
      final customSets =
          exercise.sets
              .map(
                (set) => CustomWorkoutSet(weight: set.weight, reps: set.reps),
              )
              .toList();

      return CustomWorkoutExercise(name: exercise.title, sets: customSets);
    }).toList();
  }

  @override
  void dispose() {
    _removeFocusListeners();
    for (var exercise in _exercises) {
      for (var set in exercise.sets) {
        set.dispose();
      }
    }
    super.dispose();
  }
}
