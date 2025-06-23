import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymfit/models/custom_workout.dart';

class CustomWorkoutService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save a new custom workout template
  static Future<String> saveCustomWorkout({
    required String name,
    required List<CustomWorkoutExercise> exercises,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    if (name.trim().isEmpty) {
      throw Exception('Workout name cannot be empty');
    }

    if (exercises.isEmpty) {
      throw Exception('Please select at least one exercise');
    }

    final customWorkout = CustomWorkout(
      id: '', // Will be set by Firestore
      name: name.trim(),
      exercises: exercises,
      createdAt: DateTime.now(),
      userId: user.uid,
      description: description,
    );

    try {
      final docRef = await _firestore
          .collection('custom_workouts')
          .add(customWorkout.toMap());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save custom workout: $e');
    }
  }

  /// Backward compatibility method for saving with just exercise names
  static Future<String> saveCustomWorkoutWithNames({
    required String name,
    required List<String> exerciseNames,
  }) async {
    final exercises = exerciseNames.map((exerciseName) => 
      CustomWorkoutExercise(
        name: exerciseName,
        sets: [CustomWorkoutSet(weight: 0, reps: 0)],
      )
    ).toList();

    return saveCustomWorkout(name: name, exercises: exercises);
  }

  /// Get all saved custom workouts for the current user
  static Future<List<CustomWorkout>> getSavedCustomWorkouts() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final querySnapshot = await _firestore
          .collection('custom_workouts')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Sort by date in memory instead of in query to avoid composite index requirement
      final workouts = querySnapshot.docs
          .map((doc) => CustomWorkout.fromSnapshot(doc))
          .toList();
      
      // Sort by creation date descending
      workouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return workouts;
    } catch (e) {
      throw Exception('Failed to fetch custom workouts: $e');
    }
  }

  /// Get a stream of custom workouts for real-time updates
  static Stream<List<CustomWorkout>> getCustomWorkoutsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('User not authenticated');
    }

    return _firestore
        .collection('custom_workouts')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          // Sort by date in memory instead of in query to avoid composite index requirement
          final workouts = snapshot.docs
              .map((doc) => CustomWorkout.fromSnapshot(doc))
              .toList();
          
          // Sort by creation date descending
          workouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return workouts;
        });
  }

  /// Delete a custom workout
  static Future<void> deleteCustomWorkout(String workoutId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // First check if document exists and user owns it
      final docSnapshot = await _firestore
          .collection('custom_workouts')
          .doc(workoutId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Custom workout not found');
      }

      final data = docSnapshot.data();
      if (data?['userId'] != user.uid) {
        throw Exception('Unauthorized: You do not own this workout');
      }

      // Perform the delete
      await _firestore
          .collection('custom_workouts')
          .doc(workoutId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete custom workout: $e');
    }
  }

  /// Toggle pin status of a custom workout
  static Future<void> toggleWorkoutPin(String workoutId, bool pinned) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // First check if document exists and user owns it
      final docSnapshot = await _firestore
          .collection('custom_workouts')
          .doc(workoutId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Custom workout not found');
      }

      final data = docSnapshot.data();
      if (data?['userId'] != user.uid) {
        throw Exception('Unauthorized: You do not own this workout');
      }

      // Update the pinned status
      await _firestore
          .collection('custom_workouts')
          .doc(workoutId)
          .update({
        'pinned': pinned,
      });
    } catch (e) {
      throw Exception('Failed to update workout pin status: $e');
    }
  }

  /// Get only pinned custom workouts for the current user
  static Future<List<CustomWorkout>> getPinnedCustomWorkouts() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final querySnapshot = await _firestore
          .collection('custom_workouts')
          .where('userId', isEqualTo: user.uid)
          .where('pinned', isEqualTo: true)
          .get();

      // Sort by date in memory
      final workouts = querySnapshot.docs
          .map((doc) => CustomWorkout.fromSnapshot(doc))
          .toList();
      
      // Sort by creation date descending
      workouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return workouts;
    } catch (e) {
      throw Exception('Failed to fetch pinned custom workouts: $e');
    }
  }

  /// Update a custom workout
  static Future<void> updateCustomWorkout({
    required String workoutId,
    required String name,
    required List<CustomWorkoutExercise> exercises,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    if (name.trim().isEmpty) {
      throw Exception('Workout name cannot be empty');
    }

    if (exercises.isEmpty) {
      throw Exception('Please select at least one exercise');
    }

    try {
      // First check if document exists and user owns it
      final docSnapshot = await _firestore
          .collection('custom_workouts')
          .doc(workoutId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Custom workout not found');
      }

      final data = docSnapshot.data();
      if (data?['userId'] != user.uid) {
        throw Exception('Unauthorized: You do not own this workout');
      }

      // Update the document
      await _firestore
          .collection('custom_workouts')
          .doc(workoutId)
          .update({
        'name': name.trim(),
        'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
        'exerciseNames': exercises.map((e) => e.name).toList(), // Backward compatibility
      });
    } catch (e) {
      throw Exception('Failed to update custom workout: $e');
    }
  }
} 