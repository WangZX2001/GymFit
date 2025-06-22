import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:gymfit/pages/workout/quick_start_page.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/models/workout.dart';

class WorkoutSummaryPage extends StatefulWidget {
  final List<QuickStartExercise> completedExercises;
  final Duration workoutDuration;
  final String? customWorkoutName;

  const WorkoutSummaryPage({
    super.key,
    required this.completedExercises,
    required this.workoutDuration,
    this.customWorkoutName,
  });

  @override
  State<WorkoutSummaryPage> createState() => _WorkoutSummaryPageState();
}

class _WorkoutSummaryPageState extends State<WorkoutSummaryPage> {
  bool _isSaving = false;
  bool _workoutSaved = false;

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

  int _getTotalCompletedSets() {
    return widget.completedExercises.fold(0, (total, exercise) {
      return total + exercise.sets.where((set) => set.isChecked).length;
    });
  }

  String _getWorkoutName() {
    // Return custom name if provided
    if (widget.customWorkoutName != null && widget.customWorkoutName!.isNotEmpty) {
      return widget.customWorkoutName!;
    }
    
    final startTime = QuickStartOverlay.startTime ?? DateTime.now().subtract(widget.workoutDuration);
    return Workout.generateDefaultName(
      startTime: startTime,
      workoutDuration: widget.workoutDuration,
      exerciseNames: widget.completedExercises.map((e) => e.title).toList(),
    );
  }

  Future<void> _saveWorkout() async {
    if (_workoutSaved || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await WorkoutService.saveWorkout(
        exercises: widget.completedExercises,
        duration: widget.workoutDuration,
        startTime: QuickStartOverlay.startTime,
        customWorkoutName: widget.customWorkoutName,
      );

      setState(() {
        _workoutSaved = true;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-save the workout when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveWorkout();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalCompletedSets = _getTotalCompletedSets();
    final totalExercises = widget.completedExercises.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        leading: const SizedBox(), // Remove back button
        title: const Text(
          'Workout Complete!',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Congratulations Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.trophy,
                              size: 64,
                              color: Colors.amber,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Congratulations!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You\'ve completed your workout!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Workout Name Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.tag,
                              size: 24,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Workout Name',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getWorkoutName(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Workout Stats Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Workout Summary',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Time Elapsed
                            Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.stopwatch,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Time Elapsed:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                                                 Text(
                                   _formatDuration(widget.workoutDuration),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Total Exercises
                            Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.dumbbell,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Exercises:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$totalExercises',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Total Sets
                            Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.check,
                                  size: 20,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Sets Completed:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$totalCompletedSets',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Exercise Breakdown
                      if (widget.completedExercises.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Exercise Breakdown',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              ...widget.completedExercises.map((exercise) {
                                final completedSets = exercise.sets.where((set) => set.isChecked).length;
                                final totalSets = exercise.sets.length;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exercise.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: completedSets > 0 
                                              ? Colors.green.shade100
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$completedSets/$totalSets sets',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: completedSets > 0 
                                                ? Colors.green.shade700
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 100), // Extra space for button
                    ],
                  ),
                ),
              ),
              
              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Clear workout data and navigate back to home
                    QuickStartOverlay.selectedExercises.clear();
                    QuickStartOverlay.resetTimer();
                    QuickStartOverlay.hideMinibar();
                    
                    // Navigate back to home screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 