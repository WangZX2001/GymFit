import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:gymfit/pages/workout/custom_workout_configuration_page_refactored.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/models/exercise_set.dart';
import 'package:gymfit/services/custom_workout_service.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class CustomWorkoutPage extends StatefulWidget {
  const CustomWorkoutPage({super.key});

  @override
  State<CustomWorkoutPage> createState() => _CustomWorkoutPageState();
}

class _CustomWorkoutPageState extends State<CustomWorkoutPage> {
  List<CustomWorkout> _savedWorkouts = [];
  bool _isLoading = false;
  final Set<String> _firstSlideCompleted = {};

  @override
  void initState() {
    super.initState();
    _loadSavedWorkouts();
  }

  Future<void> _loadSavedWorkouts() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final workouts = await CustomWorkoutService.getSavedCustomWorkouts();
      if (mounted) {
        setState(() {
          _savedWorkouts = workouts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workouts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showWorkoutDetails(CustomWorkout workout) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 750,
              maxWidth: 400,
            ),
            decoration: BoxDecoration(
              color: themeService.currentTheme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeService.currentTheme.cardTheme.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.dumbbell,
                        color: themeService.currentTheme.textTheme.titleMedium?.color,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          workout.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: themeService.currentTheme.textTheme.titleMedium?.color,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _editWorkout(workout);
                        },
                        icon: FaIcon(
                          FontAwesomeIcons.penToSquare, 
                          color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey, 
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: FaIcon(
                          FontAwesomeIcons.xmark, 
                          color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey, 
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                // Exercise list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: workout.exercises.length + (workout.description != null && workout.description!.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show description first if it exists
                      if (workout.description != null && workout.description!.isNotEmpty && index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: themeService.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.black,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            workout.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: themeService.currentTheme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        );
                      }
                      
                      // Adjust exercise index based on whether description is shown
                      final exerciseIndex = workout.description != null && workout.description!.isNotEmpty ? index - 1 : index;
                      final exercise = workout.exercises[exerciseIndex];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        color: themeService.isDarkMode 
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Exercise name
                              Text(
                                exercise.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: themeService.currentTheme.textTheme.titleMedium?.color,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Sets details
                              ...exercise.sets.asMap().entries.map((entry) {
                                final setIndex = entry.key;
                                final set = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${setIndex + 1}',
                                            style: TextStyle(
                                              color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${(set.weight % 1 == 0 ? set.weight.toInt() : set.weight)} kg × ${set.reps} reps',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: themeService.currentTheme.textTheme.bodyLarge?.color,
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
                      );
                    },
                  ),
                ),
                // Footer with start workout button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _startCustomWorkout(workout);
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
                        'Start Workout',
                        style: TextStyle(
                          color: themeService.isDarkMode ? Colors.black : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _browseExercises() async {
    if (!mounted) return;
    
    final selectedExercises = await Navigator.of(context, rootNavigator: true).push<List<String>>(
      MaterialPageRoute(
        builder: (context) => const ExerciseInformationPage(
          isSelectionMode: true,
        ),
      ),
    );

    if (!mounted) return;

    if (selectedExercises != null && selectedExercises.isNotEmpty) {
      // Navigate to configuration page
      final result = await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => CustomWorkoutConfigurationPage(
            exerciseNames: selectedExercises,
          ),
        ),
      );

      if (mounted && result == true) {
        _loadSavedWorkouts();
      }
    }
  }

  /// Check if there's a quick start workout currently in progress
  bool _isQuickStartInProgress() {
    return QuickStartOverlay.selectedExercises.isNotEmpty;
  }

  /// Show confirmation dialog for starting a new quick start when one is already in progress
  Future<bool> _showQuickStartConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Workout in Progress'),
          content: const Text('Are you sure you want to delete the current workout and start a new one?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Start New'),
            ),
          ],
        );
      },
    ) ?? false; // Return false if dialog is dismissed
  }

  Future<void> _startCustomWorkout(CustomWorkout workout) async {
    if (_isQuickStartInProgress()) {
      // Show confirmation dialog
      final shouldStartNew = await _showQuickStartConfirmationDialog(context);
      if (!shouldStartNew) {
        return; // User cancelled, don't start new workout
      }
      
      // Add haptic feedback when starting new workout after confirmation
      HapticFeedback.heavyImpact();
      // Clear existing workout
      QuickStartOverlay.selectedExercises.clear();
      QuickStartOverlay.resetTimer();
    } else {
      // Add haptic feedback when starting new workout
      HapticFeedback.heavyImpact();
    }

    // Convert custom workout exercises to QuickStartExercise objects with configured sets
    final exercises = workout.exercises.map((customExercise) {
      final sets = customExercise.sets.map((customSet) => 
        ExerciseSet(weight: customSet.weight, reps: customSet.reps)
      ).toList();
      
      return QuickStartExercise(title: customExercise.name, sets: sets);
    }).toList();

    // Set the exercises and workout name in the overlay
    QuickStartOverlay.selectedExercises = exercises;
    QuickStartOverlay.customWorkoutName = workout.name;
    
    // Navigate back to the main app and open QuickStart properly
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // Use the overlay system to open QuickStart properly with slight delay
    Future.delayed(const Duration(milliseconds: 50), () {
      QuickStartOverlay.openQuickStart(context);
    });
  }

  Future<void> _deleteWorkout(CustomWorkout workout) async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Workout'),
          content: Text('Are you sure you want to delete "${workout.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed == true) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        await CustomWorkoutService.deleteCustomWorkout(workout.id);
        if (mounted) {
          _loadSavedWorkouts();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.trashCan,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${workout.name} deleted successfully',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error deleting workout: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editWorkout(CustomWorkout workout) async {
    if (!mounted) return;

    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => CustomWorkoutConfigurationPage(
          exerciseNames: workout.exerciseNames,
          existingWorkout: workout,
        ),
      ),
    );

    if (mounted && result == true) {
      _loadSavedWorkouts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Custom Workouts',
          style: themeService.currentTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: themeService.currentTheme.appBarTheme.foregroundColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Create New Workout Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _browseExercises,
                        icon: FaIcon(
                          FontAwesomeIcons.plus, 
                          color: themeService.isDarkMode ? Colors.black : Colors.white, 
                          size: 18,
                        ),
                        label: Text(
                          'Create New Workout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: themeService.isDarkMode ? Colors.black : Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeService.isDarkMode ? Colors.white : Colors.black,
                          foregroundColor: themeService.isDarkMode ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Saved Workouts
                  if (_savedWorkouts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.dumbbell,
                            size: 80,
                            color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No custom workouts yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first custom workout to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeService.isDarkMode ? Colors.grey.shade500 : Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _savedWorkouts.length,
                      itemBuilder: (context, index) {
                        final workout = _savedWorkouts[index];
                        
                        // Show slid state with delete button
                        if (_firstSlideCompleted.contains(workout.id)) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: IntrinsicHeight(
                              child: Stack(
                                children: [
                                  // Delete button background
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 20),
                                        child: GestureDetector(
                                          onTap: () => _deleteWorkout(workout),
                                          child: const FaIcon(
                                            FontAwesomeIcons.trashCan,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Main content (slides over the delete button)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOutQuart,
                                    transform: Matrix4.translationValues(-80, 0, 0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: themeService.isDarkMode 
                                            ? const Color(0xFF2A2A2A)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: themeService.isDarkMode 
                                                ? Colors.black.withValues(alpha: 0.3)
                                                : Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _firstSlideCompleted.remove(workout.id);
                                          });
                                          _startCustomWorkout(workout);
                                        },
                                        onLongPress: () {
                                          setState(() {
                                            _firstSlideCompleted.remove(workout.id);
                                          });
                                          _showWorkoutDetails(workout);
                                        },
                                        borderRadius: BorderRadius.circular(15),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              // Leading icon
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  borderRadius: BorderRadius.circular(25),
                                                ),
                                                child: FaIcon(
                                                  FontAwesomeIcons.dumbbell,
                                                  color: themeService.currentTheme.textTheme.titleMedium?.color,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              // Title and exercise tags
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // Title row with exercise count
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            workout.name,
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                              color: themeService.currentTheme.textTheme.titleMedium?.color,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${workout.exerciseNames.length} exercises',
                                                          style: TextStyle(
                                                            color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Flexible(
                                                      child: Wrap(
                                                        spacing: 6,
                                                        runSpacing: 4,
                                                        children: workout.exerciseNames.take(3).map((exercise) {
                                                          return Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              exercise,
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList()
                                                          ..addAll(workout.exerciseNames.length > 3 
                                                            ? [Container(
                                                                padding: const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2,
                                                                ),
                                                                decoration: BoxDecoration(
                                                                  color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                child: Text(
                                                                  '+${workout.exerciseNames.length - 3} more',
                                                                  style: TextStyle(
                                                                    fontSize: 10,
                                                                    color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                                                  ),
                                                                ),
                                                              )]
                                                            : []),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Pin button
                                              GestureDetector(
                                                onTap: () async {
                                                  if (!mounted) return;
                                                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                                                  try {
                                                    await CustomWorkoutService.toggleWorkoutPin(
                                                      workout.id,
                                                      !workout.pinned,
                                                    );
                                                    if (mounted) {
                                                      // Update the local workout state instead of reloading
                                                      setState(() {
                                                        final workoutIndex = _savedWorkouts.indexWhere((w) => w.id == workout.id);
                                                        if (workoutIndex != -1) {
                                                          _savedWorkouts[workoutIndex] = CustomWorkout(
                                                            id: workout.id,
                                                            name: workout.name,
                                                            exercises: workout.exercises,
                                                            createdAt: workout.createdAt,
                                                            userId: workout.userId,
                                                            pinned: !workout.pinned,
                                                            description: workout.description,
                                                          );
                                                        }
                                                      });
                                                      scaffoldMessenger.showSnackBar(
                                                        SnackBar(
                                                          content: Row(
                                                            children: [
                                                              Icon(
                                                                workout.pinned 
                                                                    ? Icons.push_pin_outlined 
                                                                    : Icons.push_pin,
                                                                color: Colors.white,
                                                                size: 20,
                                                              ),
                                                              const SizedBox(width: 12),
                                                              Expanded(
                                                                child: Text(
                                                                  workout.pinned 
                                                                      ? '${workout.name} unpinned from Quick Start' 
                                                                      : '${workout.name} pinned to Quick Start',
                                                                  style: const TextStyle(
                                                                    fontSize: 14,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          backgroundColor: Colors.black87,
                                                          behavior: SnackBarBehavior.floating,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          margin: const EdgeInsets.all(16),
                                                          duration: const Duration(seconds: 2),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (mounted) {
                                                      scaffoldMessenger.showSnackBar(
                                                        SnackBar(
                                                          content: Text('Error: ${e.toString()}'),
                                                          backgroundColor: Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  child: Icon(
                                                    workout.pinned 
                                                        ? Icons.push_pin 
                                                        : Icons.push_pin_outlined,
                                                    color: workout.pinned 
                                                        ? themeService.currentTheme.textTheme.titleMedium?.color
                                                        : (themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey),
                                                    size: 24,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        // Normal dismissible for first slide
                        return Dismissible(
                          key: Key(workout.id),
                          direction: DismissDirection.endToStart,
                          dismissThresholds: const {
                            DismissDirection.endToStart: 0.25,
                          },
                          movementDuration: const Duration(milliseconds: 500),
                          resizeDuration: const Duration(milliseconds: 500),
                          confirmDismiss: (direction) async {
                            setState(() {
                              _firstSlideCompleted.add(workout.id);
                            });
                            
                            Future.delayed(const Duration(seconds: 5), () {
                              if (mounted && _firstSlideCompleted.contains(workout.id)) {
                                setState(() {
                                  _firstSlideCompleted.remove(workout.id);
                                });
                              }
                            });
                            
                            return false;
                          },
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const FaIcon(
                              FontAwesomeIcons.trashCan,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: themeService.isDarkMode 
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: themeService.isDarkMode 
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () => _startCustomWorkout(workout),
                              onLongPress: () => _showWorkoutDetails(workout),
                              borderRadius: BorderRadius.circular(15),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Leading icon
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: FaIcon(
                                        FontAwesomeIcons.dumbbell,
                                        color: themeService.currentTheme.textTheme.titleMedium?.color,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Title and exercise tags
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Title row with exercise count
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  workout.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: themeService.currentTheme.textTheme.titleMedium?.color,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${workout.exerciseNames.length} exercises',
                                                style: TextStyle(
                                                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: workout.exerciseNames.take(3).map((exercise) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  exercise,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                                  ),
                                                ),
                                              );
                                            }).toList()
                                              ..addAll(workout.exerciseNames.length > 3 
                                                ? [Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '+${workout.exerciseNames.length - 3} more',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                                      ),
                                                    ),
                                                  )]
                                                : []),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Pin button
                                    GestureDetector(
                                      onTap: () async {
                                        if (!mounted) return;
                                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                                        try {
                                          await CustomWorkoutService.toggleWorkoutPin(
                                            workout.id,
                                            !workout.pinned,
                                          );
                                          if (mounted) {
                                            // Update the local workout state instead of reloading
                                            setState(() {
                                              final workoutIndex = _savedWorkouts.indexWhere((w) => w.id == workout.id);
                                              if (workoutIndex != -1) {
                                                _savedWorkouts[workoutIndex] = CustomWorkout(
                                                  id: workout.id,
                                                  name: workout.name,
                                                  exercises: workout.exercises,
                                                  createdAt: workout.createdAt,
                                                  userId: workout.userId,
                                                  pinned: !workout.pinned,
                                                  description: workout.description,
                                                );
                                              }
                                            });
                                            scaffoldMessenger.showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    Icon(
                                                      workout.pinned 
                                                          ? Icons.push_pin_outlined 
                                                          : Icons.push_pin,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        workout.pinned 
                                                            ? '${workout.name} unpinned from Quick Start' 
                                                            : '${workout.name} pinned to Quick Start',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor: Colors.black87,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                margin: const EdgeInsets.all(16),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            scaffoldMessenger.showSnackBar(
                                              SnackBar(
                                                content: Text('Error: ${e.toString()}'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          workout.pinned 
                                              ? Icons.push_pin 
                                              : Icons.push_pin_outlined,
                                          color: workout.pinned 
                                              ? themeService.currentTheme.textTheme.titleMedium?.color
                                              : (themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}