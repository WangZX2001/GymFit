import 'dart:math';

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

  RecoveryData({
    required this.muscleGroups,
    required this.lastUpdated,
    this.customBaselines = const {},
    this.bodyWeight,
  });

  Map<String, dynamic> toMap() {
    return {
      'muscleGroups': muscleGroups.map((mg) => mg.toMap()).toList(),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'customBaselines': customBaselines,
      'bodyWeight': bodyWeight,
    };
  }

  factory RecoveryData.fromMap(Map<String, dynamic> map) {
    final customBaselinesMap = map['customBaselines'] as Map<String, dynamic>? ?? {};
    final customBaselines = customBaselinesMap.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
    
    return RecoveryData(
      muscleGroups: (map['muscleGroups'] as List<dynamic>?)
              ?.map((mg) => MuscleGroup.fromMap(mg as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
      customBaselines: customBaselines,
      bodyWeight: (map['bodyWeight'] as num?)?.toDouble(),
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

  static const Map<String, double> muscleGroupMaxLoads = {
    'Chest': 12000.0,
    'Back': 15000.0,
    'Quadriceps': 20000.0,
    'Hamstrings': 12000.0,
    'Shoulders': 8000.0,
    'Biceps': 6000.0,
    'Triceps': 6000.0,
    'Calves': 3000.0,
    'Core': 4000.0,
    'Forearms': 4000.0,
    'Neck': 2000.0,
    'Glutes': 12000.0,
    'Other': 10000.0,
  };

  /// Calculate recovery percentage using exponential decay function with realistic post-workout recovery
  /// recovery(t) = initial_recovery + (100 - initial_recovery) × (1 - e^(-k × t))
  static double calculateRecovery({
    required double trainingLoad,
    required int hoursSinceLastSession,
    required double fatigueScore,
    required String muscleGroup,
    required String exerciseType,
    double? intensityAdjustedLoad,
    double? currentRecovery, // Pass in the current recovery before the new workout
    double? userMaxLoad, // Pass in the user's max weekly load for this muscle group if available
  }) {
    // Use intensity-adjusted load if available, otherwise use base training load
    final effectiveLoad = intensityAdjustedLoad ?? trainingLoad;
    // Hybrid maxLoad: use userMaxLoad if available, else science-based default
    final defaultMaxLoad = muscleGroupMaxLoads[muscleGroup] ?? 10000.0;
    final maxLoad = (userMaxLoad != null && userMaxLoad > 0) ? userMaxLoad : defaultMaxLoad;
    
    // Calculate initial post-workout recovery based on effective training load
    final initialRecovery = calculateInitialRecovery(effectiveLoad, exerciseType);

    // Curve-based reduction if muscle is not at 100% and this is a new workout
    if (hoursSinceLastSession <= 0 && currentRecovery != null && currentRecovery < 100) {
      final intensityMultiplier = getExerciseIntensityMultiplier(exerciseType);
      double fatigueScoreCurve = (effectiveLoad / maxLoad) * (intensityMultiplier / 25.0);
      fatigueScoreCurve = fatigueScoreCurve.clamp(0.1, 0.7);
      double reduction = currentRecovery * fatigueScoreCurve;
      double reducedRecovery = currentRecovery - reduction;
      final minRecovery = getMinimumRecoveryThreshold(exerciseType);
      return reducedRecovery.clamp(minRecovery, 100.0);
    }
    
    if (hoursSinceLastSession <= 0) return initialRecovery;

    // Get muscle-specific base recovery rate
    final muscleRate = muscleRecoveryRates[muscleGroup] ?? muscleRecoveryRates['Other']!;
    
    // Get exercise type multiplier
    final exerciseMultiplier = getExerciseTypeMultiplier(exerciseType);
    
    // Dynamic k value based on muscle group, exercise type, and effective training load
    // k = (muscle_rate × exercise_multiplier) / log(load + 1)
    double k = (muscleRate * exerciseMultiplier) / log(effectiveLoad + 1);

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

  /// Calculate initial post-workout recovery percentage based on training load and exercise type
  /// Higher loads = lower initial recovery, but never 0% unless extreme
  static double calculateInitialRecovery(double trainingLoad, String exerciseType) {
    // Get exercise intensity multiplier (higher = more fatiguing)
    final intensityMultiplier = getExerciseIntensityMultiplier(exerciseType);
    
    // Calculate fatigue impact based on load and intensity
    // Higher load and intensity = lower initial recovery
    final fatigueImpact = (trainingLoad / 1000) * intensityMultiplier;
    
    // Calculate initial recovery (higher fatigue = lower recovery)
    // Base recovery starts at 100% and decreases with fatigue
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
    if (reps <= 0) return weight;
    if (reps == 1) return weight;
    
    // Brzycki formula: 1RM = weight × (36 / (37 - reps))
    return weight * (36 / (37 - reps));
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
  static List<String> getMuscleGroupsFromExercise(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();
    
    if (lowerName.contains('bench') || lowerName.contains('chest') || lowerName.contains('fly')) {
      return ['Chest'];
    } else if (lowerName.contains('curl') || lowerName.contains('bicep')) {
      return ['Biceps'];
    } else if (lowerName.contains('tricep') || lowerName.contains('pushdown') || lowerName.contains('skull')) {
      return ['Triceps'];
    } else if (lowerName.contains('shoulder') || lowerName.contains('press') || lowerName.contains('raise')) {
      return ['Shoulders'];
    } else if (lowerName.contains('row') || lowerName.contains('pulldown') || lowerName.contains('lat') || lowerName.contains('trap')) {
      return ['Back'];
    } else if (lowerName.contains('squat') || lowerName.contains('leg') || lowerName.contains('press')) {
      return ['Quadriceps'];
    } else if (lowerName.contains('deadlift') || lowerName.contains('hamstring')) {
      return ['Hamstrings'];
    } else if (lowerName.contains('glute') || lowerName.contains('hip') || lowerName.contains('bridge')) {
      return ['Glutes'];
    } else if (lowerName.contains('calf') || lowerName.contains('gastro')) {
      return ['Calves'];
    } else if (lowerName.contains('forearm') || lowerName.contains('wrist') || lowerName.contains('grip')) {
      return ['Forearms'];
    } else if (lowerName.contains('neck') || lowerName.contains('trap')) {
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
} 