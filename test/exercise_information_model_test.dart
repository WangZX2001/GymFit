import 'package:flutter_test/flutter_test.dart';
import 'package:gymfit/packages/exercise_information_repository/exercise_information_repository.dart';

void main() {
  group('ExerciseInformation Model Tests', () {
    test('should create ExerciseInformation correctly', () {
      // Act
      final exercise = ExerciseInformation(
        title: 'Bench Press',
        icon: 'lib/images/exercises/benchPress.jpg',
        mainMuscle: 'Chest',
        secondaryMuscle: 'Triceps, Shoulders',
        experienceLevel: 'Beginner',
        equipment: 'Barbell',
        howTo: 'Lie on bench, lower bar to chest, press up',
        description: 'A compound exercise for chest development',
        videoUrl: 'https://youtube.com/watch?v=example',
        proTips: ['Keep feet flat on ground', 'Retract shoulder blades'],
      );

      // Assert
      expect(exercise.title, 'Bench Press');
      expect(exercise.icon, 'lib/images/exercises/benchPress.jpg');
      expect(exercise.mainMuscle, 'Chest');
      expect(exercise.secondaryMuscle, 'Triceps, Shoulders');
      expect(exercise.experienceLevel, 'Beginner');
      expect(exercise.equipment, 'Barbell');
      expect(exercise.howTo, 'Lie on bench, lower bar to chest, press up');
      expect(exercise.description, 'A compound exercise for chest development');
      expect(exercise.videoUrl, 'https://youtube.com/watch?v=example');
      expect(exercise.proTips.length, 2);
      expect(exercise.proTips[0], 'Keep feet flat on ground');
      expect(exercise.proTips[1], 'Retract shoulder blades');
    });

    test('should create ExerciseInformation without optional fields', () {
      // Act
      final exercise = ExerciseInformation(
        title: 'Push-ups',
        icon: 'lib/images/exercises/pushup.jpg',
        mainMuscle: 'Chest',
        secondaryMuscle: 'Triceps',
        experienceLevel: 'Beginner',
        equipment: 'Bodyweight',
        howTo: 'Plank position, lower body, push up',
        description: 'A bodyweight exercise',
        proTips: ['Keep body straight'],
      );

      // Assert
      expect(exercise.title, 'Push-ups');
      expect(exercise.videoUrl, isNull);
      expect(exercise.proTips.length, 1);
    });

    test('should handle empty proTips list', () {
      // Act
      final exercise = ExerciseInformation(
        title: 'Test Exercise',
        icon: 'test.jpg',
        mainMuscle: 'Test',
        secondaryMuscle: 'Test',
        experienceLevel: 'Beginner',
        equipment: 'Test',
        howTo: 'Test instructions',
        description: 'Test description',
        proTips: [],
      );

      // Assert
      expect(exercise.proTips.length, 0);
    });

    test('should handle single pro tip', () {
      // Act
      final exercise = ExerciseInformation(
        title: 'Test Exercise',
        icon: 'test.jpg',
        mainMuscle: 'Test',
        secondaryMuscle: 'Test',
        experienceLevel: 'Beginner',
        equipment: 'Test',
        howTo: 'Test instructions',
        description: 'Test description',
        proTips: ['Single tip'],
      );

      // Assert
      expect(exercise.proTips.length, 1);
      expect(exercise.proTips[0], 'Single tip');
    });

    test('should handle multiple pro tips', () {
      // Act
      final exercise = ExerciseInformation(
        title: 'Test Exercise',
        icon: 'test.jpg',
        mainMuscle: 'Test',
        secondaryMuscle: 'Test',
        experienceLevel: 'Beginner',
        equipment: 'Test',
        howTo: 'Test instructions',
        description: 'Test description',
        proTips: ['Tip 1', 'Tip 2', 'Tip 3'],
      );

      // Assert
      expect(exercise.proTips.length, 3);
      expect(exercise.proTips[0], 'Tip 1');
      expect(exercise.proTips[1], 'Tip 2');
      expect(exercise.proTips[2], 'Tip 3');
    });

    test('should handle different experience levels', () {
      // Test Beginner
      final beginnerExercise = ExerciseInformation(
        title: 'Beginner Exercise',
        icon: 'test.jpg',
        mainMuscle: 'Test',
        secondaryMuscle: 'Test',
        experienceLevel: 'Beginner',
        equipment: 'Test',
        howTo: 'Test',
        description: 'Test',
        proTips: [],
      );

      // Test Intermediate
      final intermediateExercise = ExerciseInformation(
        title: 'Intermediate Exercise',
        icon: 'test.jpg',
        mainMuscle: 'Test',
        secondaryMuscle: 'Test',
        experienceLevel: 'Intermediate',
        equipment: 'Test',
        howTo: 'Test',
        description: 'Test',
        proTips: [],
      );

      // Test Advanced
      final advancedExercise = ExerciseInformation(
        title: 'Advanced Exercise',
        icon: 'test.jpg',
        mainMuscle: 'Test',
        secondaryMuscle: 'Test',
        experienceLevel: 'Advanced',
        equipment: 'Test',
        howTo: 'Test',
        description: 'Test',
        proTips: [],
      );

      // Assert
      expect(beginnerExercise.experienceLevel, 'Beginner');
      expect(intermediateExercise.experienceLevel, 'Intermediate');
      expect(advancedExercise.experienceLevel, 'Advanced');
    });

    test('should handle different equipment types', () {
      // Test different equipment types
      final equipmentTypes = [
        'Barbell',
        'Dumbbell',
        'Bodyweight',
        'Machine',
        'Cable',
      ];

      for (final equipment in equipmentTypes) {
        final exercise = ExerciseInformation(
          title: 'Test Exercise',
          icon: 'test.jpg',
          mainMuscle: 'Test',
          secondaryMuscle: 'Test',
          experienceLevel: 'Beginner',
          equipment: equipment,
          howTo: 'Test',
          description: 'Test',
          proTips: [],
        );

        expect(exercise.equipment, equipment);
      }
    });

    test('should handle different muscle groups', () {
      // Test different muscle groups
      final muscleGroups = [
        'Chest',
        'Back',
        'Legs',
        'Shoulders',
        'Arms',
        'Core',
      ];

      for (final muscle in muscleGroups) {
        final exercise = ExerciseInformation(
          title: 'Test Exercise',
          icon: 'test.jpg',
          mainMuscle: muscle,
          secondaryMuscle: 'Test',
          experienceLevel: 'Beginner',
          equipment: 'Test',
          howTo: 'Test',
          description: 'Test',
          proTips: [],
        );

        expect(exercise.mainMuscle, muscle);
      }
    });
  });
}
