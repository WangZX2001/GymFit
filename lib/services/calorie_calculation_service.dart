import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalorieCalculationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get user body data for calorie calculations
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

  /// Calculate MET (Metabolic Equivalent of Task) for different exercise types
  static double _getMETForExercise(String exerciseName) {
    final name = exerciseName.toLowerCase();

    // Strength training exercises
    if (name.contains('bench press') || name.contains('chest press')) {
      return 3.8;
    }
    if (name.contains('squat') || name.contains('deadlift')) {
      return 5.0;
    }
    if (name.contains('row') || name.contains('pull')) {
      return 4.0;
    }
    if (name.contains('curl') || name.contains('bicep')) {
      return 3.0;
    }
    if (name.contains('press') || name.contains('shoulder')) {
      return 3.5;
    }
    if (name.contains('fly') || name.contains('cable')) {
      return 3.2;
    }
    if (name.contains('pulldown') || name.contains('lat')) {
      return 4.2;
    }
    if (name.contains('tricep') || name.contains('pushdown')) {
      return 3.0;
    }
    if (name.contains('overhead') || name.contains('military')) {
      return 3.8;
    }

    // Bodyweight exercises
    if (name.contains('push-up') || name.contains('pushup')) {
      return 3.8;
    }
    if (name.contains('pull-up') || name.contains('pullup')) {
      return 8.0;
    }
    if (name.contains('burpee')) {
      return 8.0;
    }
    if (name.contains('jump') || name.contains('jumping')) {
      return 8.0;
    }
    if (name.contains('plank')) {
      return 4.0;
    }
    if (name.contains('crunch') || name.contains('sit-up')) {
      return 3.0;
    }
    if (name.contains('lunge')) {
      return 5.0;
    }
    if (name.contains('mountain climber')) {
      return 8.0;
    }

    // Cardio exercises
    if (name.contains('run') || name.contains('jog')) {
      return 7.0;
    }
    if (name.contains('walk')) {
      return 3.5;
    }
    if (name.contains('cycle') || name.contains('bike')) {
      return 6.0;
    }
    if (name.contains('swim')) {
      return 6.0;
    }

    // Default MET for general strength training
    return 3.5;
  }

  /// Calculate calories burnt for a single exercise
  static double _calculateExerciseCalories({
    required String exerciseName,
    required int sets,
    required num reps,
    required double weight,
    required double userWeight,
    required int age,
    required String gender,
    required int durationMinutes,
  }) {
    final met = _getMETForExercise(exerciseName);

    // Calculate calories using the formula: Calories = MET × Weight (kg) × Duration (hours)
    // For strength training, we also factor in the intensity based on weight and reps
    double intensityMultiplier = 1.0;

    if (weight > 0) {
      // Adjust intensity based on weight relative to body weight
      final weightRatio = weight / userWeight;
      if (weightRatio > 0.5) {
        intensityMultiplier = 1.3;
      } else if (weightRatio > 0.3) {
        intensityMultiplier = 1.2;
      } else if (weightRatio > 0.1) {
        intensityMultiplier = 1.1;
      }
    }

    // Adjust for age and gender
    double ageGenderMultiplier = 1.0;
    if (gender.toLowerCase() == 'female') {
      ageGenderMultiplier = 0.9; // Women typically burn slightly fewer calories
    }
    if (age > 50) {
      ageGenderMultiplier *= 0.95; // Slight reduction for older adults
    }

    // Calculate base calories
    final durationHours = durationMinutes / 60.0;
    final baseCalories = met * userWeight * durationHours;

    // Apply multipliers and set factor
    final totalCalories =
        baseCalories * intensityMultiplier * ageGenderMultiplier * (sets / 3.0);

    return totalCalories;
  }

  /// Calculate total calories burnt for a workout
  static Future<double> calculateTotalCalories({
    required List<Map<String, dynamic>> exercises,
    required int totalDurationMinutes,
  }) async {
    // First, try to calculate with user data
    try {
      final userData = await getUserBodyData();

      // Extract user data
      final double userWeight =
          (userData['starting weight'] ?? 70.0).toDouble();
      final int age = userData['age'] ?? 25;
      final String gender = userData['gender'] ?? 'Male';

      double totalCalories = 0.0;

      // Calculate calories for each exercise
      for (final exercise in exercises) {
        final exerciseName = exercise['title'] as String;
        final sets = exercise['sets'] as List<dynamic>;

        // Count completed sets
        final completedSets =
            sets.where((set) => set['isChecked'] == true).length;

        if (completedSets > 0) {
          // Get average weight and reps from completed sets
          double totalWeight = 0.0;
          int totalReps = 0;
          int validSets = 0;

          for (final set in sets) {
            if (set['isChecked'] == true) {
              totalWeight += (set['weight'] ?? 0.0).toDouble();
              totalReps += int.parse((set['reps'] ?? 0).toString());
              validSets++;
            }
          }

          final avgWeight = validSets > 0 ? totalWeight / validSets : 0.0;
          final avgReps = validSets > 0 ? (totalReps / validSets).round() : 0;

          // Calculate calories for this exercise
          final exerciseCalories = _calculateExerciseCalories(
            exerciseName: exerciseName,
            sets: completedSets,
            reps: avgReps,
            weight: avgWeight,
            userWeight: userWeight,
            age: age,
            gender: gender,
            durationMinutes:
                totalDurationMinutes ~/
                exercises.length, // Distribute time evenly
          );

          totalCalories += exerciseCalories;
        }
      }

      // Add base metabolic rate contribution during workout
      final bmrContribution = _calculateBMRContribution(
        userWeight,
        age,
        gender,
        totalDurationMinutes,
      );
      totalCalories += bmrContribution;

      // Ensure we always return a reasonable value
      if (totalCalories <= 0) {
        return _calculateEstimatedCalories(exercises, totalDurationMinutes);
      }
      return totalCalories;
    } catch (e) {
      // Return estimated calories if user data is not available
      final estimatedCalories = _calculateEstimatedCalories(
        exercises,
        totalDurationMinutes,
      );
      return estimatedCalories;
    }
  }

  /// Calculate BMR contribution during workout
  static double _calculateBMRContribution(
    double weight,
    int age,
    String gender,
    int durationMinutes,
  ) {
    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr =
          (10 * weight) +
          (6.25 * 170) -
          (5 * age) +
          5; // Assuming average height of 170cm
    } else {
      bmr =
          (10 * weight) +
          (6.25 * 160) -
          (5 * age) -
          161; // Assuming average height of 160cm
    }

    // Calculate calories burnt during workout time
    final durationHours = durationMinutes / 60.0;
    return bmr * durationHours * 0.1; // 10% of BMR during workout
  }

  /// Calculate estimated calories when user data is not available
  static double _calculateEstimatedCalories(
    List<Map<String, dynamic>> exercises,
    int totalDurationMinutes,
  ) {
    double totalCalories = 0.0;
    const double estimatedWeight = 70.0; // Default weight
    const double defaultMET = 4.0; // Average MET for strength training

    for (final exercise in exercises) {
      final sets = exercise['sets'] as List<dynamic>;
      final completedSets =
          sets.where((set) => set['isChecked'] == true).length;

      if (completedSets > 0) {
        // Simple estimation: 5 calories per set for strength training
        final setCalories = completedSets * 5.0;
        totalCalories += setCalories;
      }
    }

    // Add time-based estimation
    final durationHours = totalDurationMinutes / 60.0;
    final timeCalories = defaultMET * estimatedWeight * durationHours * 0.3;
    totalCalories += timeCalories;

    // Ensure we always return a reasonable value
    if (totalCalories <= 0) {
      return 50.0; // Minimum reasonable calories for any workout
    }
    return totalCalories;
  }

  /// Format calories for display
  static String formatCalories(double calories) {
    if (calories < 100) {
      return '${calories.round()} cal';
    } else {
      return '${(calories / 100).round() * 100} cal';
    }
  }
}
