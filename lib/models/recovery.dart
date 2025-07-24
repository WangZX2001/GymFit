import 'dart:math';
import 'package:gymfit/utils/one_rm_calculator.dart';

/// Data class for exercise information used in recovery calculations
class ExerciseData {
  final String exerciseType;
  final int sets;
  final double weight;
  final int reps;

  ExerciseData({
    required this.exerciseType,
    required this.sets,
    required this.weight,
    required this.reps,
  });
}

/// Data class for exercise load calculations
class ExerciseLoadData {
  final String exerciseType;
  final double baseLoad;
  final double effectiveLoad;
  final double intensityMultiplier;

  ExerciseLoadData({
    required this.exerciseType,
    required this.baseLoad,
    required this.effectiveLoad,
    required this.intensityMultiplier,
  });
}

class MuscleGroup {
  final String name;
  final double recoveryPercentage;
  final DateTime lastTrained;
  final double trainingLoad;
  final double fatigueScore;
  final double? intensityAdjustedLoad; // New field for 1RM-adjusted load

  MuscleGroup({
    required this.name,
    required this.recoveryPercentage,
    required this.lastTrained,
    required this.trainingLoad,
    required this.fatigueScore,
    this.intensityAdjustedLoad,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'recoveryPercentage': recoveryPercentage,
      'lastTrained': lastTrained.millisecondsSinceEpoch,
      'trainingLoad': trainingLoad,
      'fatigueScore': fatigueScore,
      'intensityAdjustedLoad': intensityAdjustedLoad,
    };
  }

  factory MuscleGroup.fromMap(Map<String, dynamic> map) {
    return MuscleGroup(
      name: map['name'] ?? '',
      recoveryPercentage: (map['recoveryPercentage'] as num?)?.toDouble() ?? 0.0,
      lastTrained: DateTime.fromMillisecondsSinceEpoch(map['lastTrained'] ?? 0),
      trainingLoad: (map['trainingLoad'] as num?)?.toDouble() ?? 0.0,
      fatigueScore: (map['fatigueScore'] as num?)?.toDouble() ?? 0.0,
      intensityAdjustedLoad: (map['intensityAdjustedLoad'] as num?)?.toDouble(),
    );
  }
}

class RecoveryData {
  final List<MuscleGroup> muscleGroups;
  final DateTime lastUpdated;
  final Map<String, double> customBaselines;
  final double? bodyWeight;
  final Map<String, String> recentExerciseTypes; // NEW: most recent exercise type per muscle group

  RecoveryData({
    required this.muscleGroups,
    required this.lastUpdated,
    this.customBaselines = const {},
    this.bodyWeight,
    this.recentExerciseTypes = const {}, // NEW
  });

  Map<String, dynamic> toMap() {
    return {
      'muscleGroups': muscleGroups.map((mg) => mg.toMap()).toList(),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'customBaselines': customBaselines,
      'bodyWeight': bodyWeight,
      'recentExerciseTypes': recentExerciseTypes, // NEW
    };
  }

  factory RecoveryData.fromMap(Map<String, dynamic> map) {
    final customBaselinesMap = map['customBaselines'] as Map<String, dynamic>? ?? {};
    final customBaselines = customBaselinesMap.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
    final recentExerciseTypesMap = map['recentExerciseTypes'] as Map<String, dynamic>? ?? {};
    final recentExerciseTypes = recentExerciseTypesMap.map(
      (key, value) => MapEntry(key, value as String),
    );
    return RecoveryData(
      muscleGroups: (map['muscleGroups'] as List<dynamic>?)
              ?.map((mg) => MuscleGroup.fromMap(mg as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
      customBaselines: customBaselines,
      bodyWeight: (map['bodyWeight'] as num?)?.toDouble(),
      recentExerciseTypes: recentExerciseTypes, // NEW
    );
  }
}

class RecoveryCalculator {
  // Muscle-specific recovery rates based on real-world recovery times
  // Higher values = faster recovery, lower values = slower recovery
  // Recovery times: 24-36h (fast), 48-72h (moderate), 72-96h (slow)
  static const Map<String, double> muscleRecoveryRates = {
    'Forearms': 0.35,     // 24-36 hrs: High blood flow, used daily
    'Calves': 0.32,       // 24-36 hrs: Endurance-focused, fast recovery
    'Core': 0.30,         // 24-48 hrs: Recovers fast but sensitive to fatigue
    'Neck': 0.28,         // 24-48 hrs: Usually trained lightly
    'Biceps': 0.25,       // 48-72 hrs: Small muscle, fast recovery
    'Triceps': 0.23,      // 48-72 hrs: Slightly slower than biceps
    'Shoulders': 0.22,    // 48-72 hrs: Moderate size, high daily use
    'Chest': 0.18,        // 48-96 hrs: Large, compound-focused
    'Back': 0.16,         // 72-96 hrs: Large area, CNS fatigue from pulls
    'Quadriceps': 0.15,   // 72-96 hrs: Large muscles, high fatigue
    'Hamstrings': 0.14,   // 72-96 hrs: Slow twitch, risk of DOMS
    'Glutes': 0.13,       // 72-96 hrs: Strong but slow recovery
    'Other': 0.20,        // Default recovery rate
  };
  
  // Default muscle-specific baseline volumes (weekly)
  // These represent realistic weekly training volumes for intermediate lifters
  static const Map<String, double> defaultMuscleBaselines = {
    'Chest': 12000.0,      // 3-4 exercises, 3-4 sets each, moderate weights
    'Back': 15000.0,       // 4-5 exercises, 3-4 sets each (rows, pulldowns, etc.)
    'Quadriceps': 20000.0, // Squats, leg press, lunges, etc.
    'Hamstrings': 12000.0, // Deadlifts, leg curls, etc.
    'Shoulders': 8000.0,   // Presses, raises, etc.
    'Biceps': 6000.0,      // Curls, hammer curls, etc.
    'Triceps': 6000.0,     // Pushdowns, extensions, etc.
    'Calves': 3000.0,      // Standing/seated calf raises
    'Core': 4000.0,        // Planks, crunches, etc.
    'Other': 8000.0,       // Default for unrecognized exercises
  };

  static const Map<String, double> muscleGroupWorkoutLoads = {
    'Chest': 3000.0,      // 2,500-3,500 kg range, using upper bound
    'Back': 4000.0,       // 3,000-4,000 kg range, using upper bound
    'Quadriceps': 5000.0, // 3,500-5,000 kg range, using upper bound
    'Hamstrings': 2800.0, // 1,600-2,800 kg range, using upper bound
    'Shoulders': 1200.0,  // 800-1,200 kg range, using upper bound
    'Biceps': 540.0,      // 360-540 kg range, using upper bound
    'Triceps': 720.0,     // 540-720 kg range, using upper bound
    'Calves': 2700.0,     // 1,800-2,700 kg range, using upper bound
    'Core': 1200.0,       // 600-1,200 kg range, using upper bound
    'Glutes': 4000.0,     // 2,400-4,000 kg range, using upper bound
    'Forearms': 4000.0,   // Keeping existing value (not in your table)
    'Neck': 2000.0,       // Keeping existing value (not in your table)
    'Other': 2500.0,      // Default for unrecognized exercises
  };

  /// Helper to get workout load for a muscle group, using userWorkoutLoad if available, otherwise default
  static double getWorkoutLoad(String muscleGroup, {double? userWorkoutLoad}) {
    final defaultWorkoutLoad = muscleGroupWorkoutLoads[muscleGroup] ?? 2500.0;
    return (userWorkoutLoad != null && userWorkoutLoad > 0) ? userWorkoutLoad : defaultWorkoutLoad;
  }

  /// Calculate recovery percentage using exponential decay function with realistic post-workout recovery
  /// recovery(t) = initial_recovery + (100 - initial_recovery) × (1 - e^(-k × t))
  ///
  /// k = muscleRate / log(trainingLoad + 1)
  /// (No exercise type multiplier is used in k)
  static double calculateRecovery({
    required double trainingLoad,
    required int hoursSinceLastSession,
    required double fatigueScore,
    required String muscleGroup,
    required String exerciseType,
    double? intensityAdjustedLoad,
    double? currentRecovery, // Pass in the current recovery before the new workout
    double? userWorkoutLoad, // Pass in the user's workout load for this muscle group if available
  }) {
    // Use intensity-adjusted load if available, otherwise use base training load
    final effectiveLoad = intensityAdjustedLoad ?? trainingLoad;
    final workoutLoad = getWorkoutLoad(muscleGroup, userWorkoutLoad: userWorkoutLoad);
    // Calculate initial post-workout recovery based on effective training load
    final initialRecovery = calculateInitialRecovery(effectiveLoad, exerciseType, workoutLoad: workoutLoad);

    // Curve-based reduction if muscle is not at 100% and this is a new workout
    if (hoursSinceLastSession <= 0 && currentRecovery != null && currentRecovery < 100) {
      final intensityMultiplier = getExerciseIntensityMultiplier(exerciseType);
      double fatigueScoreCurve = (effectiveLoad / workoutLoad) * (intensityMultiplier / 25.0);
      fatigueScoreCurve = fatigueScoreCurve.clamp(0.1, 0.7);
      double reduction = currentRecovery * fatigueScoreCurve;
      double reducedRecovery = currentRecovery - reduction;
      final minRecovery = getMinimumRecoveryThreshold(exerciseType);
      return reducedRecovery.clamp(minRecovery, 100.0);
    }
    
    if (hoursSinceLastSession <= 0) return initialRecovery;

    // Get muscle-specific base recovery rate
    final muscleRate = muscleRecoveryRates[muscleGroup] ?? muscleRecoveryRates['Other']!;
    
    // Dynamic k value based only on muscle group and effective training load
    // k = muscleRate / log(effectiveLoad + 1)
    double k = muscleRate / log(effectiveLoad + 1);

    // Fatigue factor - slows recovery if overtraining
    double fatigueFactor = 1.0;
    if (fatigueScore > 1.5) {  // Fatigue threshold is always 1.5 regardless of muscle group
      fatigueFactor = 0.8;
    }

    // Apply fatigue factor to k
    double adjustedK = k * fatigueFactor;

    // Exponential recovery curve from initial recovery to 100%
    // recovery = initial + (100 - initial) × (1 - e^(-k × t))
    double recovery = initialRecovery + (100 - initialRecovery) * (1 - exp(-adjustedK * hoursSinceLastSession));
    
    return recovery.clamp(0.0, 100.0);
  }

  /// Calculate recovery for multiple exercises targeting the same muscle group
  /// Uses weighted average approach (Option A) for fatigue calculation
  /// FIXED: Correct order of operations - time-based recovery first, then new workout impact
  static double calculateRecoveryForMultipleExercises({
    required List<ExerciseData> exercises,
    required int hoursSinceLastSession,
    required double fatigueScore,
    required String muscleGroup,
    double? currentRecovery,
    double? userWorkoutLoad,
  }) {
    
    // Handle time-based recovery when no new exercises are added
    if (exercises.isEmpty) {
      if (hoursSinceLastSession <= 0) {
        return currentRecovery ?? 100.0;
      }
      
      // Apply time-based recovery only
      if (currentRecovery != null && currentRecovery < 100) {
        final muscleRate = muscleRecoveryRates[muscleGroup] ?? muscleRecoveryRates['Other']!;
        final workoutLoad = getWorkoutLoad(muscleGroup, userWorkoutLoad: userWorkoutLoad);
        
        // k = muscleRate / log(workoutLoad + 1) (no exercise multiplier)
        double k = muscleRate / log(workoutLoad + 1);
        
        // Apply fatigue factor
        double fatigueFactor = 1.0;
        if (fatigueScore > 1.5) {
          fatigueFactor = 0.8;
        }
        
        double adjustedK = k * fatigueFactor;
        
        // Apply time-based recovery to current recovery
        double timeRecoveredValue = currentRecovery + (100 - currentRecovery) * (1 - exp(-adjustedK * hoursSinceLastSession));
        final result = timeRecoveredValue.clamp(0.0, 100.0);
        return result;
      } else {
        return currentRecovery ?? 100.0;
      }
    }

    final workoutLoad = getWorkoutLoad(muscleGroup, userWorkoutLoad: userWorkoutLoad);
    
    // Step 1: Calculate effective load for each exercise
    final exerciseLoads = <ExerciseLoadData>[];
    double totalBaseLoad = 0.0;
    
    for (final exercise in exercises) {
      final baseLoad = exercise.sets * exercise.weight * exercise.reps;
      final intensityMultiplier = getExerciseIntensityMultiplier(exercise.exerciseType);
      final effectiveLoad = baseLoad * intensityMultiplier;
      
      exerciseLoads.add(ExerciseLoadData(
        exerciseType: exercise.exerciseType,
        baseLoad: baseLoad,
        effectiveLoad: effectiveLoad,
        intensityMultiplier: intensityMultiplier,
      ));
      
      totalBaseLoad += baseLoad;
    }
    
    // Step 2: Calculate weighted average fatigue score curve (Option A)
    double weightedFatigueScoreCurve = 0.0;
    for (final exerciseData in exerciseLoads) {
      final weight = exerciseData.baseLoad / totalBaseLoad;
      final individualFatigueCurve = (exerciseData.effectiveLoad / workoutLoad) * (exerciseData.intensityMultiplier / 25.0);
      weightedFatigueScoreCurve += weight * individualFatigueCurve;
    }
    
    // Step 3: Calculate initial recovery using the most intense exercise type
    final mostIntenseExercise = exerciseLoads.reduce((a, b) => a.intensityMultiplier > b.intensityMultiplier ? a : b);
    final initialRecovery = calculateInitialRecovery(totalBaseLoad, mostIntenseExercise.exerciseType, workoutLoad: workoutLoad);
    
    // Step 4: Handle different scenarios with CORRECT ORDER
    if (hoursSinceLastSession <= 0) {
      // New workout (no time passed)
      
      // FIXED LOGIC: Only use reduction recovery if this is actually a subsequent workout
      // in the same session, not just combining exercises from the same session
      if (currentRecovery != null && currentRecovery < 100) {
        // Check if this is a subsequent workout by comparing with the recovery that would
        // result from just these exercises (without considering current recovery)
        final exercisesOnlyRecovery = calculateInitialRecovery(totalBaseLoad, mostIntenseExercise.exerciseType, workoutLoad: workoutLoad);
        
        if (currentRecovery < exercisesOnlyRecovery) {
          // Reduction recovery for subsequent workout
          weightedFatigueScoreCurve = weightedFatigueScoreCurve.clamp(0.1, 0.7);
          double reduction = currentRecovery * weightedFatigueScoreCurve;
          double reducedRecovery = currentRecovery - reduction;
          
          // Option A: For subsequent workouts, allow going below minRecovery, but not below 5%
          final result = reducedRecovery < 5.0 ? 5.0 : reducedRecovery;
          return result.clamp(0.0, 100.0);
        } else {
          // Same session, just combining exercises - use the recovery for these exercises
          return exercisesOnlyRecovery;
        }
      } else {
        // First workout for this muscle group
        // Enforce minRecovery only on initial drop
        return initialRecovery;
      }
    } else {
      // Time has passed since last workout
      if (currentRecovery != null && currentRecovery < 100) {
        // FIXED ORDER: Step 1 - Apply time-based recovery first
        final muscleRate = muscleRecoveryRates[muscleGroup] ?? muscleRecoveryRates['Other']!;
        
        // Use weighted average exercise multiplier
        double weightedExerciseMultiplier = 0.0;
        for (final exerciseData in exerciseLoads) {
          final weight = exerciseData.baseLoad / totalBaseLoad;
          final exerciseMultiplier = getExerciseTypeMultiplier(exerciseData.exerciseType);
          weightedExerciseMultiplier += weight * exerciseMultiplier;
        }
        
        // k = muscleRate / log(totalBaseLoad + 1) (no exercise multiplier)
        double k = muscleRate / log(totalBaseLoad + 1);
        
        // Apply fatigue factor
        double fatigueFactor = 1.0;
        if (fatigueScore > 1.5) {
          fatigueFactor = 0.8;
        }
        
        double adjustedK = k * fatigueFactor;
        
        // Apply time-based recovery to current recovery
        double timeRecoveredValue = currentRecovery + (100 - currentRecovery) * (1 - exp(-adjustedK * hoursSinceLastSession));
        
        // Step 2 - Apply reduction from new workout
        weightedFatigueScoreCurve = weightedFatigueScoreCurve.clamp(0.1, 0.7);
        double reduction = timeRecoveredValue * weightedFatigueScoreCurve;
        double finalRecovery = timeRecoveredValue - reduction;
        
        // CRITICAL FIX: Ensure recovery never increases from a new workout
        finalRecovery = finalRecovery.clamp(0.0, timeRecoveredValue);
        
        // Apply minimum recovery threshold
        final minRecovery = exerciseLoads.map((e) => getMinimumRecoveryThreshold(e.exerciseType)).reduce((a, b) => a < b ? a : b);
        final result = finalRecovery.clamp(minRecovery, 100.0);
        return result;
      } else {
        // No previous recovery data, use initial recovery with time-based recovery
        final muscleRate = muscleRecoveryRates[muscleGroup] ?? muscleRecoveryRates['Other']!;
        
        // Use weighted average exercise multiplier
        double weightedExerciseMultiplier = 0.0;
        for (final exerciseData in exerciseLoads) {
          final weight = exerciseData.baseLoad / totalBaseLoad;
          final exerciseMultiplier = getExerciseTypeMultiplier(exerciseData.exerciseType);
          weightedExerciseMultiplier += weight * exerciseMultiplier;
        }
        
        // k = muscleRate / log(totalBaseLoad + 1) (no exercise multiplier)
        double k = muscleRate / log(totalBaseLoad + 1);
        
        // Apply fatigue factor
        double fatigueFactor = 1.0;
        if (fatigueScore > 1.5) {
          fatigueFactor = 0.8;
        }
        
        double adjustedK = k * fatigueFactor;
        
        // Exponential recovery curve from initial recovery
        double recovery = initialRecovery + (100 - initialRecovery) * (1 - exp(-adjustedK * hoursSinceLastSession));
        
        return recovery.clamp(0.0, 100.0);
      }
    }
  }

  /// Calculate recovery for a complete workout session with multiple exercises
  /// Groups exercises by muscle group and calculates recovery for each group
  static Map<String, double> calculateWorkoutRecovery({
    required List<ExerciseData> allExercises,
    required int hoursSinceLastSession,
    required Map<String, double> currentRecoveries,
    required Map<String, double> fatigueScores,
    Map<String, double>? userWorkoutLoads,
  }) {
    final results = <String, double>{};
    
    // Group exercises by muscle group
    final exercisesByMuscleGroup = <String, List<ExerciseData>>{};
    
    for (final exercise in allExercises) {
      final muscleGroups = getMuscleGroupsFromExercise(exercise.exerciseType);
      for (final muscleGroup in muscleGroups) {
        exercisesByMuscleGroup.putIfAbsent(muscleGroup, () => []).add(exercise);
      }
    }
    
    // Calculate recovery for each muscle group
    for (final entry in exercisesByMuscleGroup.entries) {
      final muscleGroup = entry.key;
      final exercises = entry.value;
      
      final currentRecovery = currentRecoveries[muscleGroup];
      final fatigueScore = fatigueScores[muscleGroup] ?? 1.0;
      final userWorkoutLoad = userWorkoutLoads?[muscleGroup];
      
      final recovery = calculateRecoveryForMultipleExercises(
        exercises: exercises,
        hoursSinceLastSession: hoursSinceLastSession,
        fatigueScore: fatigueScore,
        muscleGroup: muscleGroup,
        currentRecovery: currentRecovery,
        userWorkoutLoad: userWorkoutLoad,
      );
      
      results[muscleGroup] = recovery;
    }
    
    return results;
  }

  /// Calculate initial post-workout recovery percentage based on training load and exercise type
  /// Higher loads = lower initial recovery, but never 0% unless extreme
  static double calculateInitialRecovery(double trainingLoad, String exerciseType, {required double workoutLoad}) {
    // Get exercise intensity multiplier (higher = more fatiguing)
    final intensityMultiplier = getExerciseIntensityMultiplier(exerciseType);
    // Calculate fatigue impact based on load and intensity, normalized by workout load
    final fatigueImpact = (trainingLoad / workoutLoad) * intensityMultiplier;
    // Calculate initial recovery (higher fatigue = lower recovery)
    double initialRecovery = 100 - fatigueImpact;
    // Apply minimum recovery thresholds based on exercise type
    final minRecovery = getMinimumRecoveryThreshold(exerciseType);
    // Ensure recovery doesn't go below minimum threshold
    return initialRecovery.clamp(minRecovery, 100.0);
  }

  /// Get exercise intensity multiplier for initial recovery calculation
  /// Higher values = more fatiguing = lower initial recovery
  static double getExerciseIntensityMultiplier(String exerciseType) {
    final lowerName = exerciseType.toLowerCase();
    
    // High-intensity compound movements (most fatiguing)
    if (lowerName.contains('deadlift') || 
        lowerName.contains('squat') || 
        lowerName.contains('clean') ||
        lowerName.contains('snatch')) {
      return 25.0;  // Very high fatigue impact
    }
    
    // Major compound movements (high fatigue)
    if (lowerName.contains('bench') || 
        lowerName.contains('press') || 
        lowerName.contains('row') ||
        lowerName.contains('pulldown') ||
        lowerName.contains('pullup') ||
        lowerName.contains('chinup')) {
      return 20.0;  // High fatigue impact
    }
    
    // Isolation exercises (moderate fatigue)
    if (lowerName.contains('curl') || 
        lowerName.contains('extension') || 
        lowerName.contains('fly') ||
        lowerName.contains('raise')) {
      return 15.0;  // Moderate fatigue impact
    }
    
    // Low-intensity exercises (minimal fatigue)
    if (lowerName.contains('crunch') || 
        lowerName.contains('plank') ||
        lowerName.contains('stretch') ||
        lowerName.contains('mobility')) {
      return 8.0;   // Low fatigue impact
    }
    
    // Default intensity
    return 18.0;  // Moderate-high fatigue impact
  }

  /// Get minimum recovery threshold based on exercise type
  /// Prevents recovery from going too low even with high loads
  static double getMinimumRecoveryThreshold(String exerciseType) {
    final lowerName = exerciseType.toLowerCase();
    
    // High-intensity exercises can drop to very low recovery
    if (lowerName.contains('deadlift') || 
        lowerName.contains('squat') || 
        lowerName.contains('clean') ||
        lowerName.contains('snatch')) {
      return 5.0;   // Can drop to 5% (extreme fatigue)
    }
    
    // Major compound movements
    if (lowerName.contains('bench') || 
        lowerName.contains('press') || 
        lowerName.contains('row') ||
        lowerName.contains('pulldown')) {
      return 10.0;  // Can drop to 10% (high fatigue)
    }
    
    // Isolation exercises
    if (lowerName.contains('curl') || 
        lowerName.contains('extension') || 
        lowerName.contains('fly') ||
        lowerName.contains('raise')) {
      return 20.0;  // Can drop to 20% (moderate fatigue)
    }
    
    // Low-intensity exercises
    if (lowerName.contains('crunch') || 
        lowerName.contains('plank') ||
        lowerName.contains('stretch')) {
      return 50.0;  // Can drop to 50% (minimal fatigue)
    }
    
    // Default minimum
    return 15.0;  // Can drop to 15% (default)
  }

  /// Calculate training load for a muscle group
  static double calculateTrainingLoad({
    required int sets,
    required double averageWeight,
    required int averageReps,
  }) {
    // Simple load calculation: sets × weight × reps
    return sets * averageWeight * averageReps;
  }

  /// Calculate 1RM using Brzycki formula
  static double calculate1RM(double weight, int reps) {
    return OneRMCalculator.brzycki(weight, reps);
  }

  /// Calculate training intensity relative to 1RM
  static double calculateTrainingIntensity({
    required double weight,
    required int reps,
    required double? oneRM,
  }) {
    if (oneRM == null || oneRM <= 0) {
      // If no 1RM data, estimate intensity based on reps
      return _estimateIntensityFromReps(reps);
    }
    
    // Calculate actual intensity as percentage of 1RM
    return (weight / oneRM) * 100;
  }

  /// Estimate training intensity based on rep ranges when 1RM is not available
  static double _estimateIntensityFromReps(int reps) {
    if (reps <= 3) return 90.0;      // Very heavy (90%+ of 1RM)
    if (reps <= 5) return 85.0;      // Heavy (85% of 1RM)
    if (reps <= 8) return 75.0;      // Moderate-heavy (75% of 1RM)
    if (reps <= 12) return 65.0;     // Moderate (65% of 1RM)
    if (reps <= 15) return 55.0;     // Light-moderate (55% of 1RM)
    return 45.0;                     // Light (45% of 1RM)
  }

  /// Calculate intensity-adjusted training load
  static double calculateIntensityAdjustedLoad({
    required int sets,
    required double averageWeight,
    required int averageReps,
    required double? oneRM,
  }) {
    final baseLoad = sets * averageWeight * averageReps;
    final intensity = calculateTrainingIntensity(
      weight: averageWeight,
      reps: averageReps,
      oneRM: oneRM,
    );
    
    // Adjust load based on intensity - higher intensity = more recovery impact
    final intensityMultiplier = _getIntensityMultiplier(intensity);
    
    return baseLoad * intensityMultiplier;
  }

  /// Get intensity multiplier for recovery calculation
  /// Higher intensity = higher multiplier = more recovery impact
  static double _getIntensityMultiplier(double intensity) {
    if (intensity >= 90) return 1.5;      // Very heavy (90%+ 1RM)
    if (intensity >= 85) return 1.3;      // Heavy (85-89% 1RM)
    if (intensity >= 75) return 1.1;      // Moderate-heavy (75-84% 1RM)
    if (intensity >= 65) return 1.0;      // Moderate (65-74% 1RM)
    if (intensity >= 55) return 0.9;      // Light-moderate (55-64% 1RM)
    return 0.8;                           // Light (<55% 1RM)
  }

  /// Calculate fatigue score based on cumulative weekly volume
  static double calculateFatigueScore({
    required List<double> weeklyVolumes,
    required double currentVolume,
    required String muscleGroup,
    Map<String, double>? customBaselines,
    double? bodyWeight,
  }) {
    // Calculate cumulative volume over the week
    double totalVolume = weeklyVolumes.fold(0.0, (sum, volume) => sum + volume) + currentVolume;
    
    // Get muscle-specific baseline (weight-adjusted if body weight available)
    double baseline;
    if (bodyWeight != null && bodyWeight > 0) {
      baseline = getWeightAdjustedBaseline(muscleGroup, bodyWeight, customBaselines: customBaselines);
    } else {
      baseline = customBaselines?[muscleGroup] ?? 
                 defaultMuscleBaselines[muscleGroup] ?? 
                 defaultMuscleBaselines['Other']!;
    }
    
    // Normalize by baseline volume
    return totalVolume / baseline;
  }

  /// Get muscle groups from exercise names
  static List<String> getMuscleGroupsFromExercise(String exerciseName, {String? mainMuscle}) {
    // If mainMuscle is provided, use it for grouping
    if (mainMuscle != null && mainMuscle.trim().isNotEmpty) {
      final normalized = mainMuscle.trim().toLowerCase();
      // Map common mainMuscle values to recovery muscle groups
      if (normalized.contains('chest')) return ['Chest'];
      if (normalized.contains('bicep')) return ['Biceps'];
      if (normalized.contains('tricep')) return ['Triceps'];
      if (normalized.contains('shoulder') || normalized.contains('deltoid')) return ['Shoulders'];
      if (normalized.contains('back') || normalized.contains('lat') || normalized.contains('trap') || normalized.contains('rhomboid')) return ['Back'];
      if (normalized.contains('quad')) return ['Quadriceps'];
      if (normalized.contains('hamstring')) return ['Hamstrings'];
      if (normalized.contains('glute')) return ['Glutes'];
      if (normalized.contains('calf')) return ['Calves'];
      if (normalized.contains('forearm')) return ['Forearms'];
      if (normalized.contains('neck')) return ['Neck'];
      if (normalized.contains('core') || normalized.contains('abs')) return ['Core'];
    }
    final lowerName = exerciseName.toLowerCase();
    
    // Compound exercises that affect multiple muscle groups
    if (lowerName.contains('bench')) {
      return ['Chest', 'Triceps']; // Bench press affects chest and triceps
    }
    // Shoulders and raises (should come before 'lat' to avoid matching 'lateral')
    else if (lowerName.contains('shoulder') || lowerName.contains('raise')) {
      return ['Shoulders'];
    }
    // Specific lat/back checks
    else if (lowerName.contains('row') || lowerName.contains('pulldown') || lowerName.contains('lat pulldown') || lowerName.contains('lat pullover') || lowerName.contains('lat row')) {
      return ['Back', 'Biceps']; // Rows and pulldowns affect back and biceps
    } else if (lowerName.contains('press') && !lowerName.contains('bench')) {
      return ['Shoulders', 'Triceps']; // Overhead press affects shoulders and triceps
    } else if (lowerName.contains('deadlift')) {
      return ['Back', 'Hamstrings', 'Glutes']; // Deadlift affects multiple muscle groups
    } else if (lowerName.contains('squat')) {
      return ['Quadriceps', 'Glutes']; // Squat affects quads and glutes
    }
    
    // Single muscle group exercises
    if (lowerName.contains('chest') || lowerName.contains('fly')) {
      return ['Chest'];
    } else if (lowerName.contains('curl') || lowerName.contains('bicep')) {
      return ['Biceps'];
    } else if (lowerName.contains('tricep') || lowerName.contains('pushdown') || lowerName.contains('skull')) {
      return ['Triceps'];
    } else if (lowerName.contains('trap')) {
      return ['Back'];
    } else if (lowerName.contains('leg') && !lowerName.contains('deadlift') && !lowerName.contains('squat')) {
      return ['Quadriceps'];
    } else if (lowerName.contains('hamstring')) {
      return ['Hamstrings'];
    } else if (lowerName.contains('glute') || lowerName.contains('hip') || lowerName.contains('bridge')) {
      return ['Glutes'];
    } else if (lowerName.contains('calf') || lowerName.contains('gastro')) {
      return ['Calves'];
    } else if (lowerName.contains('forearm') || lowerName.contains('wrist') || lowerName.contains('grip')) {
      return ['Forearms'];
    } else if (lowerName.contains('neck')) {
      return ['Neck'];
    } else if (lowerName.contains('abs') || lowerName.contains('core') || lowerName.contains('crunch')) {
      return ['Core'];
    } else {
      return ['Other'];
    }
  }

  /// Get recovery status based on percentage
  static String getRecoveryStatus(double recoveryPercentage) {
    if (recoveryPercentage >= 80) {
      return 'Ready';
    } else if (recoveryPercentage >= 60) {
      return 'Moderate';
    } else if (recoveryPercentage >= 40) {
      return 'Needs Rest';
    } else {
      return 'Rest Required';
    }
  }

  /// Get color for recovery status
  static int getRecoveryColor(double recoveryPercentage) {
    if (recoveryPercentage >= 80) {
      return 0xFF4CAF50; // Green
    } else if (recoveryPercentage >= 60) {
      return 0xFFFF9800; // Orange
    } else if (recoveryPercentage >= 40) {
      return 0xFFFF5722; // Red-Orange
    } else {
      return 0xFFF44336; // Red
    }
  }

  /// Get baseline volume for a specific muscle group
  static double getBaselineVolume(String muscleGroup, {Map<String, double>? customBaselines}) {
    return customBaselines?[muscleGroup] ?? 
           defaultMuscleBaselines[muscleGroup] ?? 
           defaultMuscleBaselines['Other']!;
  }

  /// Get exercise type multiplier that affects recovery rate
  /// Lower values = slower recovery, higher values = faster recovery
  static double getExerciseTypeMultiplier(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();
    
    // Compound movements with high systemic stress (slowest recovery)
    if (lowerName.contains('deadlift') || 
        lowerName.contains('squat') || 
        lowerName.contains('clean') ||
        lowerName.contains('snatch')) {
      return 0.7;  // 30% slower recovery (high systemic stress)
    }
    
    // Major compound movements (slower recovery)
    if (lowerName.contains('bench') || 
        lowerName.contains('press') || 
        lowerName.contains('row') ||
        lowerName.contains('pulldown') ||
        lowerName.contains('pullup') ||
        lowerName.contains('chinup')) {
      return 0.85; // 15% slower recovery (compound movements)
    }
    
    // Isolation exercises (normal recovery)
    if (lowerName.contains('curl') || 
        lowerName.contains('extension') || 
        lowerName.contains('fly') ||
        lowerName.contains('raise') ||
        lowerName.contains('crunch') ||
        lowerName.contains('plank')) {
      return 1.0;  // Normal recovery (isolation exercises)
    }
    
    // Eccentric-focused or high-intensity exercises (slower recovery)
    if (lowerName.contains('negative') || 
        lowerName.contains('eccentric') ||
        lowerName.contains('drop') ||
        lowerName.contains('superset')) {
      return 0.8;  // 20% slower recovery (high muscle damage)
    }
    
    // Default multiplier for unrecognized exercises
    return 0.9;  // Slightly slower recovery (default)
  }

  /// Get weight-adjusted baseline volume for a specific muscle group
  static double getWeightAdjustedBaseline(String muscleGroup, double bodyWeight, {Map<String, double>? customBaselines}) {
    // If custom baseline exists, use it (user has overridden)
    if (customBaselines?.containsKey(muscleGroup) == true) {
      return customBaselines![muscleGroup]!;
    }

    // Get default baseline
    final defaultBaseline = defaultMuscleBaselines[muscleGroup] ?? defaultMuscleBaselines['Other']!;
    
    // Weight adjustment factor (based on 70kg as reference weight)
    const double referenceWeight = 70.0; // 70kg reference weight
    final double weightFactor = bodyWeight / referenceWeight;
    
    // Adjust baseline based on body weight
    // Heavier individuals can handle more volume
    return defaultBaseline * weightFactor;
  }

  /// Estimate hours from now until recovery crosses a given threshold (e.g., 80%)
  ///
  /// k = muscleRate / log(workoutLoad + 1)
  /// (No exercise type multiplier is used in k)
  static double? estimateHoursToRecoveryThreshold({
    required double currentRecovery,
    required double fatigueScore,
    required String muscleGroup,
    required double lastTrainedHoursAgo,
    double threshold = 80.0,
    double? userWorkoutLoad,
    String exerciseType = 'Bench Press', // NEW: default to Bench Press for backward compatibility
  }) {
    // If already above threshold, return 0
    if (currentRecovery >= threshold) return 0;
    // Use default workout load for time-based recovery
    final muscleRate = muscleRecoveryRates[muscleGroup] ?? muscleRecoveryRates['Other']!;
    final workoutLoad = getWorkoutLoad(muscleGroup, userWorkoutLoad: userWorkoutLoad);
    // Remove exercise type multiplier from k
    double k = muscleRate / log(workoutLoad + 1);
    double fatigueFactor = 1.0;
    if (fatigueScore > 1.5) fatigueFactor = 0.8;
    double adjustedK = k * fatigueFactor;
    // Solve for t in: recovery = current + (100 - current) * (1 - exp(-k * t))
    // threshold = current + (100 - current) * (1 - exp(-k * t))
    // (threshold - current) / (100 - current) = 1 - exp(-k * t)
    // exp(-k * t) = 1 - (threshold - current) / (100 - current)
    // -k * t = ln(1 - (threshold - current) / (100 - current))
    // t = -ln(1 - (threshold - current) / (100 - current)) / k
    final ratio = (threshold - currentRecovery) / (100 - currentRecovery);
    if (ratio >= 1) return null; // Will never reach threshold
    if (ratio <= 0) return 0;
    final expArg = 1 - ratio;
    if (expArg <= 0) return null;
    final t = -log(expArg) / adjustedK;
    // Subtract hours since last trained, since recovery already started
    final hoursToGo = t - lastTrainedHoursAgo;
    return hoursToGo > 0 ? hoursToGo : 0;
  }
} 