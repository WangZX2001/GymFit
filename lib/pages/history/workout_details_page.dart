import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/pages/history/workout_edit_page.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

import 'package:intl/intl.dart';

class WorkoutDetailsPage extends StatelessWidget {
  final Workout workout;
  final bool isOwnWorkout;

  const WorkoutDetailsPage({
    super.key, 
    required this.workout,
    this.isOwnWorkout = true,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Workout Details',
          style: themeService.currentTheme.appBarTheme.titleTextStyle,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: themeService.currentTheme.appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (isOwnWorkout)
            IconButton(
              icon: Icon(
                Icons.edit, 
                color: themeService.currentTheme.appBarTheme.foregroundColor,
              ),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WorkoutEditPage(workout: workout),
                  ),
                );
                if (!context.mounted) return;

                // If the workout was successfully edited, pop this page to refresh the parent
                if (result == true) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout Name
            if (workout.name.isNotEmpty) ...[
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.tag,
                    color: Colors.purple,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      workout.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Date and Time
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.calendar,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${dateFormat.format(workout.date)} at ${timeFormat.format(workout.date)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Summary Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.stopwatch,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(workout.duration),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 12, 
                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.dumbbell,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${workout.exercises.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Exercises',
                      style: TextStyle(
                        fontSize: 12, 
                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.check,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${workout.completedSets}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Sets',
                      style: TextStyle(
                        fontSize: 12, 
                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.fire,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      workout.calories > 0
                          ? '${workout.calories.round()}'
                          : 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Calories',
                      style: TextStyle(
                        fontSize: 12, 
                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Exercise Breakdown Section
            Text(
              'Exercise Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeService.currentTheme.textTheme.titleLarge?.color,
              ),
            ),

            const SizedBox(height: 16),

            // Exercise List
            ...workout.exercises.map(
              (exercise) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Title and Summary
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: themeService.currentTheme.textTheme.titleMedium?.color,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              exercise.completedSets > 0
                                  ? (themeService.isDarkMode ? Colors.green.shade900 : Colors.green.shade100)
                                  : (themeService.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${exercise.completedSets}/${exercise.totalSets} sets',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                exercise.completedSets > 0
                                    ? (themeService.isDarkMode ? Colors.green.shade300 : Colors.green.shade700)
                                    : (themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Individual Sets Details
                  ...exercise.sets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final set = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  set.isCompleted
                                      ? Colors.green
                                      : (themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color:
                                      set.isCompleted
                                          ? Colors.white
                                          : (themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              set.isCompleted
                                  ? '${(set.weight % 1 == 0 ? set.weight.toInt() : set.weight)} kg × ${set.reps} reps'
                                  : 'Not completed',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    set.isCompleted
                                        ? (themeService.isDarkMode ? Colors.white : Colors.black87)
                                        : (themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500),
                                fontWeight:
                                    set.isCompleted
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Delete Button at Bottom (only for own workouts)
            if (isOwnWorkout)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteWorkoutConfirmation(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: themeService.isDarkMode 
                              ? Colors.red.shade600.withValues(alpha: 0.25)
                              : Colors.red.withValues(alpha: 0.15),
                          foregroundColor: themeService.isDarkMode 
                              ? Colors.red.shade300
                              : Colors.red.shade700,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: FaIcon(
                          FontAwesomeIcons.trash,
                          color: themeService.isDarkMode 
                              ? Colors.red.shade300
                              : Colors.red.shade700,
                          size: 14.0 * 0.8,
                        ),
                        label: Text(
                          'Delete Workout',
                          style: TextStyle(
                            color: themeService.isDarkMode 
                                ? Colors.red.shade300
                                : Colors.red.shade700,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteWorkoutConfirmation(BuildContext context) async {
    final dateFormat = DateFormat('MMM dd, yyyy');

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.trash,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text('Delete Workout'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to delete this workout?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(workout.date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${workout.exercises.length} exercises • ${workout.completedSets} sets • ${_formatDuration(workout.duration)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteWorkout(context);
    }
  }

  Future<void> _deleteWorkout(BuildContext context) async {
    bool isLoadingDialogOpen = false;

    try {
      // Show loading indicator with cancel option
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Deleting workout...',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a few seconds',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
      );
      isLoadingDialogOpen = true;

      // Delete workout with service-level timeout protection
      await WorkoutService.deleteWorkout(workout.id);

      // Close loading dialog first
      if (context.mounted && isLoadingDialogOpen) {
        Navigator.of(context).pop(); // Close loading dialog
        isLoadingDialogOpen = false;
      }

      // Small delay to ensure dialog is closed
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate back and show success message
      if (context.mounted) {
        Navigator.of(context).pop(); // Close details page

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Workout deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Always ensure loading dialog is closed
      if (context.mounted && isLoadingDialogOpen) {
        try {
          Navigator.of(context).pop(); // Close loading dialog
        } catch (navError) {
          // Ignore navigation errors during cleanup
        }
        isLoadingDialogOpen = false;
      }

      // Small delay to ensure dialog is closed
      await Future.delayed(const Duration(milliseconds: 100));

      if (context.mounted) {
        // Clean up error message
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to delete workout: $errorMsg')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _deleteWorkout(context),
            ),
          ),
        );
      }
    }
  }
}
