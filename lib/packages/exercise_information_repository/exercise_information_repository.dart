import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseInformation {
  final String title;
  final dynamic icon;
  final bool isImage;
  final double? customPadding;
  final String mainMuscle;
  final String description;
  final String? videoUrl;
  final List<String> precautions;

  const ExerciseInformation({
    required this.title,
    required this.icon,
    this.isImage = false,
    this.customPadding,
    required this.mainMuscle,
    required this.description,
    this.videoUrl,
    required this.precautions,
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
        title: data['title'] as String,
        icon: data['icon'] as String,
        isImage: (data['isImage'] as bool?) ?? (data['is image'] as bool? ?? false),
        customPadding: (data['customPadding'] as num?)?.toDouble(),
        mainMuscle: data['main muscle'] as String,
        description: data['description'] as String? ?? 'Description for ${data['title']} will be available soon.',
        videoUrl: data['videoUrl'] as String?,
        precautions: (data['precautions'] as List<dynamic>?)?.cast<String>() ?? ['Follow proper form.', 'Start with light weights.'],
      );
    }).toList();
  }
}
