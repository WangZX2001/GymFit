import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:gymfit/pages/workout/custom_workout_configuration_page.dart';
import 'package:gymfit/pages/workout/quick_start_page.dart';
import 'package:gymfit/services/custom_workout_service.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/components/quick_start_overlay.dart';

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
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.dumbbell,
                        color: Colors.black,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          workout.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.grey),
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
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            workout.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
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
                        color: Colors.white,
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
                                          color: Colors.grey.shade200,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${setIndex + 1}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${set.weight} kg × ${set.reps} reps',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
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
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Workout',
                        style: TextStyle(
                          color: Colors.white,
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

  Future<void> _startCustomWorkout(CustomWorkout workout) async {
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
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // Use the overlay system to open QuickStart properly
    QuickStartOverlay.openQuickStart(context);
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
                  const Icon(
                    Icons.delete,
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Custom Workouts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSavedWorkouts,
              child: SingleChildScrollView(
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
                          icon: const Icon(Icons.add, color: Colors.white, weight: 900),
                          label: const Text(
                            'Create New Workout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
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
                            Icon(
                              Icons.fitness_center,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No custom workouts yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first custom workout to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
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
                                            child: const Icon(
                                              Icons.delete,
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
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
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
                                                  child: const FaIcon(
                                                    FontAwesomeIcons.dumbbell,
                                                    color: Colors.black,
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
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 16,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${workout.exerciseNames.length} exercises',
                                                            style: TextStyle(
                                                              color: Colors.grey.shade600,
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
                                                                color: Colors.grey.shade200,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                exercise,
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors.grey.shade700,
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
                                                                    color: Colors.grey.shade300,
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                  child: Text(
                                                                    '+${workout.exerciseNames.length - 3} more',
                                                                    style: TextStyle(
                                                                      fontSize: 10,
                                                                      color: Colors.grey.shade700,
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
                                                      color: Colors.black,
                                                      size: 20,
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
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
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
                                        child: const FaIcon(
                                          FontAwesomeIcons.dumbbell,
                                          color: Colors.black,
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
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${workout.exerciseNames.length} exercises',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
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
                                                    color: Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    exercise,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey.shade700,
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
                                                        color: Colors.grey.shade300,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        '+${workout.exerciseNames.length - 3} more',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey.shade700,
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
                                            color: Colors.black,
                                            size: 20,
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
            ),
    );
  }
}