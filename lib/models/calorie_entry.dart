import 'package:cloud_firestore/cloud_firestore.dart';

class CalorieEntry {
  final String id;
  final String name;
  final int calories;
  final DateTime date;
  final String userId;
  final String? notes;

  CalorieEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.date,
    required this.userId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'notes': notes,
    };
  }

  factory CalorieEntry.fromMap(Map<String, dynamic> map, String id) {
    return CalorieEntry(
      id: id,
      name: map['name'] ?? '',
      calories: map['calories'] ?? 0,
      date: (map['date'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
      notes: map['notes'],
    );
  }
}
