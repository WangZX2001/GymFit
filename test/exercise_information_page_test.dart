import 'package:flutter_test/flutter_test.dart';
import 'package:gymfit/packages/exercise_information_repository/exercise_information_repository.dart';

void main() {
  group('ExerciseInformation Model Tests', () {
    test('should create ExerciseInformation correctly', () {
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

      expect(exercise.title, 'Bench Press');
      expect(exercise.mainMuscle, 'Chest');
      expect(exercise.secondaryMuscle, 'Triceps, Shoulders');
      expect(exercise.experienceLevel, 'Beginner');
      expect(exercise.equipment, 'Barbell');
      expect(exercise.howTo, 'Lie on bench, lower bar to chest, press up');
      expect(exercise.description, 'A compound exercise for chest development');
      expect(exercise.videoUrl, 'https://youtube.com/watch?v=example');
      expect(exercise.proTips.length, 2);
      expect(exercise.proTips[0], 'Keep feet flat on ground');
    });

    test('should handle optional videoUrl field', () {
      final exercise = ExerciseInformation(
        title: 'Push-ups',
        icon: 'lib/images/exercises/pushups.jpg',
        mainMuscle: 'Chest',
        secondaryMuscle: 'Triceps, Shoulders',
        experienceLevel: 'Beginner',
        equipment: 'Bodyweight',
        howTo: 'Start in plank position, lower body, push up',
        description: 'A bodyweight exercise for chest',
        proTips: ['Keep body straight', 'Lower chest to ground'],
      );

      expect(exercise.videoUrl, isNull);
      expect(exercise.title, 'Push-ups');
    });

    test('should handle empty proTips list', () {
      final exercise = ExerciseInformation(
        title: 'Squats',
        icon: 'lib/images/exercises/squats.jpg',
        mainMuscle: 'Legs',
        secondaryMuscle: 'Glutes',
        experienceLevel: 'Beginner',
        equipment: 'Bodyweight',
        howTo: 'Stand with feet shoulder-width apart, squat down',
        description: 'A fundamental leg exercise',
        proTips: [],
      );

      expect(exercise.proTips.length, 0);
    });

    test('should handle different experience levels', () {
      final beginnerExercise = ExerciseInformation(
        title: 'Wall Push-ups',
        icon: 'lib/images/exercises/wallPushups.jpg',
        mainMuscle: 'Chest',
        secondaryMuscle: 'Triceps',
        experienceLevel: 'Beginner',
        equipment: 'Bodyweight',
        howTo: 'Stand facing wall, place hands on wall, push',
        description: 'Beginner-friendly chest exercise',
        proTips: ['Start close to wall'],
      );

      final advancedExercise = ExerciseInformation(
        title: 'Weighted Pull-ups',
        icon: 'lib/images/exercises/weightedPullups.jpg',
        mainMuscle: 'Back',
        secondaryMuscle: 'Biceps',
        experienceLevel: 'Advanced',
        equipment: 'Pull-up bar, weight belt',
        howTo: 'Hang from bar with weight, pull up',
        description: 'Advanced back exercise',
        proTips: ['Start with light weight'],
      );

      expect(beginnerExercise.experienceLevel, 'Beginner');
      expect(advancedExercise.experienceLevel, 'Advanced');
    });

    test('should handle different equipment types', () {
      final barbellExercise = ExerciseInformation(
        title: 'Deadlift',
        icon: 'lib/images/exercises/deadlift.jpg',
        mainMuscle: 'Back',
        secondaryMuscle: 'Legs',
        experienceLevel: 'Intermediate',
        equipment: 'Barbell',
        howTo: 'Stand over barbell, grip and lift',
        description: 'Compound back exercise',
        proTips: ['Keep back straight'],
      );

      final dumbbellExercise = ExerciseInformation(
        title: 'Dumbbell Rows',
        icon: 'lib/images/exercises/dumbbellRows.jpg',
        mainMuscle: 'Back',
        secondaryMuscle: 'Biceps',
        experienceLevel: 'Beginner',
        equipment: 'Dumbbells',
        howTo: 'Bend over, row dumbbell to chest',
        description: 'Unilateral back exercise',
        proTips: ['Keep elbow close'],
      );

      expect(barbellExercise.equipment, 'Barbell');
      expect(dumbbellExercise.equipment, 'Dumbbells');
    });
  });
}
