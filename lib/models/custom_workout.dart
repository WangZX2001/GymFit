import 'package:cloud_firestore/cloud_firestore.dart';

class CustomWorkoutExercise {
  final String name;
  final List<CustomWorkoutSet> sets;

  CustomWorkoutExercise({
    required this.name,
    required this.sets,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets.map((set) => set.toMap()).toList(),
    };
  }

  factory CustomWorkoutExercise.fromMap(Map<String, dynamic> map) {
    return CustomWorkoutExercise(
      name: map['name'] ?? '',
      sets: (map['sets'] as List<dynamic>?)
          ?.map((set) => CustomWorkoutSet.fromMap(set as Map<String, dynamic>))
          .toList() ?? [CustomWorkoutSet(weight: 0, reps: 0)],
    );
  }
}

class CustomWorkoutSet {
  final int weight;
  final int reps;

  CustomWorkoutSet({
    required this.weight,
    required this.reps,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'reps': reps,
    };
  }

  factory CustomWorkoutSet.fromMap(Map<String, dynamic> map) {
    return CustomWorkoutSet(
      weight: map['weight'] ?? 0,
      reps: map['reps'] ?? 0,
    );
  }
}

class CustomWorkout {
  final String id;
  final String name;
  final List<CustomWorkoutExercise> exercises;
  final DateTime createdAt;
  final String userId;
  final bool pinned;

  CustomWorkout({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
    required this.userId,
    this.pinned = false,
  });

  // Backward compatibility - get exercise names
  List<String> get exerciseNames => exercises.map((e) => e.name).toList();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'exerciseNames': exerciseNames, // Keep for backward compatibility
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'pinned': pinned,
    };
  }

  factory CustomWorkout.fromMap(Map<String, dynamic> map, String documentId) {
    // Handle both new format (with exercises) and old format (with exerciseNames)
    List<CustomWorkoutExercise> exercises;
    
    if (map['exercises'] != null) {
      // New format with full exercise data
      exercises = (map['exercises'] as List<dynamic>)
          .map((exercise) => CustomWorkoutExercise.fromMap(exercise as Map<String, dynamic>))
          .toList();
    } else {
      // Backward compatibility - convert exerciseNames to exercises
      final exerciseNames = List<String>.from(map['exerciseNames'] ?? []);
      exercises = exerciseNames.map((name) => CustomWorkoutExercise(
        name: name,
        sets: [CustomWorkoutSet(weight: 0, reps: 0)],
      )).toList();
    }

    return CustomWorkout(
      id: documentId,
      name: map['name'] ?? '',
      exercises: exercises,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
      pinned: map['pinned'] ?? false,
    );
  }

  factory CustomWorkout.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return CustomWorkout.fromMap(data, snapshot.id);
  }
} 