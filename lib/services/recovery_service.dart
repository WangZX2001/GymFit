import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gymfit/models/recovery.dart';
import 'package:gymfit/models/workout.dart';
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
        // Use existing recovery data if available, otherwise default to 30 days ago
        MuscleGroup existingMuscleGroup;
        try {
          existingMuscleGroup = existingData?.muscleGroups.firstWhere(
            (mg) => mg.name == muscleGroup,
          ) ?? MuscleGroup(
            name: muscleGroup,
            recoveryPercentage: 100.0,
            lastTrained: now.subtract(const Duration(days: 30)),
            trainingLoad: 0.0,
            fatigueScore: 0.0,
          );
        } catch (e) {
          // If muscle group not found in existing data, create default
          existingMuscleGroup = MuscleGroup(
            name: muscleGroup,
            recoveryPercentage: 100.0,
            lastTrained: now.subtract(const Duration(days: 30)),
            trainingLoad: 0.0,
            fatigueScore: 0.0,
          );
        }
        
        muscleGroupMap[muscleGroup] = MuscleGroup(
          name: muscleGroup,
          recoveryPercentage: existingMuscleGroup.recoveryPercentage,
          lastTrained: existingMuscleGroup.lastTrained,
          trainingLoad: existingMuscleGroup.trainingLoad,
          fatigueScore: existingMuscleGroup.fatigueScore,
        );
        lastExerciseType[muscleGroup] = 'default'; // Default exercise type
        
      }

      // Process workouts from the last week
      final recentWorkouts = workouts.where((w) => w.date.isAfter(oneWeekAgo)).toList();
      
      // Group exercises by muscle group for each workout
      final Map<String, Map<String, List<ExerciseData>>> workoutExercisesByMuscleGroup = {};
      
      for (final workout in recentWorkouts) {
        workoutExercisesByMuscleGroup[workout.id] = {};
        
        for (final exercise in workout.exercises) {
          final exerciseMuscleGroups = RecoveryCalculator.getMuscleGroupsFromExercise(exercise.title, mainMuscle: exercise.mainMuscle);
          
          for (final muscleGroup in exerciseMuscleGroups) {
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

              // Create ExerciseData for multiple exercises calculation
              final exerciseData = ExerciseData(
                exerciseType: exercise.title,
                sets: completedSets,
                weight: averageWeight,
                reps: averageReps.toInt(),
              );
              
              // Add to muscle group exercises for this workout
              workoutExercisesByMuscleGroup[workout.id]!.putIfAbsent(muscleGroup, () => []).add(exerciseData);
            }
          }
        }
      }
      
      // Group workouts into sessions (workouts within 2 hours of each other are same session)
      final List<List<Workout>> workoutSessions = [];
      final sortedWorkouts = List<Workout>.from(recentWorkouts)..sort((a, b) => a.date.compareTo(b.date));
      
      if (sortedWorkouts.isNotEmpty) {
        List<Workout> currentSession = [sortedWorkouts.first];
        
        for (int i = 1; i < sortedWorkouts.length; i++) {
          final workout = sortedWorkouts[i];
          final lastWorkoutInSession = currentSession.last;
          final hoursBetween = workout.date.difference(lastWorkoutInSession.date).inHours;
          
          if (hoursBetween <= 2) {
            // Same session
            currentSession.add(workout);
          } else {
            // New session
            workoutSessions.add(List.from(currentSession));
            currentSession = [workout];
          }
        }
        workoutSessions.add(currentSession);
      }
      

      
      // Process each session
      for (final session in workoutSessions) {
        // Combine all exercises from this session by muscle group
        final Map<String, List<ExerciseData>> sessionExercisesByMuscleGroup = {};
        
        for (final workout in session) {
          final workoutExercises = workoutExercisesByMuscleGroup[workout.id];
          if (workoutExercises == null) continue;
          
          for (final muscleGroup in workoutExercises.keys) {
            sessionExercisesByMuscleGroup.putIfAbsent(muscleGroup, () => [])
                .addAll(workoutExercises[muscleGroup]!);
          }
        }
        
        // Process each muscle group for this session
        for (final muscleGroup in sessionExercisesByMuscleGroup.keys) {
          if (muscleGroupMap.containsKey(muscleGroup)) {
            final currentGroup = muscleGroupMap[muscleGroup]!;
            final exercises = sessionExercisesByMuscleGroup[muscleGroup]!;
            
            if (exercises.isNotEmpty) {
              // Calculate total training load for this muscle group in this session
              final totalBaseLoad = exercises.fold(0.0, (total, e) => total + (e.sets * e.weight * e.reps));
              
              // Calculate hours since last session (before this session started)
              final sessionStartTime = session.first.date;
              final hoursSinceLastSession = sessionStartTime.difference(currentGroup.lastTrained).inHours.toDouble();
              
              // Calculate fatigue score for this session
              final List<double> weeklyVolumes = sortedWorkouts
                  .where((w) => w.date.isBefore(sessionStartTime))
                  .where((w) => w.exercises.any((e) => 
                      RecoveryCalculator.getMuscleGroupsFromExercise(e.title, mainMuscle: e.mainMuscle).contains(muscleGroup)))
                  .map((w) => w.exercises
                      .where((e) => RecoveryCalculator.getMuscleGroupsFromExercise(e.title, mainMuscle: e.mainMuscle).contains(muscleGroup))
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
                currentVolume: totalBaseLoad,
                muscleGroup: muscleGroup,
                customBaselines: existingData?.customBaselines,
                bodyWeight: bodyWeight,
              );
              
              // Calculate new recovery
              final newRecovery = RecoveryCalculator.calculateRecoveryForMultipleExercises(
                exercises: exercises,
                hoursSinceLastSession: hoursSinceLastSession.toInt(),
                fatigueScore: fatigueScore,
                muscleGroup: muscleGroup,
                currentRecovery: currentGroup.recoveryPercentage,
                userWorkoutLoad: null,
              );
              

              
              // Update muscle group data
              final newTrainingLoad = currentGroup.trainingLoad + totalBaseLoad;
              final newLastTrained = sessionStartTime.isAfter(currentGroup.lastTrained) 
                  ? sessionStartTime 
                  : currentGroup.lastTrained;

              muscleGroupMap[muscleGroup] = MuscleGroup(
                name: muscleGroup,
                recoveryPercentage: newRecovery, // Update with new recovery
                lastTrained: newLastTrained,
                trainingLoad: newTrainingLoad,
                fatigueScore: fatigueScore,
                intensityAdjustedLoad: currentGroup.intensityAdjustedLoad,
              );
            }
          }
        }
      }

      // Recovery has already been calculated during workout processing
      // Just apply time-based recovery if needed
      for (final muscleGroup in muscleGroupMap.keys) {
        final group = muscleGroupMap[muscleGroup]!;
        final hoursSinceLastSession = now.difference(group.lastTrained).inHours.toDouble();
        
        // Only apply time-based recovery if significant time has passed since last workout
        if (hoursSinceLastSession > 1) {
          final timeBasedRecovery = RecoveryCalculator.calculateRecoveryForMultipleExercises(
            exercises: [],
            hoursSinceLastSession: hoursSinceLastSession.toInt(),
            fatigueScore: group.fatigueScore,
            muscleGroup: muscleGroup,
            currentRecovery: group.recoveryPercentage,
            userWorkoutLoad: null,
          );
          
          muscleGroupMap[muscleGroup] = MuscleGroup(
            name: muscleGroup,
            recoveryPercentage: timeBasedRecovery,
            lastTrained: group.lastTrained,
            trainingLoad: group.trainingLoad,
            fatigueScore: group.fatigueScore,
          );
        }
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
    final result = await calculateRecoveryData();
    return result;
  }

  /// Force immediate recalculation by clearing cache and recalculating
  static Future<RecoveryData> forceRecalculation() async {
    // First reset the cached data
    await resetRecoveryData();
    
    // Then recalculate fresh data
    final result = await calculateRecoveryData();
    
    return result;
  }

  /// Reset recovery data to force fresh calculation
  static Future<void> resetRecoveryData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recovery')
          .doc('data')
          .delete();
      
      _notifyRecoveryUpdate();
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting recovery data: $e');
      }
    }
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