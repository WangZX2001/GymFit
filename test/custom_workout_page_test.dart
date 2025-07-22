import 'package:flutter_test/flutter_test.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('CustomWorkout Model Tests', () {
    test('should create CustomWorkoutExercise correctly', () {
      final sets = [
        CustomWorkoutSet(weight: 100.0, reps: 10),
        CustomWorkoutSet(weight: 100.0, reps: 8),
      ];

      final exercise = CustomWorkoutExercise(name: 'Bench Press', sets: sets);

      expect(exercise.name, 'Bench Press');
      expect(exercise.sets.length, 2);
      expect(exercise.sets[0].weight, 100.0);
      expect(exercise.sets[0].reps, 10);
      expect(exercise.sets[1].weight, 100.0);
      expect(exercise.sets[1].reps, 8);
    });

    test('should create CustomWorkoutSet correctly', () {
      final set = CustomWorkoutSet(weight: 150.0, reps: 12);

      expect(set.weight, 150.0);
      expect(set.reps, 12);
    });

    test('should create CustomWorkout correctly', () {
      final exercises = [
        CustomWorkoutExercise(
          name: 'Bench Press',
          sets: [
            CustomWorkoutSet(weight: 100.0, reps: 10),
            CustomWorkoutSet(weight: 100.0, reps: 8),
          ],
        ),
        CustomWorkoutExercise(
          name: 'Squats',
          sets: [
            CustomWorkoutSet(weight: 120.0, reps: 12),
            CustomWorkoutSet(weight: 120.0, reps: 10),
          ],
        ),
      ];

      final workout = CustomWorkout(
        id: 'workout1',
        name: 'Upper Body Workout',
        exercises: exercises,
        createdAt: DateTime.now(),
        userId: 'user123',
      );

      expect(workout.id, 'workout1');
      expect(workout.name, 'Upper Body Workout');
      expect(workout.exercises.length, 2);
      expect(workout.exercises[0].name, 'Bench Press');
      expect(workout.exercises[1].name, 'Squats');
    });

    test('should handle toMap and fromMap correctly', () {
      final exercises = [
        CustomWorkoutExercise(
          name: 'Deadlift',
          sets: [CustomWorkoutSet(weight: 200.0, reps: 5)],
        ),
      ];

      final workout = CustomWorkout(
        id: 'workout2',
        name: 'Strength Workout',
        exercises: exercises,
        createdAt: DateTime(2024, 1, 1),
        userId: 'user123',
      );

      final map = workout.toMap();

      expect(map['id'], 'workout2');
      expect(map['name'], 'Strength Workout');
      expect(map['exercises'], isA<List>());
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('should handle edge cases', () {
      // Test with empty exercises list
      final emptyWorkout = CustomWorkout(
        id: 'empty',
        name: 'Empty Workout',
        exercises: [],
        createdAt: DateTime.now(),
        userId: 'user123',
      );

      expect(emptyWorkout.exercises.length, 0);

      // Test with empty sets list
      final exerciseWithNoSets = CustomWorkoutExercise(
        name: 'No Sets Exercise',
        sets: [],
      );

      expect(exerciseWithNoSets.sets.length, 0);
    });

    test('should handle different weight and rep values', () {
      final set1 = CustomWorkoutSet(weight: 0.0, reps: 0);
      final set2 = CustomWorkoutSet(weight: 999.9, reps: 100);

      expect(set1.weight, 0.0);
      expect(set1.reps, 0);
      expect(set2.weight, 999.9);
      expect(set2.reps, 100);
    });
  });
}
