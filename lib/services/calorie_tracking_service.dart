import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymfit/models/calorie_entry.dart';

class CalorieTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add a new calorie entry
  static Future<String> addCalorieEntry({
    required String name,
    required int calories,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    if (name.trim().isEmpty) {
      throw Exception('Food name cannot be empty');
    }

    if (calories <= 0) {
      throw Exception('Calories must be greater than 0');
    }

    final entry = CalorieEntry(
      id: '',
      name: name.trim(),
      calories: calories,
      date: DateTime.now(),
      userId: user.uid,
      notes: notes?.trim(),
    );

    try {
      final docRef = await _firestore
          .collection('calorie_entries')
          .add(entry.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add calorie entry: $e');
    }
  }

  /// Get calorie entries for a specific date
  static Future<List<CalorieEntry>> getCalorieEntriesForDate(
    DateTime date,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // First try the optimized query with index
      try {
        final snapshot =
            await _firestore
                .collection('calorie_entries')
                .where('userId', isEqualTo: user.uid)
                .where(
                  'date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
                )
                .where('date', isLessThan: Timestamp.fromDate(endOfDay))
                .orderBy('date', descending: true)
                .get();

        return snapshot.docs
            .map((doc) => CalorieEntry.fromMap(doc.data(), doc.id))
            .toList();
      } catch (indexError) {
        // If index doesn't exist, fall back to simpler query
        final snapshot =
            await _firestore
                .collection('calorie_entries')
                .where('userId', isEqualTo: user.uid)
                .get();

        // Filter by date in memory
        final allEntries =
            snapshot.docs
                .map((doc) => CalorieEntry.fromMap(doc.data(), doc.id))
                .toList();

        final filteredEntries =
            allEntries
                .where(
                  (entry) =>
                      entry.date.isAfter(startOfDay) &&
                      entry.date.isBefore(endOfDay),
                )
                .toList();

        // Sort by date descending
        filteredEntries.sort((a, b) => b.date.compareTo(a.date));

        return filteredEntries;
      }
    } catch (e) {
      throw Exception('Failed to fetch calorie entries: $e');
    }
  }

  /// Get calorie entries for the last 7 days
  static Future<List<CalorieEntry>> getCalorieEntriesForLastWeek() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      // First try the optimized query with index
      try {
        final snapshot =
            await _firestore
                .collection('calorie_entries')
                .where('userId', isEqualTo: user.uid)
                .where(
                  'date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo),
                )
                .orderBy('date', descending: true)
                .get();

        return snapshot.docs
            .map((doc) => CalorieEntry.fromMap(doc.data(), doc.id))
            .toList();
      } catch (indexError) {
        // If index doesn't exist, fall back to simpler query
        final snapshot =
            await _firestore
                .collection('calorie_entries')
                .where('userId', isEqualTo: user.uid)
                .get();

        // Filter by date in memory
        final allEntries =
            snapshot.docs
                .map((doc) => CalorieEntry.fromMap(doc.data(), doc.id))
                .toList();

        final filteredEntries =
            allEntries.where((entry) => entry.date.isAfter(weekAgo)).toList();

        // Sort by date descending
        filteredEntries.sort((a, b) => b.date.compareTo(a.date));

        return filteredEntries;
      }
    } catch (e) {
      throw Exception('Failed to fetch calorie entries: $e');
    }
  }

  /// Delete a calorie entry
  static Future<void> deleteCalorieEntry(String entryId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection('calorie_entries').doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete calorie entry: $e');
    }
  }

  /// Calculate total calories for a specific date
  static Future<int> getTotalCaloriesForDate(DateTime date) async {
    try {
      final entries = await getCalorieEntriesForDate(date);
      int total = 0;
      for (final entry in entries) {
        total += entry.calories;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  /// Get daily calorie totals for the last 7 days
  static Future<Map<DateTime, int>> getDailyCalorieTotals() async {
    try {
      final entries = await getCalorieEntriesForLastWeek();
      final Map<DateTime, int> dailyTotals = {};

      for (final entry in entries) {
        final date = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        dailyTotals[date] = (dailyTotals[date] ?? 0) + entry.calories;
      }

      return dailyTotals;
    } catch (e) {
      return {};
    }
  }
}
