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

  /// Generate sets for an exercise based on goal, fitness level, and exercise type
  static List<CustomWorkoutSet> _generateSetsForExercise(
    ExerciseInformation exercise,
    String goal,
    String fitnessLevel,
  ) {
    // Note: getUserBodyData() is async, so we'll use the data passed from the main method
    // For now, we'll focus on exercise-specific recommendations

    int setCount;
    int reps;
    double weight;

    // Determine exercise type and muscle group
    final String exerciseName = exercise.title.toLowerCase();
    final String muscleGroup = exercise.mainMuscle.toLowerCase();
    final String equipment = exercise.equipment.toLowerCase();

    // Base recommendations by goal
    switch (goal.toLowerCase()) {
      case 'lose weight':
        setCount = _getSetCountForWeightLoss(fitnessLevel);
        reps = _getRepsForWeightLoss(exerciseName, muscleGroup, equipment);
        weight = _getRecommendedWeight(
          exerciseName,
          muscleGroup,
          equipment,
          goal,
          fitnessLevel,
        );
        break;
      case 'gain muscle':
        setCount = _getSetCountForMuscleGain(fitnessLevel);
        reps = _getRepsForMuscleGain(
          exerciseName,
          muscleGroup,
          equipment,
          fitnessLevel,
        );
        weight = _getRecommendedWeight(
          exerciseName,
          muscleGroup,
          equipment,
          goal,
          fitnessLevel,
        );
        break;
      case 'endurance':
        setCount = _getSetCountForEndurance(fitnessLevel);
        reps = _getRepsForEndurance(exerciseName, muscleGroup, equipment);
        weight = _getRecommendedWeight(
          exerciseName,
          muscleGroup,
          equipment,
          goal,
          fitnessLevel,
        );
        break;
      case 'cardio':
        setCount = _getSetCountForCardio(fitnessLevel);
        reps = _getRepsForCardio(exerciseName, muscleGroup, equipment);
        weight = _getRecommendedWeight(
          exerciseName,
          muscleGroup,
          equipment,
          goal,
          fitnessLevel,
        );
        break;
      default:
        setCount = 3;
        reps = 10;
        weight = _getRecommendedWeight(
          exerciseName,
          muscleGroup,
          equipment,
          goal,
          fitnessLevel,
        );
    }

    // Create progressive sets (pyramid or reverse pyramid based on goal)
    return _createProgressiveSets(setCount, reps, weight, goal, fitnessLevel);
  }

  /// Get set count for weight loss based on fitness level
  static int _getSetCountForWeightLoss(String fitnessLevel) {
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        return 2;
      case 'intermediate':
        return 3;
      case 'advance':
        return 4;
      default:
        return 3;
    }
  }

  /// Get set count for muscle gain based on fitness level
  static int _getSetCountForMuscleGain(String fitnessLevel) {
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        return 3;
      case 'intermediate':
        return 4;
      case 'advance':
        return 5;
      default:
        return 3;
    }
  }

  /// Get set count for endurance based on fitness level
  static int _getSetCountForEndurance(String fitnessLevel) {
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        return 2;
      case 'intermediate':
        return 3;
      case 'advance':
        return 4;
      default:
        return 3;
    }
  }

  /// Get set count for cardio based on fitness level
  static int _getSetCountForCardio(String fitnessLevel) {
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        return 2;
      case 'intermediate':
        return 3;
      case 'advance':
        return 4;
      default:
        return 3;
    }
  }

  /// Get reps for weight loss based on exercise type
  static int _getRepsForWeightLoss(
    String exerciseName,
    String muscleGroup,
    String equipment,
  ) {
    // Higher reps for weight loss (12-20 range)
    int baseReps = 15;

    // Adjust based on exercise type
    if (exerciseName.contains('squat') || exerciseName.contains('deadlift')) {
      baseReps = 12; // Compound movements - slightly lower reps
    } else if (exerciseName.contains('press') || exerciseName.contains('row')) {
      baseReps = 14; // Compound upper body
    } else if (equipment == 'bodyweight') {
      baseReps = 18; // Bodyweight exercises - higher reps
    } else if (muscleGroup == 'arms') {
      baseReps = 16; // Isolation exercises
    }

    return baseReps;
  }

  /// Get reps for muscle gain based on exercise type and fitness level
  static int _getRepsForMuscleGain(
    String exerciseName,
    String muscleGroup,
    String equipment,
    String fitnessLevel,
  ) {
    // Moderate reps for muscle gain (6-12 range)
    int baseReps = 8;

    // Adjust based on fitness level
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        baseReps = 10; // Higher reps for beginners
        break;
      case 'intermediate':
        baseReps = 8;
        break;
      case 'advance':
        baseReps = 6; // Lower reps for advanced users
        break;
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

    return baseReps < 6
        ? 6
        : (baseReps > 12 ? 12 : baseReps); // Ensure reps stay in optimal range
  }

  /// Get reps for endurance based on exercise type
  static int _getRepsForEndurance(
    String exerciseName,
    String muscleGroup,
    String equipment,
  ) {
    // High reps for endurance (15-25 range)
    int baseReps = 20;

    // Adjust based on exercise type
    if (exerciseName.contains('squat') || exerciseName.contains('deadlift')) {
      baseReps = 15; // Compound movements - moderate reps
    } else if (exerciseName.contains('press') || exerciseName.contains('row')) {
      baseReps = 18; // Compound upper body
    } else if (equipment == 'bodyweight') {
      baseReps = 25; // Bodyweight exercises - very high reps
    } else if (muscleGroup == 'arms') {
      baseReps = 22; // Isolation exercises
    }

    return baseReps;
  }

  /// Get reps for cardio based on exercise type
  static int _getRepsForCardio(
    String exerciseName,
    String muscleGroup,
    String equipment,
  ) {
    // Very high reps for cardio (20-40 range)
    int baseReps = 30;

    // Adjust based on exercise type
    if (exerciseName.contains('jump') || exerciseName.contains('burpee')) {
      baseReps = 25; // High impact - moderate reps
    } else if (exerciseName.contains('mountain climber') ||
        exerciseName.contains('plank')) {
      baseReps = 40; // Low impact - very high reps
    } else if (equipment == 'bodyweight') {
      baseReps = 35; // Bodyweight exercises
    } else if (muscleGroup == 'legs') {
      baseReps = 30; // Leg exercises
    }

    return baseReps;
  }

  /// Create progressive sets with varying reps and weights
  static List<CustomWorkoutSet> _createProgressiveSets(
    int setCount,
    int baseReps,
    double baseWeight,
    String goal,
    String fitnessLevel,
  ) {
    // Use the new progressive weight system for better weight recommendations
    return _createProgressiveWeightSets(
      setCount,
      baseReps,
      baseWeight,
      goal,
      fitnessLevel,
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

  /// Get recommended weight for an exercise based on multiple factors
  static double _getRecommendedWeight(
    String exerciseName,
    String muscleGroup,
    String equipment,
    String goal,
    String fitnessLevel,
  ) {
    // Base weight recommendations by exercise type and goal
    double baseWeight = _getBaseWeightForExercise(
      exerciseName,
      muscleGroup,
      equipment,
    );

    // Adjust based on goal
    baseWeight = _adjustWeightForGoal(baseWeight, goal);

    // Adjust based on fitness level
    baseWeight = _adjustWeightForFitnessLevel(baseWeight, fitnessLevel);

    // Adjust for bodyweight exercises
    if (equipment == 'bodyweight') {
      return 0.0; // Bodyweight exercises
    }

    return baseWeight;
  }

  /// Get base weight for different exercise types
  static double _getBaseWeightForExercise(
    String exerciseName,
    String muscleGroup,
    String equipment,
  ) {
    // Base weights in kg for different exercise categories
    if (exerciseName.contains('squat') || exerciseName.contains('deadlift')) {
      return 40.0; // Compound leg movements
    } else if (exerciseName.contains('bench press') ||
        exerciseName.contains('press')) {
      return 30.0; // Compound upper body push
    } else if (exerciseName.contains('row') || exerciseName.contains('pull')) {
      return 25.0; // Compound upper body pull
    } else if (muscleGroup == 'arms') {
      return 10.0; // Isolation arm exercises
    } else if (muscleGroup == 'shoulders') {
      return 15.0; // Shoulder exercises
    } else if (muscleGroup == 'chest') {
      return 20.0; // Chest isolation
    } else if (muscleGroup == 'back') {
      return 18.0; // Back isolation
    } else if (muscleGroup == 'legs') {
      return 25.0; // Leg isolation
    } else if (muscleGroup == 'abs') {
      return 5.0; // Core exercises
    } else if (equipment.contains('cable')) {
      return 15.0; // Cable exercises
    } else if (equipment.contains('machine')) {
      return 20.0; // Machine exercises
    }

    return 15.0; // Default weight
  }

  /// Adjust weight based on fitness goal
  static double _adjustWeightForGoal(double baseWeight, String goal) {
    switch (goal.toLowerCase()) {
      case 'lose weight':
        return baseWeight * 0.6; // Lighter weights for higher reps
      case 'gain muscle':
        return baseWeight * 1.0; // Standard weight for hypertrophy
      case 'endurance':
        return baseWeight * 0.5; // Light weights for endurance
      case 'cardio':
        return 0.0; // Bodyweight for cardio
      default:
        return baseWeight * 0.8; // Moderate weight
    }
  }

  /// Adjust weight based on fitness level
  static double _adjustWeightForFitnessLevel(
    double baseWeight,
    String fitnessLevel,
  ) {
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        return baseWeight * 0.5; // 50% of base weight for beginners
      case 'intermediate':
        return baseWeight * 0.8; // 80% of base weight for intermediate
      case 'advance':
        return baseWeight * 1.2; // 120% of base weight for advanced
      default:
        return baseWeight * 0.6; // Default to beginner level
    }
  }

  /// Create progressive weight sets (pyramid or reverse pyramid)
  static List<CustomWorkoutSet> _createProgressiveWeightSets(
    int setCount,
    int baseReps,
    double baseWeight,
    String goal,
    String fitnessLevel,
  ) {
    List<CustomWorkoutSet> sets = [];

    switch (goal.toLowerCase()) {
      case 'lose weight':
        // Reverse pyramid for weight loss (decreasing weight)
        for (int i = 0; i < setCount; i++) {
          double weight = baseWeight - (i * 2.5); // Decrease by 2.5kg each set
          int reps = baseReps - (i * 2); // Decrease by 2 reps each set
          sets.add(
            CustomWorkoutSet(
              weight:
                  weight < 0.0
                      ? 0.0
                      : (weight > baseWeight ? baseWeight : weight),
              reps: reps < 8 ? 8 : (reps > baseReps ? baseReps : reps),
            ),
          );
        }
        break;
      case 'gain muscle':
        // Pyramid for muscle gain (increasing weight for advanced, consistent for beginners)
        if (fitnessLevel.toLowerCase() == 'beginner') {
          // Consistent weight for beginners
          for (int i = 0; i < setCount; i++) {
            sets.add(CustomWorkoutSet(weight: baseWeight, reps: baseReps));
          }
        } else {
          // Pyramid for intermediate/advanced
          for (int i = 0; i < setCount; i++) {
            double weight =
                baseWeight + (i * 2.5); // Increase by 2.5kg each set
            int reps = baseReps - (i * 1); // Slight decrease in reps
            sets.add(
              CustomWorkoutSet(
                weight:
                    weight < baseWeight
                        ? baseWeight
                        : (weight > baseWeight + 10.0
                            ? baseWeight + 10.0
                            : weight),
                reps: reps < 6 ? 6 : (reps > baseReps ? baseReps : reps),
              ),
            );
          }
        }
        break;
      case 'endurance':
        // Consistent light weight for endurance
        for (int i = 0; i < setCount; i++) {
          sets.add(CustomWorkoutSet(weight: baseWeight, reps: baseReps));
        }
        break;
      case 'cardio':
        // Bodyweight for cardio
        for (int i = 0; i < setCount; i++) {
          sets.add(CustomWorkoutSet(weight: 0.0, reps: baseReps));
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
}
