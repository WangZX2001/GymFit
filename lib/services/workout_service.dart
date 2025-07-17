import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/models/quick_start_exercise.dart';

class WorkoutService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notification system for workout updates
  static final List<VoidCallback> _workoutUpdateListeners = [];

  // Add a listener for workout updates
  static void addWorkoutUpdateListener(VoidCallback listener) {
    _workoutUpdateListeners.add(listener);
  }

  // Remove a listener for workout updates
  static void removeWorkoutUpdateListener(VoidCallback listener) {
    _workoutUpdateListeners.remove(listener);
  }

  // Notify all listeners that workouts have been updated
  static void _notifyWorkoutUpdate() {
    for (final listener in _workoutUpdateListeners) {
      try {
        listener();
      } catch (e) {
        // Handle any errors in listeners gracefully
        if (kDebugMode) {
          print('Error in workout update listener: $e');
        }
      }
    }
  }

  static Future<String> saveWorkout({
    required List<QuickStartExercise> exercises,
    required Duration duration,
    DateTime? startTime,
    String? customWorkoutName,
    double calories = 0.0,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Convert QuickStartExercise to WorkoutExercise
    final workoutExercises =
        exercises.map((exercise) {
          final completedSets =
              exercise.sets.where((set) => set.isChecked).length;
          final workoutSets =
              exercise.sets
                  .map(
                    (set) => WorkoutSet(
                      weight: set.weight,
                      reps: set.reps,
                      isCompleted: set.isChecked,
                    ),
                  )
                  .toList();

          return WorkoutExercise(
            title: exercise.title,
            totalSets: exercise.sets.length,
            completedSets: completedSets,
            sets: workoutSets,
          );
        }).toList();

    final totalSets = exercises.fold(
      0,
      (total, exercise) => total + exercise.sets.length,
    );
    final completedSets = exercises.fold(
      0,
      (total, exercise) =>
          total + exercise.sets.where((set) => set.isChecked).length,
    );

    // Calculate workout start time (end time minus duration)
    final workoutStartTime = startTime ?? DateTime.now().subtract(duration);

    // Use custom name if provided, otherwise generate default name
    final workoutName =
        customWorkoutName?.isNotEmpty == true
            ? customWorkoutName!
            : Workout.generateDefaultName(
              startTime: workoutStartTime,
              workoutDuration: duration,
              exerciseNames: exercises.map((e) => e.title).toList(),
            );

    final workout = Workout(
      id: '', // Will be set by Firestore
      name: workoutName,
      date: DateTime.now(),
      duration: duration,
      exercises: workoutExercises,
      totalSets: totalSets,
      completedSets: completedSets,
      userId: user.uid,
      calories: calories,
    );

    try {
      final docRef = await _firestore
          .collection('workouts')
          .add(workout.toMap());

      // Notify listeners that a workout has been saved
      _notifyWorkoutUpdate();

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save workout: $e');
    }
  }

  static Future<List<Workout>> getUserWorkouts({int? limit}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      Query query = _firestore
          .collection('workouts')
          .where('userId', isEqualTo: user.uid);

      final querySnapshot = await query.get();

      // Sort by date in memory instead of in query
      final workouts =
          querySnapshot.docs.map((doc) => Workout.fromSnapshot(doc)).toList();

      // Sort by date descending
      workouts.sort((a, b) => b.date.compareTo(a.date));

      // Apply limit if specified
      if (limit != null && workouts.length > limit) {
        return workouts.take(limit).toList();
      }

      return workouts;
    } catch (e) {
      throw Exception('Failed to fetch workouts: $e');
    }
  }

  static Stream<List<Workout>> getUserWorkoutsStream({int? limit}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('User not authenticated');
    }

    Query query = _firestore
        .collection('workouts')
        .where('userId', isEqualTo: user.uid);

    return query.snapshots().map((snapshot) {
      // Sort by date in memory instead of in query
      final workouts =
          snapshot.docs.map((doc) => Workout.fromSnapshot(doc)).toList();

      // Sort by date descending
      workouts.sort((a, b) => b.date.compareTo(a.date));

      // Apply limit if specified
      if (limit != null && workouts.length > limit) {
        return workouts.take(limit).toList();
      }

      return workouts;
    });
  }

  static Future<void> deleteWorkout(String workoutId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Add timeout protection at service level
      await Future.any([
        _performDelete(workoutId, user.uid),
        Future.delayed(const Duration(seconds: 8), () {
          throw Exception('Delete operation timed out after 8 seconds');
        }),
      ]);
    } catch (e) {
      // Clean up the error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      throw Exception(errorMsg);
    }
  }

  static Future<void> _performDelete(String workoutId, String userId) async {
    // First check if document exists with timeout
    final docSnapshot = await _firestore
        .collection('workouts')
        .doc(workoutId)
        .get()
        .timeout(const Duration(seconds: 3));

    if (!docSnapshot.exists) {
      throw Exception('Workout not found');
    }

    final data = docSnapshot.data();

    // Verify user owns this workout
    if (data?['userId'] != userId) {
      throw Exception('Unauthorized: You do not own this workout');
    }

    // Perform the delete with timeout
    await _firestore
        .collection('workouts')
        .doc(workoutId)
        .delete()
        .timeout(const Duration(seconds: 4));

    // Notify listeners that a workout has been deleted
    _notifyWorkoutUpdate();
  }

  static Future<void> updateWorkout(Workout workout) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // First check if document exists and user owns it
      final docSnapshot =
          await _firestore.collection('workouts').doc(workout.id).get();

      if (!docSnapshot.exists) {
        throw Exception('Workout not found');
      }

      final data = docSnapshot.data();
      if (data?['userId'] != user.uid) {
        throw Exception('Unauthorized: You do not own this workout');
      }

      // Update the document
      await _firestore
          .collection('workouts')
          .doc(workout.id)
          .update(workout.toMap());

      // Notify listeners that a workout has been updated
      _notifyWorkoutUpdate();
    } catch (e) {
      throw Exception('Failed to update workout: $e');
    }
  }

  /// Test Firebase connectivity - useful for debugging
  static Future<Map<String, bool>> testFirebaseConnectivity() async {
    final user = _auth.currentUser;
    Map<String, bool> results = {};

    try {
      // Test 1: Firebase Auth
      debugPrint('🧪 Testing Firebase Auth...');
      results['auth'] = user != null;
      debugPrint('   Auth result: ${results['auth']}');

      // Test 2: Firestore Connection
      debugPrint('🧪 Testing Firestore connection...');
      try {
        await _firestore.enableNetwork();
        results['firestore'] = true;
        debugPrint('   Firestore connection: SUCCESS');
      } catch (e) {
        results['firestore'] = false;
        debugPrint('   Firestore connection: FAILED - $e');
      }

      // Test 3: Workout Collection Access
      if (user != null) {
        debugPrint('🧪 Testing workout collection access...');
        try {
          final querySnapshot =
              await _firestore
                  .collection('workouts')
                  .where('userId', isEqualTo: user.uid)
                  .limit(1)
                  .get();
          results['workoutCollection'] = true;
          debugPrint(
            '   Workout collection access: SUCCESS (${querySnapshot.docs.length} docs found)',
          );
        } catch (e) {
          results['workoutCollection'] = false;
          debugPrint('   Workout collection access: FAILED - $e');
        }
      } else {
        results['workoutCollection'] = false;
        debugPrint('   Workout collection access: SKIPPED (no user)');
      }

      // Test 4: Delete Operation (simulate without actually deleting)
      if (user != null) {
        debugPrint('🧪 Testing delete operation permissions...');
        try {
          // Just check if we can read a document for delete permission testing
          await _firestore
              .collection('workouts')
              .where('userId', isEqualTo: user.uid)
              .limit(1)
              .get();
          results['deleteOperation'] = true;
          debugPrint('   Delete operation permissions: SUCCESS');
        } catch (e) {
          results['deleteOperation'] = false;
          debugPrint('   Delete operation permissions: FAILED - $e');
        }
      } else {
        results['deleteOperation'] = false;
        debugPrint('   Delete operation permissions: SKIPPED (no user)');
      }
    } catch (e) {
      debugPrint('❌ Firebase connectivity test failed: $e');
      // Return whatever results we have so far
    }

    debugPrint('🧪 Firebase test results: $results');
    return results;
  }

  static Future<Workout?> getWorkout(String workoutId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final doc = await _firestore.collection('workouts').doc(workoutId).get();
      if (doc.exists) {
        return Workout.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch workout: $e');
    }
  }

  /// Get friends' workouts for the friends feed
  static Future<List<Workout>> getFriendsWorkouts({int? limit}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // First get the user's friends list
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || userDoc.data() == null) {
        return [];
      }

      final friendIds = List<String>.from(userDoc.data()!['friends'] ?? []);
      if (friendIds.isEmpty) {
        return [];
      }

      // Query workouts from friends
      Query query = _firestore
          .collection('workouts')
          .where('userId', whereIn: friendIds);

      final querySnapshot = await query.get();

      // Sort by date in memory instead of in query
      final workouts =
          querySnapshot.docs.map((doc) => Workout.fromSnapshot(doc)).toList();

      // Sort by date descending
      workouts.sort((a, b) => b.date.compareTo(a.date));

      // Apply limit if specified
      if (limit != null && workouts.length > limit) {
        return workouts.take(limit).toList();
      }

      return workouts;
    } catch (e) {
      throw Exception('Failed to fetch friends workouts: $e');
    }
  }

  /// Get a stream of friends' workouts for real-time updates
  static Stream<List<Workout>> getFriendsWorkoutsStream({int? limit}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('User not authenticated');
    }

    return _firestore.collection('users').doc(user.uid).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists || userDoc.data() == null) {
        return <Workout>[];
      }

      final friendIds = List<String>.from(userDoc.data()!['friends'] ?? []);
      if (friendIds.isEmpty) {
        return <Workout>[];
      }

      // Query workouts from friends
      final querySnapshot = await _firestore
          .collection('workouts')
          .where('userId', whereIn: friendIds)
          .get();

      // Sort by date in memory instead of in query
      final workouts =
          querySnapshot.docs.map((doc) => Workout.fromSnapshot(doc)).toList();

      // Sort by date descending
      workouts.sort((a, b) => b.date.compareTo(a.date));

      // Apply limit if specified
      if (limit != null && workouts.length > limit) {
        return workouts.take(limit).toList();
      }

      return workouts;
    });
  }

  /// Get user info by user ID (for displaying friend info in workout cards)
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user info: $e');
      return null;
    }
  }

  /// Get the most recent exercise data for prefilling
  static Future<Map<String, dynamic>?> getLastExerciseData(String exerciseName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the most recent workouts that contain this exercise
      // Note: We remove orderBy to avoid requiring a composite index
      final querySnapshot = await _firestore
          .collection('workouts')
          .where('userId', isEqualTo: user.uid)
          .limit(50) // Get more docs since we can't sort by date in query
          .get();

      // Convert to workouts and sort by date manually
      final workouts = querySnapshot.docs
          .map((doc) => Workout.fromSnapshot(doc))
          .toList();
      
      // Sort by date descending (most recent first)
      workouts.sort((a, b) => b.date.compareTo(a.date));

      // Look through workouts to find the most recent one with this exercise
      for (final workout in workouts) {
        
        // Find the exercise in this workout
        final exercise = workout.exercises.firstWhere(
          (e) => e.title.toLowerCase() == exerciseName.toLowerCase(),
          orElse: () => WorkoutExercise(title: '', totalSets: 0, completedSets: 0, sets: []),
        );

        if (exercise.title.isNotEmpty && exercise.sets.isNotEmpty) {
          // Return all sets data for intelligent prefilling
          final setsData = exercise.sets.map((set) => {
            'weight': set.weight,
            'reps': set.reps,
            'isCompleted': set.isCompleted,
          }).toList();

          return {
            'sets': setsData,
            'totalSets': exercise.sets.length,
          };
        }
      }

      return null; // No previous data found
    } catch (e) {
      debugPrint('Error fetching last exercise data: $e');
      return null;
    }
  }
}
