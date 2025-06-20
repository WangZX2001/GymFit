import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseInformation {
  final String title;
  final dynamic icon;
  final String mainMuscle;
  final String secondaryMuscle;
  final String experienceLevel;
  final String equipment;
  final String howTo;
  final String description;
  final String? videoUrl;
  final List<String> proTips;

  const ExerciseInformation({
    required this.title,
    required this.icon,
    required this.mainMuscle,
    required this.secondaryMuscle,
    required this.experienceLevel,
    required this.equipment,
    required this.howTo,
    required this.description,
    this.videoUrl,
    required this.proTips,
  });
}

class ExerciseInformationRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<List<ExerciseInformation>> getAllExerciseInformation() async {
    // 1. Query the collection
    final snapshot = await _firestore
      .collection('exercise_information')
      .get();

    // 2. Map each doc into your model
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ExerciseInformation(
        title: data['title'] as String? ?? 'Unknown Exercise',
        icon: data['icon'] ?? 'fitness_center',
        mainMuscle: data['main muscle'] as String? ?? 'Unknown',
        secondaryMuscle: data['secondary muscle'] as String? ?? '',
        experienceLevel: data['experience level'] as String? ?? 'Beginner',
        equipment: data['equipment'] as String? ?? 'Bodyweight',
        howTo: data['howTo'] as String? ?? 'Instructions will be available soon.',
        description: data['description'] as String? ?? 'Description will be available soon.',
        videoUrl: data['videoUrl'] as String?,
        proTips: () {
          final dynamic tips = data['proTips'];
          if (tips is List) {
            return tips.cast<String>();
          } else if (tips is String) {
            return [tips];
          } else {
            return ['Follow proper form.', 'Start with light weights.'];
          }
        }(),
      );
    }).toList();
  }
}
