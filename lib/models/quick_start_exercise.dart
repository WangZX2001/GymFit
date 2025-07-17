import 'package:gymfit/models/exercise_set.dart';

// Model to track exercise with multiple sets
class QuickStartExercise {
  final String title;
  List<ExerciseSet> sets;
  
  QuickStartExercise({required this.title, List<ExerciseSet>? sets})
    : sets = sets ?? [ExerciseSet()];
} 