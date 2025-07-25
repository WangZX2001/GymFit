import 'package:flutter/material.dart';
import 'package:gymfit/services/custom_workout_configuration_state_manager.dart';
import 'package:gymfit/components/exercise_set_row.dart';
import 'package:gymfit/components/generic_exercise_card.dart';

// Adapter for ConfigSet to work with ExerciseSetRow
class ConfigSetAdapter implements ExerciseSetData {
  final ConfigSet configSet;
  
  ConfigSetAdapter(this.configSet);
  
  @override String get id => configSet.id;
  @override double get weight => configSet.weight;
  @override int get reps => configSet.reps;
  @override bool? get isChecked => null; // No checkboxes in custom workout configuration
  @override TextEditingController get weightController => configSet.weightController;
  @override TextEditingController get repsController => configSet.repsController;
  @override FocusNode get weightFocusNode => configSet.weightFocusNode;
  @override FocusNode get repsFocusNode => configSet.repsFocusNode;
  @override bool get weightSelected => configSet.weightSelected;
  @override bool get repsSelected => configSet.repsSelected;
  @override bool get isWeightPrefilled => configSet.isWeightPrefilled;
  @override bool get isRepsPrefilled => configSet.isRepsPrefilled;
  @override String get previousDataFormatted => configSet.previousDataFormatted;
  
  @override void updateWeight(double weight) => configSet.updateWeight(weight);
  @override void updateReps(int reps) => configSet.updateReps(reps);
  
  @override set isWeightPrefilled(bool value) => configSet.isWeightPrefilled = value;
  @override set isRepsPrefilled(bool value) => configSet.isRepsPrefilled = value;
  @override set weightSelected(bool value) => configSet.weightSelected = value;
  @override set repsSelected(bool value) => configSet.repsSelected = value;
}

// Adapter for ConfigExercise to work with GenericExerciseCard
class ConfigExerciseAdapter implements ExerciseData {
  final ConfigExercise exercise;
  
  ConfigExerciseAdapter(this.exercise);
  
  @override
  String get title => exercise.title;
  
  @override
  List<dynamic> get sets => exercise.sets;
  
  @override
  bool? get isChecked => null; // No checkboxes in custom workout configuration
} 