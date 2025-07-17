import 'package:gymfit/models/workout.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/components/quick_start_overlay.dart';

class WorkoutNameGenerator {
  static String generateWorkoutName({
    String? customWorkoutName,
    required List<QuickStartExercise> selectedExercises,
    DateTime? startTime,
  }) {
    // Return custom name if set
    if (customWorkoutName != null && customWorkoutName.isNotEmpty) {
      return customWorkoutName;
    }

    final actualStartTime = startTime ?? 
        QuickStartOverlay.startTime ?? 
        DateTime.now().subtract(QuickStartOverlay.elapsedTime);

    // If no exercises selected, show a generic name based on time
    if (selectedExercises.isEmpty) {
      final hour = actualStartTime.hour;
      String timeOfDay;

      if (hour >= 5 && hour < 12) {
        timeOfDay = 'Morning';
      } else if (hour >= 12 && hour < 17) {
        timeOfDay = 'Afternoon';
      } else if (hour >= 17 && hour < 21) {
        timeOfDay = 'Evening';
      } else {
        timeOfDay = 'Night';
      }

      return '$timeOfDay Workout';
    }

    return Workout.generateDefaultName(
      startTime: actualStartTime,
      workoutDuration: QuickStartOverlay.elapsedTime,
      exerciseNames: selectedExercises.map((e) => e.title).toList(),
    );
  }
} 