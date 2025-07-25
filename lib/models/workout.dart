import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutExercise {
  final String title;
  final String? mainMuscle; // Nullable, for legacy compatibility
  final int totalSets;
  final int completedSets;
  final List<WorkoutSet> sets;

  WorkoutExercise({
    required this.title,
    this.mainMuscle,
    required this.totalSets,
    required this.completedSets,
    required this.sets,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'main muscle': mainMuscle, // Map to Firestore as 'main muscle'
      'totalSets': totalSets,
      'completedSets': completedSets,
      'sets': sets.map((set) => set.toMap()).toList(),
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      title: map['title'] ?? '',
      mainMuscle: map['main muscle'], // Read from Firestore as 'main muscle'
      totalSets: map['totalSets'] ?? 0,
      completedSets: map['completedSets'] ?? 0,
      sets:
          (map['sets'] as List<dynamic>?)
              ?.map((set) => WorkoutSet.fromMap(set as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WorkoutSet {
  final double weight;
  final int reps;
  final bool isCompleted;

  WorkoutSet({
    required this.weight,
    required this.reps,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {'weight': weight, 'reps': reps, 'isCompleted': isCompleted};
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      reps: map['reps'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class Workout {
  final String id;
  final String name;
  final DateTime date;
  final Duration duration;
  final List<WorkoutExercise> exercises;
  final int totalSets;
  final int completedSets;
  final String userId;
  final double calories;

  Workout({
    required this.id,
    required this.name,
    required this.date,
    required this.duration,
    required this.exercises,
    required this.totalSets,
    required this.completedSets,
    required this.userId,
    this.calories = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': Timestamp.fromDate(date),
      'durationSeconds': duration.inSeconds,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'totalSets': totalSets,
      'completedSets': completedSets,
      'userId': userId,
      'calories': calories,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map, String documentId) {
    return Workout(
      id: documentId,
      name: map['name'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      duration: Duration(seconds: map['durationSeconds'] ?? 0),
      exercises:
          (map['exercises'] as List<dynamic>?)
              ?.map(
                (exercise) =>
                    WorkoutExercise.fromMap(exercise as Map<String, dynamic>),
              )
              .toList() ??
          [],
      totalSets: map['totalSets'] ?? 0,
      completedSets: map['completedSets'] ?? 0,
      userId: map['userId'] ?? '',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory Workout.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Workout.fromMap(data, snapshot.id);
  }

  /// Generate a default workout name based on time of day and workout characteristics
  static String generateDefaultName({
    required DateTime startTime,
    required Duration workoutDuration,
    required List<String> exerciseNames,
  }) {
    final hour = startTime.hour;
    String timeOfDay;

    // Determine time of day
    if (hour >= 5 && hour < 12) {
      timeOfDay = 'Morning';
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = 'Afternoon';
    } else if (hour >= 17 && hour < 21) {
      timeOfDay = 'Evening';
    } else {
      timeOfDay = 'Night';
    }

    // Determine workout type based on duration and exercises
    String workoutType;
    final durationMinutes = workoutDuration.inMinutes;

    if (durationMinutes < 20) {
      workoutType = 'Quick';
    } else if (durationMinutes < 45) {
      workoutType = 'Power';
    } else if (durationMinutes < 75) {
      workoutType = 'Strong';
    } else {
      workoutType = 'Epic';
    }

    // Check for specific exercise types to add descriptors
    String descriptor = '';
    final lowerExercises = exerciseNames.map((e) => e.toLowerCase()).toList();

    if (lowerExercises.any(
      (e) => e.contains('chest') || e.contains('bench') || e.contains('push'),
    )) {
      descriptor = ' Push';
    } else if (lowerExercises.any(
      (e) => e.contains('pull') || e.contains('row') || e.contains('lat'),
    )) {
      descriptor = ' Pull';
    } else if (lowerExercises.any(
      (e) => e.contains('squat') || e.contains('leg') || e.contains('deadlift'),
    )) {
      descriptor = ' Lower';
    } else if (lowerExercises.any(
      (e) =>
          e.contains('shoulder') ||
          e.contains('arm') ||
          e.contains('bicep') ||
          e.contains('tricep'),
    )) {
      descriptor = ' Upper';
    }

    return '$timeOfDay $workoutType$descriptor';
  }
}
