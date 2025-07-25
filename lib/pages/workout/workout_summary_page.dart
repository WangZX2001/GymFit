import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/services/calorie_calculation_service.dart';
import 'package:gymfit/services/theme_service.dart';
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
  double _totalCalories = 0.0;
  bool _isCalculatingCalories = true;

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
    try {
      return widget.completedExercises.fold(0, (total, exercise) {
        return total +
            exercise.sets.where((set) => set.isChecked).length;
      });
    } catch (e) {
      return 0; // Return 0 if calculation fails
    }
  }

  String _getWorkoutName() {
    // Return custom name if provided
    if (widget.customWorkoutName != null &&
        widget.customWorkoutName!.isNotEmpty) {
      return widget.customWorkoutName!;
    }

    // Safely get start time with fallback
    final startTime =
        QuickStartOverlay.startTime ??
        DateTime.now().subtract(widget.workoutDuration);

    try {
      // Extract exercise names
      final exerciseNames =
          widget.completedExercises.map((e) => e.title).toList();

      return Workout.generateDefaultName(
        startTime: startTime,
        workoutDuration: widget.workoutDuration,
        exerciseNames: exerciseNames,
      );
    } catch (e) {
      // Fallback to a simple name if generation fails
      return 'Workout ${DateTime.now().toString().substring(0, 16)}';
    }
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
        calories: _totalCalories,
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Calculate calories first, then save workout
      await _calculateCalories();
      _saveWorkout();
    });
  }

  Future<void> _calculateCalories() async {
    try {
      // Validate that we have exercises to calculate
      if (widget.completedExercises.isEmpty) {
        if (mounted) {
          setState(() {
            _totalCalories = 0.0;
            _isCalculatingCalories = false;
          });
        }
        return;
      }

      // Convert exercises to the format expected by the calorie service
      final exercises =
          widget.completedExercises.map((exercise) {
            return {
              'title':
                  exercise.title.isNotEmpty
                      ? exercise.title
                      : 'Unknown Exercise',
              'sets':
                  exercise.sets.map((set) {
                    return {
                      'weight': set.weight,
                      'reps': set.reps,
                      'isChecked': set.isChecked,
                    };
                  }).toList(),
            };
          }).toList();

      final calories = await CalorieCalculationService.calculateTotalCalories(
        exercises: exercises,
        totalDurationMinutes: widget.workoutDuration.inMinutes,
      );

      if (mounted) {
        setState(() {
          _totalCalories = calories;
          _isCalculatingCalories = false;
        });
      }
    } catch (e) {
      // Set a default calorie value if calculation fails
      if (mounted) {
        setState(() {
          _totalCalories = 50.0; // Default minimum calories
          _isCalculatingCalories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    try {
      final totalCompletedSets = _getTotalCompletedSets();
      final totalExercises = widget.completedExercises.length;

      return PopScope(
        canPop: false, // Prevent back navigation
        child: Scaffold(
          backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
            elevation: 0,
            leading: const SizedBox(), // Remove back button
            automaticallyImplyLeading: false, // Disable back button and swipe gesture
            title: Text(
              'Workout Complete!',
              style: TextStyle(
                color: themeService.currentTheme.appBarTheme.foregroundColor,
                fontWeight: FontWeight.bold
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Congratulations Section
                          Column(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.trophy,
                                size: 64,
                                color: Colors.amber,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Congratulations!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: themeService.currentTheme.textTheme.titleLarge?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You\'ve completed your workout!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Workout Name Section
                          Row(
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
                                    Text(
                                      'Workout Name',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
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

                          const SizedBox(height: 20),

                          // Workout Stats Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workout Summary',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: themeService.currentTheme.textTheme.titleLarge?.color,
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
                                  Text(
                                    'Time Elapsed:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: themeService.currentTheme.textTheme.bodyLarge?.color,
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
                                  Text(
                                    'Exercises:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: themeService.currentTheme.textTheme.bodyLarge?.color,
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
                                  Text(
                                    'Sets Completed:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: themeService.currentTheme.textTheme.bodyLarge?.color,
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

                              const SizedBox(height: 12),

                              // Total Calories
                              Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.fire,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Calories Burnt:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: themeService.currentTheme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const Spacer(),
                                  _isCalculatingCalories
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.red,
                                        ),
                                      )
                                      : _totalCalories > 0
                                      ? Text(
                                        CalorieCalculationService.formatCalories(
                                          _totalCalories,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      )
                                      : Text(
                                        '0 cal',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                        ),
                                      ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Exercise Breakdown
                          if (widget.completedExercises.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Exercise Breakdown',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: themeService.currentTheme.textTheme.titleLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                ...widget.completedExercises.map((exercise) {
                                  final completedSets =
                                      exercise.sets
                                          .where(
                                            (set) => set.isChecked,
                                          )
                                          .length;
                                  final totalSets = exercise.sets.length;

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            exercise.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: themeService.currentTheme.textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                completedSets > 0
                                                    ? (themeService.isDarkMode ? Colors.green.shade900 : Colors.green.shade100)
                                                    : (themeService.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '$completedSets/$totalSets sets',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  completedSets > 0
                                                      ? (themeService.isDarkMode ? Colors.green.shade300 : Colors.green.shade700)
                                                      : (themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Done Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          // Clear workout data and navigate back to home
                          QuickStartOverlay.selectedExercises.clear();
                          QuickStartOverlay.resetTimer();
                          QuickStartOverlay.hideMinibar();

                          // Navigate back to home screen
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: themeService.isDarkMode ? Colors.white : Colors.black,
                          foregroundColor: themeService.isDarkMode ? Colors.black : Colors.white,
                          side: BorderSide(
                            color: themeService.isDarkMode ? Colors.white : Colors.black,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.check,
                              color: themeService.isDarkMode ? Colors.black : Colors.white,
                              size: 14.0 * 0.8,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w900,
                                color: themeService.isDarkMode ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      // Fallback UI in case of any build errors
      return Scaffold(
        backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: const SizedBox(),
          title: Text(
            'Workout Complete!',
            style: TextStyle(
              color: themeService.currentTheme.appBarTheme.foregroundColor,
              fontWeight: FontWeight.bold
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Workout Completed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: themeService.currentTheme.textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Great job completing your workout!',
                  style: TextStyle(
                    fontSize: 16,
                    color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Clear workout data and navigate back to home
                        QuickStartOverlay.selectedExercises.clear();
                        QuickStartOverlay.resetTimer();
                        QuickStartOverlay.hideMinibar();
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeService.isDarkMode ? Colors.white : Colors.black,
                        foregroundColor: themeService.isDarkMode ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeService.isDarkMode ? Colors.black : Colors.white,
                        ),
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
}
