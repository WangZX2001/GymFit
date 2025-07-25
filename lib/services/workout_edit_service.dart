import 'package:flutter/material.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/models/editable_workout_models.dart';
import 'package:gymfit/services/workout_service.dart';

class WorkoutEditService {


  static Future<void> selectStartDate(
    BuildContext context,
    DateTime currentStartTime,
    Function(DateTime) onStartTimeChanged,
    Function(DateTime) onEndTimeChanged,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentStartTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null && context.mounted) {
      final newStartTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        currentStartTime.hour,
        currentStartTime.minute,
      );
      
      onStartTimeChanged(newStartTime);
      
      // Ensure end time is after start time
      final currentEndTime = newStartTime.add(const Duration(minutes: 30));
      onEndTimeChanged(currentEndTime);
    }
  }

  static Future<void> selectStartTime(
    BuildContext context,
    DateTime currentStartTime,
    Function(DateTime) onStartTimeChanged,
    Function(DateTime) onEndTimeChanged,
  ) async {
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        int hour = currentStartTime.hour;
        int minute = currentStartTime.minute;
        bool isAM = hour < 12;
        
        return AlertDialog(
          title: const Text('Set Start Time'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Hour',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 120,
                            width: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 40,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              controller: FixedExtentScrollController(initialItem: hour % 12 == 0 ? 12 : hour % 12),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  hour = isAM ? (index == 12 ? 0 : index) : (index == 12 ? 12 : index + 12);
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  final displayHour = index == 0 ? 12 : index;
                                  return Center(
                                    child: Text(
                                      '$displayHour',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: (isAM ? (index == 12 ? 0 : index) : (index == 12 ? 12 : index + 12)) == hour ? Colors.blue : Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                                childCount: 13, // 1-12
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Column(
                        children: [
                          const Text(
                            'Minute',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 120,
                            width: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 40,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              controller: FixedExtentScrollController(initialItem: minute),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  minute = index;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: index == minute ? Colors.blue : Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                                childCount: 60,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'AM/PM',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 120,
                            width: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 40,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              controller: FixedExtentScrollController(initialItem: isAM ? 0 : 1),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  isAM = index == 0;
                                  // Adjust hour when switching AM/PM
                                  if (isAM && hour >= 12) {
                                    hour = hour == 12 ? 0 : hour - 12;
                                  } else if (!isAM && hour < 12) {
                                    hour = hour == 0 ? 12 : hour + 12;
                                  }
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      index == 0 ? 'AM' : 'PM',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: (index == 0) == isAM ? Colors.blue : Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                                childCount: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Time: ${hour == 0 ? 12 : hour > 12 ? hour - 12 : hour}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newTime = TimeOfDay(hour: hour, minute: minute);
                Navigator.of(context).pop(newTime);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    
    if (result != null && context.mounted) {
      final newStartTime = DateTime(
        currentStartTime.year,
        currentStartTime.month,
        currentStartTime.day,
        result.hour,
        result.minute,
      );
      
      onStartTimeChanged(newStartTime);
      
      // Ensure end time is after start time
      final currentEndTime = newStartTime.add(const Duration(minutes: 30));
      onEndTimeChanged(currentEndTime);
    }
  }

  static Future<void> selectDuration(
    BuildContext context,
    Duration currentDuration,
    Function(Duration) onDurationChanged,
  ) async {
    // Show a dialog with duration picker
    final result = await showDialog<Duration>(
      context: context,
      builder: (BuildContext context) {
        int hours = currentDuration.inHours;
        int minutes = currentDuration.inMinutes.remainder(60);
        
        return AlertDialog(
          title: const Text('Set Workout Duration'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Hours',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 120,
                            width: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 40,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              controller: FixedExtentScrollController(initialItem: hours),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  hours = index;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      '$index',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: index == hours ? Colors.blue : Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                                childCount: 100,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Column(
                        children: [
                          const Text(
                            'Minutes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 120,
                            width: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 40,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              controller: FixedExtentScrollController(initialItem: minutes),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  minutes = index;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: index == minutes ? Colors.blue : Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                                childCount: 60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Duration: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newDuration = Duration(hours: hours, minutes: minutes);
                Navigator.of(context).pop(newDuration);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    
    if (result != null) {
      onDurationChanged(result);
    }
  }

  static Future<bool> saveWorkout(
    Workout originalWorkout,
    String workoutName,
    DateTime startTime,
    DateTime endTime,
    List<EditableExercise> exercises,
    Function(bool) onSavingChanged,
  ) async {
    onSavingChanged(true);

    try {
      // Convert editable exercises back to workout format
      final updatedExercises = exercises.map((exercise) {
        final sets = exercise.sets.map((set) => WorkoutSet(
          weight: set.weight,
          reps: set.reps,
          isCompleted: set.isChecked,
        )).toList();
        
        final completedSets = sets.where((set) => set.isCompleted).length;
        return WorkoutExercise(
          title: exercise.title,
          totalSets: sets.length,
          completedSets: completedSets,
          sets: sets,
        );
      }).toList();

      final totalSets = updatedExercises.fold(0, (total, exercise) => total + exercise.totalSets);
      final completedSets = updatedExercises.fold(0, (total, exercise) => total + exercise.completedSets);

      final updatedWorkout = Workout(
        id: originalWorkout.id,
        name: workoutName.trim(),
        date: startTime,
        duration: endTime.difference(startTime),
        exercises: updatedExercises,
        totalSets: totalSets,
        completedSets: completedSets,
        userId: originalWorkout.userId,
      );

      await WorkoutService.updateWorkout(updatedWorkout);
      return true;
    } catch (e) {
      rethrow;
    } finally {
      onSavingChanged(false);
    }
  }

  static List<EditableExercise> convertWorkoutToEditable(Workout workout) {
    return workout.exercises.map((exercise) {
      final sets = exercise.sets.map((set) => EditableExerciseSet(
        weight: set.weight,
        reps: set.reps,
        isChecked: set.isCompleted,
      )).toList();
      return EditableExercise(title: exercise.title, sets: sets);
    }).toList();
  }
} 