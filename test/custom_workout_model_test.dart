import 'package:flutter_test/flutter_test.dart';
import 'package:gymfit/models/custom_workout.dart';

void main() {
  group('CustomWorkout Model Tests', () {
    test('should create CustomWorkoutExercise correctly', () {
      // Arrange
      final sets = [
        CustomWorkoutSet(weight: 100.0, reps: 10),
        CustomWorkoutSet(weight: 100.0, reps: 8),
      ];

      // Act
      final exercise = CustomWorkoutExercise(name: 'Bench Press', sets: sets);

      // Assert
      expect(exercise.name, 'Bench Press');
      expect(exercise.sets.length, 2);
      expect(exercise.sets[0].weight, 100.0);
      expect(exercise.sets[0].reps, 10);
      expect(exercise.sets[1].weight, 100.0);
      expect(exercise.sets[1].reps, 8);
    });

    test('should create CustomWorkoutSet correctly', () {
      // Act
      final set = CustomWorkoutSet(weight: 150.0, reps: 12);

      // Assert
      expect(set.weight, 150.0);
      expect(set.reps, 12);
    });

    test('should create CustomWorkout correctly', () {
      // Arrange
      final exercises = [
        CustomWorkoutExercise(
          name: 'Bench Press',
          sets: [CustomWorkoutSet(weight: 100.0, reps: 10)],
        ),
        CustomWorkoutExercise(
          name: 'Squats',
          sets: [CustomWorkoutSet(weight: 150.0, reps: 12)],
        ),
      ];

      // Act
      final workout = CustomWorkout(
        id: '1',
        name: 'Test Workout',
        exercises: exercises,
        createdAt: DateTime(2024, 1, 1),
        userId: 'user123',
        description: 'A test workout',
        pinned: true,
      );

      // Assert
      expect(workout.id, '1');
      expect(workout.name, 'Test Workout');
      expect(workout.exercises.length, 2);
      expect(workout.userId, 'user123');
      expect(workout.description, 'A test workout');
      expect(workout.pinned, true);
    });

    test('should get exercise names correctly', () {
      // Arrange
      final exercises = [
        CustomWorkoutExercise(name: 'Bench Press', sets: []),
        CustomWorkoutExercise(name: 'Squats', sets: []),
        CustomWorkoutExercise(name: 'Deadlift', sets: []),
      ];

      final workout = CustomWorkout(
        id: '1',
        name: 'Test Workout',
        exercises: exercises,
        createdAt: DateTime.now(),
        userId: 'user123',
      );

      // Act
      final exerciseNames = workout.exerciseNames;

      // Assert
      expect(exerciseNames.length, 3);
      expect(exerciseNames[0], 'Bench Press');
      expect(exerciseNames[1], 'Squats');
      expect(exerciseNames[2], 'Deadlift');
    });

    test('should convert CustomWorkoutExercise to map correctly', () {
      // Arrange
      final exercise = CustomWorkoutExercise(
        name: 'Bench Press',
        sets: [
          CustomWorkoutSet(weight: 100.0, reps: 10),
          CustomWorkoutSet(weight: 100.0, reps: 8),
        ],
      );

      // Act
      final map = exercise.toMap();

      // Assert
      expect(map['name'], 'Bench Press');
      expect(map['sets'].length, 2);
      expect(map['sets'][0]['weight'], 100.0);
      expect(map['sets'][0]['reps'], 10);
      expect(map['sets'][1]['weight'], 100.0);
      expect(map['sets'][1]['reps'], 8);
    });

    test('should convert CustomWorkoutSet to map correctly', () {
      // Arrange
      final set = CustomWorkoutSet(weight: 150.0, reps: 12);

      // Act
      final map = set.toMap();

      // Assert
      expect(map['weight'], 150.0);
      expect(map['reps'], 12);
    });

    test('should create CustomWorkoutExercise from map correctly', () {
      // Arrange
      final map = {
        'name': 'Bench Press',
        'sets': [
          {'weight': 100.0, 'reps': 10},
          {'weight': 100.0, 'reps': 8},
        ],
      };

      // Act
      final exercise = CustomWorkoutExercise.fromMap(map);

      // Assert
      expect(exercise.name, 'Bench Press');
      expect(exercise.sets.length, 2);
      expect(exercise.sets[0].weight, 100.0);
      expect(exercise.sets[0].reps, 10);
      expect(exercise.sets[1].weight, 100.0);
      expect(exercise.sets[1].reps, 8);
    });

    test('should create CustomWorkoutSet from map correctly', () {
      // Arrange
      final map = {'weight': 150.0, 'reps': 12};

      // Act
      final set = CustomWorkoutSet.fromMap(map);

      // Assert
      expect(set.weight, 150.0);
      expect(set.reps, 12);
    });

    test('should handle empty sets in CustomWorkoutExercise', () {
      // Act
      final exercise = CustomWorkoutExercise(name: 'Test', sets: []);

      // Assert
      expect(exercise.name, 'Test');
      expect(exercise.sets.length, 0);
    });

    test('should handle default values in CustomWorkoutSet', () {
      // Act
      final set = CustomWorkoutSet(weight: 0.0, reps: 0);

      // Assert
      expect(set.weight, 0.0);
      expect(set.reps, 0);
    });
  });
}
