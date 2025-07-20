import 'package:flutter/material.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/models/editable_workout_models.dart';
import 'package:gymfit/services/workout_service.dart';

class WorkoutEditService {
  static Future<void> selectStartTime(
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
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentStartTime),
      );
      
      if (pickedTime != null && context.mounted) {
        final newStartTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        onStartTimeChanged(newStartTime);
        
        // Ensure end time is after start time
        final currentEndTime = currentStartTime.add(const Duration(minutes: 30));
        if (currentEndTime.isBefore(newStartTime)) {
          onEndTimeChanged(newStartTime.add(const Duration(minutes: 30)));
        }
      }
    }
  }

  static Future<void> selectEndTime(
    BuildContext context,
    DateTime currentStartTime,
    DateTime currentEndTime,
    Function(DateTime) onEndTimeChanged,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentEndTime,
      firstDate: currentStartTime,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentEndTime),
      );
      
      if (pickedTime != null && context.mounted) {
        final newEndTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        if (newEndTime.isAfter(currentStartTime)) {
          onEndTimeChanged(newEndTime);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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