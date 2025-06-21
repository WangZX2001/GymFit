import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/pages/workout/quick_start_page.dart';

class WorkoutService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String> saveWorkout({
    required List<QuickStartExercise> exercises,
    required Duration duration,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Convert QuickStartExercise to WorkoutExercise
    final workoutExercises = exercises.map((exercise) {
      final completedSets = exercise.sets.where((set) => set.isChecked).length;
      final workoutSets = exercise.sets.map((set) => WorkoutSet(
        weight: set.weight,
        reps: set.reps,
        isCompleted: set.isChecked,
      )).toList();

      return WorkoutExercise(
        title: exercise.title,
        totalSets: exercise.sets.length,
        completedSets: completedSets,
        sets: workoutSets,
      );
    }).toList();

    final totalSets = exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);
    final completedSets = exercises.fold(0, (sum, exercise) => 
        sum + exercise.sets.where((set) => set.isChecked).length);

    final workout = Workout(
      id: '', // Will be set by Firestore
      date: DateTime.now(),
      duration: duration,
      exercises: workoutExercises,
      totalSets: totalSets,
      completedSets: completedSets,
      userId: user.uid,
    );

    try {
      final docRef = await _firestore
          .collection('workouts')
          .add(workout.toMap());
      
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
      final workouts = querySnapshot.docs
          .map((doc) => Workout.fromSnapshot(doc))
          .toList();
      
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
      final workouts = snapshot.docs
          .map((doc) => Workout.fromSnapshot(doc))
          .toList();
      
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
      await _firestore.collection('workouts').doc(workoutId).delete();
    } catch (e) {
      throw Exception('Failed to delete workout: $e');
    }
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
} 