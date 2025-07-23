import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/packages/exercise_information_repository/exercise_information_repository.dart';
import 'package:gymfit/services/workout_service.dart'; // Added for WorkoutService
import 'package:gymfit/utils/one_rm_calculator.dart'; // Added for OneRMCalculator

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

  /// Generate recommended week plan based on user body data and preferences
  static Future<Map<String, List<CustomWorkoutExercise>>> generateRecommendedWeekPlan({
    required int daysPerWeek,
    required List<String> selectedDays,
    required String trainingSplit,
  }) async {
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

    // Shuffle exercises to add variety
    filteredExercises.shuffle();
    


    // Canonical muscle group mapping for splits
    final Map<String, String> muscleToSplitGroup = {
      // Push
      'chest': 'push',
      'upper chest': 'push',
      'lower chest': 'push',
      'shoulders': 'push',
      'front delts': 'push',
      'triceps': 'push',
      // Pull
      'back': 'pull',
      'lats': 'pull',
      'traps': 'pull',
      'biceps': 'pull',
      'rear delts': 'pull',
      'rhomboids': 'pull',
      'forearms': 'pull',
      // Legs
      'legs': 'legs',
      'quads': 'legs',
      'hamstrings': 'legs',
      'glutes': 'legs',
      'calves': 'legs',
      'adductors': 'legs',
      'abductors': 'legs',
      // Core
      'abs': 'core',
      'core': 'core',
      // Arms (for upper)
      'arms': 'arms',
    };

    // Helper to get canonical group for a muscle
    String getSplitGroup(String muscle) {
      final m = muscle.trim().toLowerCase();
      return muscleToSplitGroup[m] ?? m;
    }

    // Group exercises by canonical split group
    Map<String, List<ExerciseInformation>> splitGroupExercises = {};
    for (var exercise in filteredExercises) {
      final group = getSplitGroup(exercise.mainMuscle);
      splitGroupExercises.putIfAbsent(group, () => []).add(exercise);
    }

    // Define canonical muscle group lists for each split
    // final List<String> pushMuscles = [
    //   'chest', 'upper chest', 'lower chest', 'shoulders', 'front delts', 'triceps'
    // ];
    // final List<String> pullMuscles = [
    //   'back', 'lats', 'traps', 'biceps', 'rear delts', 'rhomboids', 'forearms'
    // ];
    // final List<String> legsMuscles = [
    //   'legs', 'quads', 'hamstrings', 'glutes', 'calves', 'adductors', 'abductors'
    // ];
    // final List<String> coreMuscles = [
    //   'abs', 'core', 'obliques'
    // ];
    // final List<String> upperMuscles = [
    //   ...pushMuscles, ...pullMuscles, 'arms'
    // ];
    // final List<String> lowerMuscles = [
    //   ...legsMuscles
    // ];

    // Refined split muscle group lists (no 'arms' catch-all)
    // final List<String> refinedPushMuscles = [
    //   'chest', 'upper chest', 'lower chest', 'shoulders', 'front delts', 'triceps'
    // ];
    // final List<String> refinedPullMuscles = [
    //   'back', 'lats', 'traps', 'biceps', 'rear delts', 'rhomboids', 'forearms'
    // ];
    // final List<String> refinedLegsMuscles = [
    //   'legs', 'quads', 'hamstrings', 'glutes', 'calves', 'adductors', 'abductors', 'core', 'abs', 'obliques'
    // ];
    // final List<String> refinedUpperMuscles = [
    //   'chest', 'upper chest', 'lower chest', 'back', 'lats', 'traps', 'shoulders', 'front delts', 'rear delts', 'rhomboids', 'biceps', 'triceps', 'forearms'
    // ];
    // final List<String> refinedLowerMuscles = [
    //   'legs', 'quads', 'hamstrings', 'glutes', 'calves', 'adductors', 'abductors', 'core', 'abs', 'obliques'
    // ];

    // Strict split muscle group lists as specified by user
    final List<String> strictPushMuscles = [
      'Chest', 'Triceps', 'Shoulders'
    ];
    final List<String> strictPullMuscles = [
      'Biceps', 'Back', 'Upper Back', 'Lower Back', 'Traps', 'Neck', 'Lats'
    ];
    final List<String> strictLegsMuscles = [
      'Legs'
    ];
    final List<String> strictUpperMuscles = [
      ...strictPushMuscles, ...strictPullMuscles
    ];
    final List<String> strictLowerMuscles = [
      ...strictLegsMuscles
    ];

    // Determine training days
    final weekDays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final days = selectedDays.isNotEmpty
        ? selectedDays
        : weekDays.sublist(0, daysPerWeek);

    // Split logic (explicit muscle group lists)
    Map<String, List<String>> splitMuscleGroups = {};
    if (trainingSplit == 'Full Body') {
      for (var day in days) {
        splitMuscleGroups[day] = [
          ...strictPushMuscles, ...strictPullMuscles, ...strictLegsMuscles
        ];
      }
    } else if (trainingSplit == 'Upper/Lower') {
      for (int i = 0; i < days.length; i++) {
        splitMuscleGroups[days[i]] =
            i % 2 == 0
                ? strictUpperMuscles
                : strictLowerMuscles;
      }
    } else if (trainingSplit == 'Push/Pull/Legs') {
      for (int i = 0; i < days.length; i++) {
        if (i % 3 == 0) {
          splitMuscleGroups[days[i]] = strictPushMuscles;
        } else if (i % 3 == 1) {
          splitMuscleGroups[days[i]] = strictPullMuscles;
        } else {
          splitMuscleGroups[days[i]] = strictLegsMuscles;
        }
      }
    }

    // For each day, select exercises for the split
    Map<String, List<CustomWorkoutExercise>> weekPlan = {};
    for (final day in days) {
      final targetMuscles = splitMuscleGroups[day] ?? [];
      List<CustomWorkoutExercise> dayExercises = [];
      // Strict filtering: Only include exercises whose normalized primary mainMuscle is in targetMuscles
      final normalizedTargetMuscles = targetMuscles.map((m) => m.trim().toLowerCase()).toSet();
      final usedMuscles = <String, int>{};
      
      // Create a list of exercises for this day's muscle groups
      List<ExerciseInformation> dayExercisesList = [];
      for (final ex in filteredExercises) {
        String main = ex.mainMuscle.split(RegExp(r'[\/,&]')).first.split('and').first.trim().toLowerCase();
        if (normalizedTargetMuscles.contains(main)) {
          dayExercisesList.add(ex);
        }
      }
      
      // Shuffle the exercises for this specific day
      dayExercisesList.shuffle();
      
      // Select exercises with limits
      for (final ex in dayExercisesList) {
        String main = ex.mainMuscle.split(RegExp(r'[\/,&]')).first.split('and').first.trim().toLowerCase();
        usedMuscles[main] = (usedMuscles[main] ?? 0) + 1;
        if (usedMuscles[main]! <= 2) {
          final sets = await _generateSetsForExercise(ex, goal, fitnessLevel);
          dayExercises.add(CustomWorkoutExercise(
            name: ex.title,
            sets: sets,
          ));
        }
      }
      
      weekPlan[day] = dayExercises;
    }

    return weekPlan;
  }

  /// Generate recommended workout based on user body data
  static Future<CustomWorkout> generateRecommendedWorkout({
    required int daysPerWeek,
    required List<String> selectedDays,
    required String trainingSplit,
  }) async {
    // Get the week plan
    final weekPlan = await generateRecommendedWeekPlan(
      daysPerWeek: daysPerWeek,
      selectedDays: selectedDays,
      trainingSplit: trainingSplit,
    );

    // Flatten for legacy compatibility
    List<CustomWorkoutExercise> allExercises = weekPlan.values.expand((e) => e).toList();
    String workoutName = 'Recommended Plan ($trainingSplit, $daysPerWeek days)';
    String workoutDescription = 'Weekly Plan:\n';
    for (final day in weekPlan.keys) {
      workoutDescription += '\n$day:\n';
      for (final ex in weekPlan[day] ?? []) {
        workoutDescription += '  - ${ex.name}\n';
      }
    }

    return CustomWorkout(
      id: 'recommended_${DateTime.now().millisecondsSinceEpoch}',
      name: workoutName,
      exercises: allExercises,
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

  // /// Select exercises for the workout based on goal
  // static List<ExerciseInformation> _selectExercisesForWorkout(
  //   List<ExerciseInformation> exercises, {
  //   required String goal,
  //   required String fitnessLevel,
  // }) {
  //   List<ExerciseInformation> selectedExercises = [];

  //   // Determine number of exercises based on fitness level
  //   int targetExerciseCount;
  //   switch (fitnessLevel.toLowerCase()) {
  //     case 'beginner':
  //       targetExerciseCount = 4;
  //       break;
  //     case 'intermediate':
  //       targetExerciseCount = 6;
  //       break;
  //     case 'advance':
  //       targetExerciseCount = 8;
  //       break;
  //     default:
  //       targetExerciseCount = 4;
  //   }

  //   // Group exercises by muscle groups
  //   Map<String, List<ExerciseInformation>> muscleGroups = {};
  //   for (var exercise in exercises) {
  //     String muscle = exercise.mainMuscle.toLowerCase();
  //     muscleGroups.putIfAbsent(muscle, () => []).add(exercise);
  //   }

  //   // Select exercises based on goal
  //   switch (goal.toLowerCase()) {
  //     case 'lose weight':
  //       selectedExercises = _selectWeightLossExercises(
  //         muscleGroups,
  //         targetExerciseCount,
  //       );
  //       break;
  //     case 'gain muscle':
  //       selectedExercises = _selectMuscleGainExercises(
  //         muscleGroups,
  //         targetExerciseCount,
  //       );
  //       break;
  //     case 'endurance':
  //       selectedExercises = _selectEnduranceExercises(
  //         muscleGroups,
  //         targetExerciseCount,
  //       );
  //       break;
  //     case 'cardio':
  //       selectedExercises = _selectCardioExercises(
  //         muscleGroups,
  //         targetExerciseCount,
  //       );
  //       break;
  //     default:
  //       selectedExercises = _selectMuscleGainExercises(
  //         muscleGroups,
  //         targetExerciseCount,
  //       );
  //   }

  //   return selectedExercises;
  // }

  // /// Select exercises for weight loss
  // static List<ExerciseInformation> _selectWeightLossExercises(
  //   Map<String, List<ExerciseInformation>> muscleGroups,
  //   int targetCount,
  // ) {
  //   List<ExerciseInformation> selected = [];

  //   // Prioritize compound movements and cardio-friendly exercises
  //   List<String> priorityMuscles = ['chest', 'back', 'legs', 'shoulders'];

  //   for (String muscle in priorityMuscles) {
  //     if (selected.length >= targetCount) break;

  //     var exercises = muscleGroups[muscle] ?? [];
  //     if (exercises.isNotEmpty) {
  //       // Select compound movements first
  //       var compoundExercises =
  //           exercises
  //               .where(
  //                 (e) =>
  //                     e.title.toLowerCase().contains('press') ||
  //                     e.title.toLowerCase().contains('row') ||
  //                     e.title.toLowerCase().contains('squat') ||
  //                     e.title.toLowerCase().contains('deadlift'),
  //               )
  //               .toList();

  //       if (compoundExercises.isNotEmpty) {
  //         selected.add(compoundExercises.first);
  //       } else if (exercises.isNotEmpty) {
  //         selected.add(exercises.first);
  //       }
  //     }
  //   }

  //   return selected;
  // }

  // /// Select exercises for muscle gain
  // static List<ExerciseInformation> _selectMuscleGainExercises(
  //   Map<String, List<ExerciseInformation>> muscleGroups,
  //   int targetCount,
  // ) {
  //   List<ExerciseInformation> selected = [];

  //   // Target all major muscle groups
  //   List<String> targetMuscles = [
  //     'chest',
  //     'back',
  //     'legs',
  //     'shoulders',
  //     'arms',
  //     'abs',
  //   ];

  //   for (String muscle in targetMuscles) {
  //     if (selected.length >= targetCount) break;

  //     var exercises = muscleGroups[muscle] ?? [];
  //     if (exercises.isNotEmpty) {
  //       selected.add(exercises.first);
  //     }
  //   }

  //   return selected;
  // }

  // /// Select exercises for endurance
  // static List<ExerciseInformation> _selectEnduranceExercises(
  //   Map<String, List<ExerciseInformation>> muscleGroups,
  //   int targetCount,
  // ) {
  //   List<ExerciseInformation> selected = [];

  //   // Focus on bodyweight and light resistance exercises
  //   List<String> priorityMuscles = ['legs', 'chest', 'back', 'shoulders'];

  //   for (String muscle in priorityMuscles) {
  //     if (selected.length >= targetCount) break;

  //     var exercises = muscleGroups[muscle] ?? [];
  //     var enduranceExercises =
  //           exercises
  //               .where(
  //                 (e) =>
  //                     e.equipment.toLowerCase() == 'bodyweight' ||
  //                     e.equipment.toLowerCase().contains('cable'),
  //               )
  //               .toList();

  //   if (enduranceExercises.isNotEmpty) {
  //     selected.add(enduranceExercises.first);
  //   } else if (exercises.isNotEmpty) {
  //     selected.add(exercises.first);
  //   }
  //   }

  //   return selected;
  // }

  // /// Select exercises for cardio
  // static List<ExerciseInformation> _selectCardioExercises(
  //   Map<String, List<ExerciseInformation>> muscleGroups,
  //   int targetCount,
  // ) {
  //   List<ExerciseInformation> selected = [];

  //   // Focus on full-body and leg exercises
  //   List<String> priorityMuscles = ['legs', 'chest', 'back'];

  //   for (String muscle in priorityMuscles) {
  //     if (selected.length >= targetCount) break;

  //     var exercises = muscleGroups[muscle] ?? [];
  //     var cardioExercises =
  //           exercises
  //               .where(
  //                 (e) =>
  //                     e.equipment.toLowerCase() == 'bodyweight' ||
  //                     e.title.toLowerCase().contains('jump') ||
  //                     e.title.toLowerCase().contains('burpee'),
  //               )
  //               .toList();

  //   if (cardioExercises.isNotEmpty) {
  //     selected.add(cardioExercises.first);
  //   } else if (exercises.isNotEmpty) {
  //     selected.add(exercises.first);
  //   }
  //   }

  //   return selected;
  // }

  /// Generate sets for an exercise based on goal, fitness level, and exercise type
  static Future<List<CustomWorkoutSet>> _generateSetsForExercise(
    ExerciseInformation exercise,
    String goal,
    String fitnessLevel,
  ) async {
    // Get user's 1RM data for this exercise
    final user1RM = await _getUser1RMForExercise(exercise.title);
    final userBodyWeight = await _getUserBodyWeight();
    
    int setCount;
    int reps;
    double weight;

    // Determine exercise type and muscle group
    final String exerciseName = exercise.title.toLowerCase();
    final String muscleGroup = exercise.mainMuscle.toLowerCase();
    final String equipment = exercise.equipment.toLowerCase();

    // Get personalized weight based on 1RM or body weight
    weight = await _getPersonalizedWeight(
      exercise,
      user1RM,
      userBodyWeight,
      goal,
      fitnessLevel,
    );

    // Get reps based on goal and exercise type
    reps = _getPersonalizedReps(
      exerciseName,
      muscleGroup,
      equipment,
      goal,
      fitnessLevel,
      user1RM,
    );

    // Get set count based on fitness level and goal
    setCount = _getPersonalizedSetCount(fitnessLevel, goal);

    // Create progressive sets with personalized progression
    return _createPersonalizedProgressiveSets(
      setCount,
      reps,
      weight,
      goal,
      fitnessLevel,
      user1RM,
    );
  }

  /// Get user's 1RM for a specific exercise
  static Future<double?> _getUser1RMForExercise(String exerciseName) async {
    try {
      final workouts = await WorkoutService.getUserWorkouts();
      double? max1RM;
      
      for (final workout in workouts) {
        for (final exercise in workout.exercises) {
          if (exercise.title.toLowerCase() == exerciseName.toLowerCase()) {
            for (final set in exercise.sets) {
              if (set.isCompleted && set.weight > 0 && set.reps > 0) {
                final estimated1RM = _calculate1RM(set.weight, set.reps);
                if (max1RM == null || estimated1RM > max1RM) {
                  max1RM = estimated1RM;
                }
              }
            }
          }
        }
      }
      
      return max1RM;
    } catch (e) {
      // print('Error getting 1RM for $exerciseName: $e');
      return null;
    }
  }

  /// Calculate 1RM using Brzycki formula
  static double _calculate1RM(double weight, int reps) {
    return OneRMCalculator.brzycki(weight, reps);
  }

  /// Get user's body weight from profile data
  static Future<double?> _getUserBodyWeight() async {
    try {
      final userData = await getUserBodyData();
      final height = userData['height']?.toDouble();
      final bmi = userData['bmi']?.toDouble();
      
      if (height != null && bmi != null) {
        // Calculate weight from BMI: weight = BMI * (height/100)^2
        return bmi * (height / 100) * (height / 100);
      }
      
      return null;
    } catch (e) {
      // print('Error getting user body weight: $e');
      return null;
    }
  }

  /// Get personalized weight based on 1RM, body weight, and user data
  static Future<double> _getPersonalizedWeight(
    ExerciseInformation exercise,
    double? user1RM,
    double? userBodyWeight,
    String goal,
    String fitnessLevel,
  ) async {
    // final String exerciseName = exercise.title.toLowerCase();
    // final String muscleGroup = exercise.mainMuscle.toLowerCase();
    // final String equipment = exercise.equipment.toLowerCase();

    // If we have 1RM data, use it as the primary source
    if (user1RM != null && user1RM > 0) {
      return _getWeightFrom1RM(user1RM, goal, fitnessLevel);
    }

    // Fallback to body weight based calculations
    if (userBodyWeight != null && userBodyWeight > 0) {
      return _getWeightFromBodyWeight(userBodyWeight, exercise, goal, fitnessLevel);
    }

    // Final fallback to generic calculations
    return _getGenericWeight(exercise, goal, fitnessLevel);
  }

  /// Calculate weight from 1RM data
  static double _getWeightFrom1RM(double oneRM, String goal, String fitnessLevel) {
    double percentage;
    
    // Set percentage based on goal
    switch (goal.toLowerCase()) {
      case 'lose weight':
        percentage = 0.65; // 65% of 1RM for higher reps
        break;
      case 'gain muscle':
        percentage = 0.75; // 75% of 1RM for hypertrophy
        break;
      case 'endurance':
        percentage = 0.55; // 55% of 1RM for endurance
        break;
      case 'strength':
        percentage = 0.85; // 85% of 1RM for strength
        break;
      default:
        percentage = 0.70; // 70% of 1RM default
    }

    // Adjust based on fitness level
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        percentage *= 0.8; // Reduce weight for beginners
        break;
      case 'intermediate':
        percentage *= 0.9; // Slight reduction for intermediate
        break;
      case 'advance':
        percentage *= 1.0; // Full percentage for advanced
        break;
      default:
        percentage *= 0.85;
    }

    return (oneRM * percentage).roundToDouble();
  }

  /// Calculate weight from body weight
  static double _getWeightFromBodyWeight(
    double bodyWeight,
    ExerciseInformation exercise,
    String goal,
    String fitnessLevel,
  ) {
    final String exerciseName = exercise.title.toLowerCase();
    final String equipment = exercise.equipment.toLowerCase();

    // Bodyweight exercises
    if (equipment == 'bodyweight') {
      return 0.0;
    }

    // Calculate weight as percentage of body weight
    double bodyWeightPercentage;
    
    if (exerciseName.contains('squat') || exerciseName.contains('deadlift')) {
      bodyWeightPercentage = 0.6; // 60% of body weight for compound leg movements
    } else if (exerciseName.contains('bench press') || exerciseName.contains('press')) {
      bodyWeightPercentage = 0.4; // 40% of body weight for compound upper body
    } else if (exerciseName.contains('row') || exerciseName.contains('pull')) {
      bodyWeightPercentage = 0.35; // 35% of body weight for pulling movements
    } else if (exerciseName.contains('curl') || exerciseName.contains('tricep')) {
      bodyWeightPercentage = 0.15; // 15% of body weight for arm isolation
    } else if (exerciseName.contains('shoulder') || exerciseName.contains('lateral')) {
      bodyWeightPercentage = 0.2; // 20% of body weight for shoulder exercises
    } else {
      bodyWeightPercentage = 0.25; // 25% of body weight default
    }

    // Adjust based on goal
    switch (goal.toLowerCase()) {
      case 'lose weight':
        bodyWeightPercentage *= 0.7; // Reduce for weight loss
        break;
      case 'gain muscle':
        bodyWeightPercentage *= 1.0; // Standard for muscle gain
        break;
      case 'endurance':
        bodyWeightPercentage *= 0.5; // Reduce for endurance
        break;
      case 'strength':
        bodyWeightPercentage *= 1.2; // Increase for strength
        break;
    }

    // Adjust based on fitness level
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        bodyWeightPercentage *= 0.6; // Reduce for beginners
        break;
      case 'intermediate':
        bodyWeightPercentage *= 0.8; // Moderate for intermediate
        break;
      case 'advance':
        bodyWeightPercentage *= 1.0; // Full for advanced
        break;
    }

    return (bodyWeight * bodyWeightPercentage).roundToDouble();
  }

  /// Get generic weight (fallback method)
  static double _getGenericWeight(
    ExerciseInformation exercise,
    String goal,
    String fitnessLevel,
  ) {
    final String exerciseName = exercise.title.toLowerCase();
    final String muscleGroup = exercise.mainMuscle.toLowerCase();
    final String equipment = exercise.equipment.toLowerCase();

    // Base weights in kg
    double baseWeight;
    
    if (exerciseName.contains('squat') || exerciseName.contains('deadlift')) {
      baseWeight = 40.0;
    } else if (exerciseName.contains('bench press') || exerciseName.contains('press')) {
      baseWeight = 30.0;
    } else if (exerciseName.contains('row') || exerciseName.contains('pull')) {
      baseWeight = 25.0;
    } else if (muscleGroup == 'arms') {
      baseWeight = 10.0;
    } else if (muscleGroup == 'shoulders') {
      baseWeight = 15.0;
    } else if (muscleGroup == 'chest') {
      baseWeight = 20.0;
    } else if (muscleGroup == 'back') {
      baseWeight = 18.0;
    } else if (muscleGroup == 'legs') {
      baseWeight = 25.0;
    } else if (equipment.contains('cable')) {
      baseWeight = 15.0;
    } else if (equipment.contains('machine')) {
      baseWeight = 20.0;
    } else {
      baseWeight = 15.0;
    }

    // Adjust based on goal
    switch (goal.toLowerCase()) {
      case 'lose weight':
        baseWeight *= 0.6;
        break;
      case 'gain muscle':
        baseWeight *= 1.0;
        break;
      case 'endurance':
        baseWeight *= 0.5;
        break;
      case 'strength':
        baseWeight *= 1.2;
        break;
    }

    // Adjust based on fitness level
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        baseWeight *= 0.5;
        break;
      case 'intermediate':
        baseWeight *= 0.8;
        break;
      case 'advance':
        baseWeight *= 1.2;
        break;
    }

    return baseWeight.roundToDouble();
  }

  /// Get personalized reps based on goal, exercise type, and user data
  static int _getPersonalizedReps(
    String exerciseName,
    String muscleGroup,
    String equipment,
    String goal,
    String fitnessLevel,
    double? user1RM,
  ) {
    int baseReps;

    // Set base reps based on goal
    switch (goal.toLowerCase()) {
      case 'lose weight':
        baseReps = 15; // Higher reps for weight loss
        break;
      case 'gain muscle':
        baseReps = 10; // Moderate reps for hypertrophy
        break;
      case 'endurance':
        baseReps = 20; // High reps for endurance
        break;
      case 'strength':
        baseReps = 6; // Lower reps for strength
        break;
      default:
        baseReps = 12;
    }

    // Adjust based on exercise type
    if (exerciseName.contains('squat') || exerciseName.contains('deadlift')) {
      baseReps = (baseReps * 0.8).round(); // Compound movements - lower reps
    } else if (exerciseName.contains('press') || exerciseName.contains('row')) {
      baseReps = (baseReps * 0.9).round(); // Compound upper body
    } else if (equipment == 'bodyweight') {
      baseReps = (baseReps * 1.2).round(); // Bodyweight - higher reps
    } else if (muscleGroup == 'arms') {
      baseReps = (baseReps * 1.1).round(); // Isolation exercises
    }

    // Adjust based on fitness level
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        baseReps = (baseReps * 1.1).round(); // Higher reps for beginners
        break;
      case 'intermediate':
        baseReps = baseReps; // Standard reps
        break;
      case 'advance':
        baseReps = (baseReps * 0.9).round(); // Lower reps for advanced
        break;
    }

    // Ensure reps stay in reasonable range
    if (baseReps < 6) baseReps = 6;
    if (baseReps > 25) baseReps = 25;

    return baseReps;
  }

  /// Get personalized set count
  static int _getPersonalizedSetCount(String fitnessLevel, String goal) {
    int baseSets;

    // Set count based on fitness level
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        baseSets = 3;
        break;
      case 'intermediate':
        baseSets = 4;
        break;
      case 'advance':
        baseSets = 5;
        break;
      default:
        baseSets = 3;
    }

    // Adjust based on goal
    switch (goal.toLowerCase()) {
      case 'lose weight':
        baseSets = (baseSets * 1.1).round(); // More sets for weight loss
        break;
      case 'endurance':
        baseSets = (baseSets * 1.2).round(); // More sets for endurance
        break;
      case 'strength':
        baseSets = (baseSets * 0.9).round(); // Fewer sets for strength
        break;
    }

    // Ensure sets stay in reasonable range
    if (baseSets < 2) baseSets = 2;
    if (baseSets > 6) baseSets = 6;

    return baseSets;
  }

  /// Create personalized progressive sets with intelligent progression
  static List<CustomWorkoutSet> _createPersonalizedProgressiveSets(
    int setCount,
    int baseReps,
    double baseWeight,
    String goal,
    String fitnessLevel,
    double? user1RM,
  ) {
    List<CustomWorkoutSet> sets = [];

    switch (goal.toLowerCase()) {
      case 'lose weight':
        // Reverse pyramid for weight loss (decreasing weight, increasing reps)
        for (int i = 0; i < setCount; i++) {
          double weight = baseWeight - (i * 2.5); // Decrease by 2.5kg each set
          int reps = baseReps + (i * 2); // Increase by 2 reps each set
          
          // Ensure weight doesn't go below 0
          weight = weight < 0.0 ? 0.0 : weight;
          // Ensure reps stay in reasonable range
          reps = reps < 8 ? 8 : (reps > 25 ? 25 : reps);
          
          sets.add(CustomWorkoutSet(weight: weight, reps: reps));
        }
        break;

      case 'gain muscle':
        // Pyramid for muscle gain (increasing weight, decreasing reps)
        if (fitnessLevel.toLowerCase() == 'beginner') {
          // Consistent weight for beginners
          for (int i = 0; i < setCount; i++) {
            sets.add(CustomWorkoutSet(weight: baseWeight, reps: baseReps));
          }
        } else {
          // Pyramid for intermediate/advanced
          for (int i = 0; i < setCount; i++) {
            double weight = baseWeight + (i * 2.5); // Increase by 2.5kg each set
            int reps = baseReps - (i * 1); // Slight decrease in reps
            
            // Ensure reps stay in reasonable range
            reps = reps < 6 ? 6 : (reps > baseReps ? baseReps : reps);
            
            sets.add(CustomWorkoutSet(weight: weight, reps: reps));
          }
        }
        break;

      case 'endurance':
        // Consistent light weight for endurance
        for (int i = 0; i < setCount; i++) {
          sets.add(CustomWorkoutSet(weight: baseWeight, reps: baseReps));
        }
        break;

      case 'strength':
        // Heavy weight, low reps for strength
        for (int i = 0; i < setCount; i++) {
          double weight = baseWeight + (i * 5.0); // Increase by 5kg each set
          int reps = baseReps - (i * 2); // Decrease reps more aggressively
          
          // Ensure reps stay in strength range
          reps = reps < 3 ? 3 : (reps > 8 ? 8 : reps);
          
          sets.add(CustomWorkoutSet(weight: weight, reps: reps));
        }
        break;

      default:
        // Default consistent weight
        for (int i = 0; i < setCount; i++) {
          sets.add(CustomWorkoutSet(weight: baseWeight, reps: baseReps));
        }
    }

    return sets;
  }

  // /// Generate workout name
  // static String _generateWorkoutName(String goal, String fitnessLevel) {
  //   String goalText = goal.replaceAll(' ', '');
  //   String levelText = fitnessLevel.toLowerCase();
  //   return 'Recommended $goalText ($levelText)';
  // }

  // /// Generate workout description
  // static String _generateWorkoutDescription(
  //   String goal,
  //   String fitnessLevel,
  //   List<ExerciseInformation> exercises,
  // ) {
  //   String description =
  //       'This $fitnessLevel-level workout is designed to help you $goal. ';
  //   description +=
  //       'It includes ${exercises.length} exercises targeting different muscle groups. ';

  //   switch (goal.toLowerCase()) {
  //     case 'lose weight':
  //       description +=
  //           'Focus on maintaining proper form and completing all sets with controlled movements.';
  //       break;
  //     case 'gain muscle':
  //       description +=
  //           'Focus on progressive overload and proper form to maximize muscle growth.';
  //       break;
  //     case 'endurance':
  //       description +=
  //           'Focus on maintaining steady pace and completing all repetitions with good form.';
  //       break;
  //     case 'cardio':
  //       description +=
  //           'Keep your heart rate elevated throughout the workout for maximum cardiovascular benefits.';
  //       break;
  //   }

  //   return description;
  // }

}
