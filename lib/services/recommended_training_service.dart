import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/packages/exercise_information_repository/exercise_information_repository.dart';

class RecommendedTrainingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ExerciseInformationRepository _exerciseRepo =
      ExerciseInformationRepository();

  /// Get user body data from Firestore
  static Future<Map<String, dynamic>> getUserBodyData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        throw Exception('User data not found');
      }

      return doc.data() ?? {};
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  /// Generate recommended workout based on user body data
  static Future<CustomWorkout> generateRecommendedWorkout() async {
    final userData = await getUserBodyData();
    final exercises = await _exerciseRepo.getAllExerciseInformation();

    // Extract user data
    final String goal = userData['goal'] ?? 'Gain Muscle';
    final String fitnessLevel = userData['fitness level'] ?? 'Beginner';
    final String medicalCondition = userData['medical condition'] ?? 'None';
    final int age = userData['age'] ?? 25;
    final double? bmi = userData['bmi']?.toDouble();
    final String gender = userData['gender'] ?? 'Male';

    // Filter exercises based on user data
    List<ExerciseInformation> filteredExercises = _filterExercisesByUserData(
      exercises,
      goal: goal,
      fitnessLevel: fitnessLevel,
      medicalCondition: medicalCondition,
      age: age,
      bmi: bmi,
      gender: gender,
    );

    // Select exercises for the workout
    List<ExerciseInformation> selectedExercises = _selectExercisesForWorkout(
      filteredExercises,
      goal: goal,
      fitnessLevel: fitnessLevel,
    );

    // Convert to CustomWorkoutExercise format
    List<CustomWorkoutExercise> workoutExercises =
        selectedExercises.map((exercise) {
          return CustomWorkoutExercise(
            name: exercise.title,
            sets: _generateSetsForExercise(exercise, goal, fitnessLevel),
          );
        }).toList();

    // Generate workout name and description
    String workoutName = _generateWorkoutName(goal, fitnessLevel);
    String workoutDescription = _generateWorkoutDescription(
      goal,
      fitnessLevel,
      selectedExercises,
    );

    return CustomWorkout(
      id: 'recommended_${DateTime.now().millisecondsSinceEpoch}',
      name: workoutName,
      exercises: workoutExercises,
      createdAt: DateTime.now(),
      userId: _auth.currentUser!.uid,
      description: workoutDescription,
    );
  }

  /// Filter exercises based on user data
  static List<ExerciseInformation> _filterExercisesByUserData(
    List<ExerciseInformation> exercises, {
    required String goal,
    required String fitnessLevel,
    required String medicalCondition,
    required int age,
    double? bmi,
    required String gender,
  }) {
    return exercises.where((exercise) {
      // Filter by fitness level
      if (!_isExerciseSuitableForLevel(exercise, fitnessLevel)) {
        return false;
      }

      // Filter by medical conditions
      if (!_isExerciseSafeForCondition(exercise, medicalCondition)) {
        return false;
      }

      // Filter by age considerations
      if (!_isExerciseSuitableForAge(exercise, age)) {
        return false;
      }

      // Filter by BMI considerations
      if (bmi != null && !_isExerciseSuitableForBMI(exercise, bmi)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Check if exercise is suitable for fitness level
  static bool _isExerciseSuitableForLevel(
    ExerciseInformation exercise,
    String fitnessLevel,
  ) {
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        return exercise.experienceLevel.toLowerCase() == 'beginner';
      case 'intermediate':
        return [
          'beginner',
          'intermediate',
        ].contains(exercise.experienceLevel.toLowerCase());
      case 'advance':
        return true; // Advanced users can do all exercises
      default:
        return exercise.experienceLevel.toLowerCase() == 'beginner';
    }
  }

  /// Check if exercise is safe for medical condition
  static bool _isExerciseSafeForCondition(
    ExerciseInformation exercise,
    String medicalCondition,
  ) {
    switch (medicalCondition.toLowerCase()) {
      case 'high blood pressure':
        // Avoid high-intensity exercises that can spike blood pressure
        return !exercise.title.toLowerCase().contains('deadlift') &&
            !exercise.title.toLowerCase().contains('squat') &&
            !exercise.title.toLowerCase().contains('bench press');
      case 'bone injuries':
        // Avoid heavy weight-bearing exercises
        return exercise.equipment.toLowerCase() == 'bodyweight' ||
            exercise.equipment.toLowerCase().contains('cable') ||
            exercise.equipment.toLowerCase().contains('machine');
      case 'flu':
        // Avoid strenuous exercises
        return exercise.experienceLevel.toLowerCase() == 'beginner';
      case 'none':
      default:
        return true;
    }
  }

  /// Check if exercise is suitable for age
  static bool _isExerciseSuitableForAge(ExerciseInformation exercise, int age) {
    if (age > 60) {
      // Elderly users should avoid high-impact exercises
      return exercise.equipment.toLowerCase() == 'bodyweight' ||
          exercise.equipment.toLowerCase().contains('cable') ||
          exercise.equipment.toLowerCase().contains('machine');
    }
    return true;
  }

  /// Check if exercise is suitable for BMI
  static bool _isExerciseSuitableForBMI(
    ExerciseInformation exercise,
    double bmi,
  ) {
    if (bmi > 30) {
      // Obese users should avoid high-impact exercises
      return exercise.equipment.toLowerCase() == 'bodyweight' ||
          exercise.equipment.toLowerCase().contains('cable') ||
          exercise.equipment.toLowerCase().contains('machine');
    }
    return true;
  }

  /// Select exercises for the workout based on goal
  static List<ExerciseInformation> _selectExercisesForWorkout(
    List<ExerciseInformation> exercises, {
    required String goal,
    required String fitnessLevel,
  }) {
    List<ExerciseInformation> selectedExercises = [];

    // Determine number of exercises based on fitness level
    int targetExerciseCount;
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        targetExerciseCount = 4;
        break;
      case 'intermediate':
        targetExerciseCount = 6;
        break;
      case 'advance':
        targetExerciseCount = 8;
        break;
      default:
        targetExerciseCount = 4;
    }

    // Group exercises by muscle groups
    Map<String, List<ExerciseInformation>> muscleGroups = {};
    for (var exercise in exercises) {
      String muscle = exercise.mainMuscle.toLowerCase();
      muscleGroups.putIfAbsent(muscle, () => []).add(exercise);
    }

    // Select exercises based on goal
    switch (goal.toLowerCase()) {
      case 'lose weight':
        selectedExercises = _selectWeightLossExercises(
          muscleGroups,
          targetExerciseCount,
        );
        break;
      case 'gain muscle':
        selectedExercises = _selectMuscleGainExercises(
          muscleGroups,
          targetExerciseCount,
        );
        break;
      case 'endurance':
        selectedExercises = _selectEnduranceExercises(
          muscleGroups,
          targetExerciseCount,
        );
        break;
      case 'cardio':
        selectedExercises = _selectCardioExercises(
          muscleGroups,
          targetExerciseCount,
        );
        break;
      default:
        selectedExercises = _selectMuscleGainExercises(
          muscleGroups,
          targetExerciseCount,
        );
    }

    return selectedExercises;
  }

  /// Select exercises for weight loss
  static List<ExerciseInformation> _selectWeightLossExercises(
    Map<String, List<ExerciseInformation>> muscleGroups,
    int targetCount,
  ) {
    List<ExerciseInformation> selected = [];

    // Prioritize compound movements and cardio-friendly exercises
    List<String> priorityMuscles = ['chest', 'back', 'legs', 'shoulders'];

    for (String muscle in priorityMuscles) {
      if (selected.length >= targetCount) break;

      var exercises = muscleGroups[muscle] ?? [];
      if (exercises.isNotEmpty) {
        // Select compound movements first
        var compoundExercises =
            exercises
                .where(
                  (e) =>
                      e.title.toLowerCase().contains('press') ||
                      e.title.toLowerCase().contains('row') ||
                      e.title.toLowerCase().contains('squat') ||
                      e.title.toLowerCase().contains('deadlift'),
                )
                .toList();

        if (compoundExercises.isNotEmpty) {
          selected.add(compoundExercises.first);
        } else if (exercises.isNotEmpty) {
          selected.add(exercises.first);
        }
      }
    }

    return selected;
  }

  /// Select exercises for muscle gain
  static List<ExerciseInformation> _selectMuscleGainExercises(
    Map<String, List<ExerciseInformation>> muscleGroups,
    int targetCount,
  ) {
    List<ExerciseInformation> selected = [];

    // Target all major muscle groups
    List<String> targetMuscles = [
      'chest',
      'back',
      'legs',
      'shoulders',
      'arms',
      'abs',
    ];

    for (String muscle in targetMuscles) {
      if (selected.length >= targetCount) break;

      var exercises = muscleGroups[muscle] ?? [];
      if (exercises.isNotEmpty) {
        selected.add(exercises.first);
      }
    }

    return selected;
  }

  /// Select exercises for endurance
  static List<ExerciseInformation> _selectEnduranceExercises(
    Map<String, List<ExerciseInformation>> muscleGroups,
    int targetCount,
  ) {
    List<ExerciseInformation> selected = [];

    // Focus on bodyweight and light resistance exercises
    List<String> priorityMuscles = ['legs', 'chest', 'back', 'shoulders'];

    for (String muscle in priorityMuscles) {
      if (selected.length >= targetCount) break;

      var exercises = muscleGroups[muscle] ?? [];
      var enduranceExercises =
          exercises
              .where(
                (e) =>
                    e.equipment.toLowerCase() == 'bodyweight' ||
                    e.equipment.toLowerCase().contains('cable'),
              )
              .toList();

      if (enduranceExercises.isNotEmpty) {
        selected.add(enduranceExercises.first);
      } else if (exercises.isNotEmpty) {
        selected.add(exercises.first);
      }
    }

    return selected;
  }

  /// Select exercises for cardio
  static List<ExerciseInformation> _selectCardioExercises(
    Map<String, List<ExerciseInformation>> muscleGroups,
    int targetCount,
  ) {
    List<ExerciseInformation> selected = [];

    // Focus on full-body and leg exercises
    List<String> priorityMuscles = ['legs', 'chest', 'back'];

    for (String muscle in priorityMuscles) {
      if (selected.length >= targetCount) break;

      var exercises = muscleGroups[muscle] ?? [];
      var cardioExercises =
          exercises
              .where(
                (e) =>
                    e.equipment.toLowerCase() == 'bodyweight' ||
                    e.title.toLowerCase().contains('jump') ||
                    e.title.toLowerCase().contains('burpee'),
              )
              .toList();

      if (cardioExercises.isNotEmpty) {
        selected.add(cardioExercises.first);
      } else if (exercises.isNotEmpty) {
        selected.add(exercises.first);
      }
    }

    return selected;
  }

  /// Generate sets for an exercise based on goal and fitness level
  static List<CustomWorkoutSet> _generateSetsForExercise(
    ExerciseInformation exercise,
    String goal,
    String fitnessLevel,
  ) {
    int setCount;
    int reps;
    double weight;

    switch (goal.toLowerCase()) {
      case 'lose weight':
        setCount = 3;
        reps = 15;
        weight = 0.0; // Bodyweight or light weights
        break;
      case 'gain muscle':
        setCount = fitnessLevel.toLowerCase() == 'beginner' ? 3 : 4;
        reps = 8;
        weight = 0.0; // Will be set by user
        break;
      case 'endurance':
        setCount = 3;
        reps = 20;
        weight = 0.0; // Light weights
        break;
      case 'cardio':
        setCount = 3;
        reps = 30;
        weight = 0.0; // Bodyweight
        break;
      default:
        setCount = 3;
        reps = 10;
        weight = 0.0;
    }

    return List.generate(
      setCount,
      (index) => CustomWorkoutSet(weight: weight, reps: reps),
    );
  }

  /// Generate workout name
  static String _generateWorkoutName(String goal, String fitnessLevel) {
    String goalText = goal.replaceAll(' ', '');
    String levelText = fitnessLevel.toLowerCase();
    return 'Recommended $goalText ($levelText)';
  }

  /// Generate workout description
  static String _generateWorkoutDescription(
    String goal,
    String fitnessLevel,
    List<ExerciseInformation> exercises,
  ) {
    String description =
        'This $fitnessLevel-level workout is designed to help you $goal. ';
    description +=
        'It includes ${exercises.length} exercises targeting different muscle groups. ';

    switch (goal.toLowerCase()) {
      case 'lose weight':
        description +=
            'Focus on maintaining proper form and completing all sets with controlled movements.';
        break;
      case 'gain muscle':
        description +=
            'Focus on progressive overload and proper form to maximize muscle growth.';
        break;
      case 'endurance':
        description +=
            'Focus on maintaining steady pace and completing all repetitions with good form.';
        break;
      case 'cardio':
        description +=
            'Keep your heart rate elevated throughout the workout for maximum cardiovascular benefits.';
        break;
    }

    return description;
  }
}
