import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseInformation {
  final String title;
  final dynamic icon;
  final bool isImage;
  final double? customPadding;
  final String mainMuscle;

  const ExerciseInformation({
    required this.title,
    required this.icon,
    this.isImage = false,
    this.customPadding,
    required this.mainMuscle,
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
      );
    }).toList();
  }
}
