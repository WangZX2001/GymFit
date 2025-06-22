import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/pages/workout_details_page.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const Text(
          'Workout History',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Workout>>(
          stream: WorkoutService.getUserWorkoutsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading workouts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final workouts = snapshot.data ?? [];

            if (workouts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.dumbbell,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Workouts Yet',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your first workout to see it here!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  final dateFormat = DateFormat('MMM dd, yyyy');
                  final timeFormat = DateFormat('h:mm a');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _showWorkoutDetails(context, workout);
                      },
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        _showWorkoutPreview(context, workout);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date and Time
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateFormat.format(workout.date),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  timeFormat.format(workout.date),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Workout Stats
                            Row(
                              children: [
                                // Duration
                                Expanded(
                                  child: Row(
                                    children: [
                                      const FaIcon(
                                        FontAwesomeIcons.stopwatch,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDuration(workout.duration),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Exercises
                                Expanded(
                                  child: Row(
                                    children: [
                                      const FaIcon(
                                        FontAwesomeIcons.dumbbell,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${workout.exercises.length} exercises',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Sets
                                Expanded(
                                  child: Row(
                                    children: [
                                      const FaIcon(
                                        FontAwesomeIcons.check,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${workout.completedSets} sets',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Exercise List Preview
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: workout.exercises.map((exercise) => Padding(
                                padding: const EdgeInsets.only(bottom: 2.0),
                                child: Text(
                                  '${exercise.completedSets} x ${exercise.title}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )).toList(),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Tap hint
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Tap for details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _showWorkoutDetails(BuildContext context, Workout workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailsPage(workout: workout),
      ),
    );
  }

  void _showWorkoutPreview(BuildContext context, Workout workout) {
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Workout Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and Time
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.calendar,
                              color: Colors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${dateFormat.format(workout.date)} at ${timeFormat.format(workout.date)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Quick Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPreviewStat(
                            FontAwesomeIcons.stopwatch,
                            Colors.blue,
                            _formatDuration(workout.duration),
                            'Duration',
                          ),
                          _buildPreviewStat(
                            FontAwesomeIcons.dumbbell,
                            Colors.green,
                            '${workout.exercises.length}',
                            'Exercises',
                          ),
                          _buildPreviewStat(
                            FontAwesomeIcons.check,
                            Colors.orange,
                            '${workout.completedSets}',
                            'Sets',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Exercise Summary
                      const Text(
                        'Exercises',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      ...workout.exercises.map((exercise) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Exercise Title and Summary
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: exercise.completedSets > 0 
                                          ? Colors.green 
                                          : Colors.grey.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      exercise.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${exercise.completedSets}/${exercise.totalSets}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // All Sets Details
                              ...exercise.sets.asMap().entries.map((entry) {
                                final int setIndex = entry.key;
                                final set = entry.value;
                                
                                return Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: set.isCompleted 
                                        ? Colors.green.shade50 
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: set.isCompleted 
                                          ? Colors.green.shade200 
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Set ${setIndex + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: set.isCompleted 
                                              ? Colors.green.shade700 
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        '${set.weight} kg × ${set.reps} reps',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: set.isCompleted 
                                              ? Colors.green.shade700 
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                      Icon(
                                        set.isCompleted 
                                            ? Icons.check_circle 
                                            : Icons.radio_button_unchecked,
                                        size: 16,
                                        color: set.isCompleted 
                                            ? Colors.green 
                                            : Colors.grey.shade400,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 16),
                      
                      // View Details Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showWorkoutDetails(context, workout);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'View Full Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewStat(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        FaIcon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }


} 