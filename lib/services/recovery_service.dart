import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gymfit/models/recovery.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/services/recommended_training_service.dart';

class RecoveryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notification system for recovery updates
  static final List<VoidCallback> _recoveryUpdateListeners = [];

  // Add a listener for recovery updates
  static void addRecoveryUpdateListener(VoidCallback listener) {
    _recoveryUpdateListeners.add(listener);
  }

  // Remove a listener for recovery updates
  static void removeRecoveryUpdateListener(VoidCallback listener) {
    _recoveryUpdateListeners.remove(listener);
  }

  // Notify all listeners that recovery data has been updated
  static void _notifyRecoveryUpdate() {
    for (final listener in _recoveryUpdateListeners) {
      try {
        listener();
      } catch (e) {
        if (kDebugMode) {
          print('Error in recovery update listener: $e');
        }
      }
    }
  }

  /// Get user's recovery data
  static Future<RecoveryData?> getUserRecoveryData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recovery')
          .doc('data')
          .get();

      if (doc.exists && doc.data() != null) {
        return RecoveryData.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recovery data: $e');
      }
      return null;
    }
  }

  /// Save user's recovery data
  static Future<void> saveRecoveryData(RecoveryData recoveryData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recovery')
          .doc('data')
          .set(recoveryData.toMap());
      
      _notifyRecoveryUpdate();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving recovery data: $e');
      }
    }
  }

  /// Calculate and update recovery data based on workout history
  static Future<RecoveryData> calculateRecoveryData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get existing recovery data for custom baselines
      final existingData = await getUserRecoveryData();
      
      // Get user's body weight
      final bodyWeight = await _getUserBodyWeight();
      
      // Get user's workout history
      final workouts = await WorkoutService.getUserWorkouts();
      
      // Group workouts by muscle groups and calculate recovery
      final Map<String, MuscleGroup> muscleGroupMap = {};
      final Map<String, String> lastExerciseType = {}; // Track last exercise type per muscle group
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      // Initialize muscle groups
      final muscleGroups = [
        'Chest', 'Biceps', 'Triceps', 'Shoulders', 'Back',
        'Quadriceps', 'Hamstrings', 'Glutes', 'Calves', 
        'Forearms', 'Neck', 'Core'
      ];

      for (final muscleGroup in muscleGroups) {
        muscleGroupMap[muscleGroup] = MuscleGroup(
          name: muscleGroup,
          recoveryPercentage: 100.0,
          lastTrained: now.subtract(const Duration(days: 30)), // Default to 30 days ago
          trainingLoad: 0.0,
          fatigueScore: 0.0,
        );
        lastExerciseType[muscleGroup] = 'default'; // Default exercise type
      }

      // Process workouts from the last week
      final recentWorkouts = workouts.where((w) => w.date.isAfter(oneWeekAgo)).toList();
      
      for (final workout in recentWorkouts) {
        for (final exercise in workout.exercises) {
          final exerciseMuscleGroups = RecoveryCalculator.getMuscleGroupsFromExercise(exercise.title);
          
          for (final muscleGroup in exerciseMuscleGroups) {
            if (muscleGroupMap.containsKey(muscleGroup)) {
              final currentGroup = muscleGroupMap[muscleGroup]!;
              
              // Calculate training load for this exercise
              final completedSets = exercise.sets.where((set) => set.isCompleted).length;
              if (completedSets > 0) {
                final averageWeight = exercise.sets
                    .where((set) => set.isCompleted)
                    .map((set) => set.weight)
                    .reduce((a, b) => a + b) / completedSets;
                
                final averageReps = exercise.sets
                    .where((set) => set.isCompleted)
                    .map((set) => set.reps)
                    .reduce((a, b) => a + b) / completedSets;

                // Get 1RM for this exercise to calculate intensity-adjusted load
                final oneRM = await getUser1RMForExercise(exercise.title);
                
                final baseExerciseLoad = RecoveryCalculator.calculateTrainingLoad(
                  sets: completedSets,
                  averageWeight: averageWeight,
                  averageReps: averageReps.toInt(),
                );

                final intensityAdjustedLoad = RecoveryCalculator.calculateIntensityAdjustedLoad(
                  sets: completedSets,
                  averageWeight: averageWeight,
                  averageReps: averageReps.toInt(),
                  oneRM: oneRM,
                );

                // Update muscle group data
                final newTrainingLoad = currentGroup.trainingLoad + baseExerciseLoad;
                final newIntensityAdjustedLoad = currentGroup.trainingLoad + intensityAdjustedLoad;
                final newLastTrained = workout.date.isAfter(currentGroup.lastTrained) 
                    ? workout.date 
                    : currentGroup.lastTrained;

                // Update last exercise type for this muscle group
                if (workout.date.isAfter(currentGroup.lastTrained) || 
                    workout.date.isAtSameMomentAs(currentGroup.lastTrained)) {
                  lastExerciseType[muscleGroup] = exercise.title;
                }

                muscleGroupMap[muscleGroup] = MuscleGroup(
                  name: muscleGroup,
                  recoveryPercentage: currentGroup.recoveryPercentage,
                  lastTrained: newLastTrained,
                  trainingLoad: newTrainingLoad,
                  fatigueScore: currentGroup.fatigueScore,
                  intensityAdjustedLoad: newIntensityAdjustedLoad,
                );
              }
            }
          }
        }
      }

      // Calculate recovery percentages and fatigue scores
      for (final muscleGroup in muscleGroupMap.keys) {
        final group = muscleGroupMap[muscleGroup]!;
        final hoursSinceLastSession = now.difference(group.lastTrained).inHours.toDouble();
        
        // Calculate fatigue score based on weekly volume
        final weeklyVolumes = recentWorkouts
            .where((w) => w.exercises.any((e) => 
                RecoveryCalculator.getMuscleGroupsFromExercise(e.title).contains(muscleGroup)))
            .map((w) => w.exercises
                .where((e) => RecoveryCalculator.getMuscleGroupsFromExercise(e.title).contains(muscleGroup))
                .fold(0.0, (total, e) {
                  final completedSets = e.sets.where((set) => set.isCompleted).length;
                  if (completedSets > 0) {
                    final avgWeight = e.sets
                        .where((set) => set.isCompleted)
                        .map((set) => set.weight)
                        .reduce((a, b) => a + b) / completedSets;
                    final avgReps = e.sets
                        .where((set) => set.isCompleted)
                        .map((set) => set.reps)
                        .reduce((a, b) => a + b) / completedSets;
                    return total + (completedSets * avgWeight * avgReps.toInt());
                  }
                  return total;
                }))
            .toList();

        final fatigueScore = RecoveryCalculator.calculateFatigueScore(
          weeklyVolumes: weeklyVolumes,
          currentVolume: group.trainingLoad,
          muscleGroup: muscleGroup,
          customBaselines: existingData?.customBaselines,
          bodyWeight: bodyWeight,
        );

        final recoveryPercentage = RecoveryCalculator.calculateRecovery(
          trainingLoad: group.trainingLoad,
          hoursSinceLastSession: hoursSinceLastSession.toInt(),
          fatigueScore: fatigueScore,
          muscleGroup: muscleGroup,
          exerciseType: lastExerciseType[muscleGroup] ?? 'default',
          intensityAdjustedLoad: group.intensityAdjustedLoad,
          currentRecovery: hoursSinceLastSession == 0 ? group.recoveryPercentage : null,
        );

        muscleGroupMap[muscleGroup] = MuscleGroup(
          name: muscleGroup,
          recoveryPercentage: recoveryPercentage,
          lastTrained: group.lastTrained,
          trainingLoad: group.trainingLoad,
          fatigueScore: fatigueScore,
        );
      }

      final recoveryData = RecoveryData(
        muscleGroups: muscleGroupMap.values.toList(),
        lastUpdated: now,
        customBaselines: existingData?.customBaselines ?? {},
        bodyWeight: bodyWeight,
      );

      // Save the calculated data
      await saveRecoveryData(recoveryData);
      
      return recoveryData;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating recovery data: $e');
      }
      rethrow;
    }
  }

  /// Get recovery data, calculating if necessary
  static Future<RecoveryData> getRecoveryData() async {
    final existingData = await getUserRecoveryData();
    
    // If no data exists or data is older than 1 hour, recalculate
    if (existingData == null || 
        DateTime.now().difference(existingData.lastUpdated).inHours > 1) {
      return await calculateRecoveryData();
    }
    
    return existingData;
  }

  /// Force refresh recovery data
  static Future<RecoveryData> refreshRecoveryData() async {
    return await calculateRecoveryData();
  }

  /// Update custom baseline for a muscle group
  static Future<void> updateCustomBaseline(String muscleGroup, double newBaseline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final existingData = await getUserRecoveryData();
      final updatedBaselines = Map<String, double>.from(existingData?.customBaselines ?? {});
      updatedBaselines[muscleGroup] = newBaseline;

      final updatedData = RecoveryData(
        muscleGroups: existingData?.muscleGroups ?? [],
        lastUpdated: DateTime.now(),
        customBaselines: updatedBaselines,
        bodyWeight: existingData?.bodyWeight,
      );

      await saveRecoveryData(updatedData);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating custom baseline: $e');
      }
    }
  }

  /// Remove custom baseline for a muscle group (reset to default)
  static Future<void> removeCustomBaseline(String muscleGroup) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final existingData = await getUserRecoveryData();
      final updatedBaselines = Map<String, double>.from(existingData?.customBaselines ?? {});
      updatedBaselines.remove(muscleGroup);

      final updatedData = RecoveryData(
        muscleGroups: existingData?.muscleGroups ?? [],
        lastUpdated: DateTime.now(),
        customBaselines: updatedBaselines,
        bodyWeight: existingData?.bodyWeight,
      );

      await saveRecoveryData(updatedData);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing custom baseline: $e');
      }
    }
  }

  /// Get user's body weight from profile data
  static Future<double?> _getUserBodyWeight() async {
    try {
      final userData = await RecommendedTrainingService.getUserBodyData();
      final height = userData['height']?.toDouble();
      final bmi = userData['bmi']?.toDouble();
      
      if (height != null && bmi != null) {
        // Calculate weight from BMI: weight = BMI * (height/100)^2
        return bmi * (height / 100) * (height / 100);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user body weight: $e');
      }
      return null;
    }
  }

  /// Get user's 1RM for a specific exercise
  static Future<double?> getUser1RMForExercise(String exerciseName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final workouts = await WorkoutService.getUserWorkouts();
      double? max1RM;

      for (final workout in workouts) {
        for (final exercise in workout.exercises) {
          if (exercise.title.toLowerCase() == exerciseName.toLowerCase()) {
            for (final set in exercise.sets) {
              if (set.isCompleted && set.weight > 0 && set.reps > 0) {
                final estimated1RM = RecoveryCalculator.calculate1RM(set.weight, set.reps);
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
      if (kDebugMode) {
        print('Error getting 1RM for $exerciseName: $e');
      }
      return null;
    }
  }
} 