import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/packages/exercise_information_repository/exercise_information_repository.dart';
import 'package:gymfit/pages/workout/exercise_description_page.dart';

class MainExercisesPage extends StatefulWidget {
  const MainExercisesPage({super.key});

  @override
  State<MainExercisesPage> createState() => _MainExercisesPageState();
}

class _MainExercisesPageState extends State<MainExercisesPage> {
  List<ExerciseFrequency> exerciseFrequencies = [];
  List<ExerciseInformation> allExerciseInfo = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExerciseFrequencies();
  }

  Future<void> _loadExerciseFrequencies() async {
    try {
      // Load both workout data and exercise information
      final futures = await Future.wait([
        WorkoutService.getUserWorkouts(),
        ExerciseInformationRepository().getAllExerciseInformation(),
      ]);
      
      final workouts = futures[0] as List<Workout>;
      allExerciseInfo = futures[1] as List<ExerciseInformation>;
      
      final frequencyMap = <String, int>{};
      
      // Count exercise frequencies
      for (final workout in workouts) {
        for (final exercise in workout.exercises) {
          final exerciseName = exercise.title;
          frequencyMap[exerciseName] = (frequencyMap[exerciseName] ?? 0) + 1;
        }
      }
      
      // Convert to list and sort by frequency (descending)
      final frequencies = frequencyMap.entries
          .map((entry) => ExerciseFrequency(
                name: entry.key,
                frequency: entry.value,
              ))
          .toList()
        ..sort((a, b) => b.frequency.compareTo(a.frequency));
      
      if (mounted) {
        setState(() {
          exerciseFrequencies = frequencies;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exercise data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Main Exercises', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.black),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : exerciseFrequencies.isEmpty
                ? _buildEmptyState()
                : _buildExercisesList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.dumbbell,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start working out to see your exercise statistics!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              FaIcon(
                FontAwesomeIcons.dumbbell,
                size: 48,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                'Your Most Performed Exercises',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Ranked by frequency',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // Exercise List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: exerciseFrequencies.length,
            itemBuilder: (context, index) {
              final exercise = exerciseFrequencies[index];
              final rank = index + 1;
              
              return GestureDetector(
                onTap: () => _navigateToExerciseDescription(exercise.name),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getRankColor(rank),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          rank.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Exercise Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${exercise.frequency} ${exercise.frequency == 1 ? 'time' : 'times'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    

                  ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade600; // Gold
      case 2:
        return Colors.grey.shade500; // Silver
      case 3:
        return Colors.brown.shade400; // Bronze
      default:
        return Colors.blue.shade600; // Default blue
    }
  }

  void _navigateToExerciseDescription(String exerciseName) {
    // Find the exercise information from the repository
    final exerciseInfo = allExerciseInfo.firstWhere(
      (info) => info.title.toLowerCase() == exerciseName.toLowerCase(),
      orElse: () => ExerciseInformation(
        title: exerciseName,
        icon: 'fitness_center',
        mainMuscle: 'Unknown',
        secondaryMuscle: '',
        experienceLevel: 'Beginner',
        equipment: 'Various',
        howTo: 'Exercise instructions will be available soon.',
        description: 'This is one of your most frequently performed exercises.',
        videoUrl: null,
        proTips: ['Follow proper form.', 'Start with appropriate weight.'],
      ),
    );

    // Navigate to the exercise description page
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ExerciseDescriptionPage(
          title: exerciseInfo.title,
          description: exerciseInfo.description,
          videoUrl: exerciseInfo.videoUrl,
          mainMuscle: exerciseInfo.mainMuscle,
          secondaryMuscle: exerciseInfo.secondaryMuscle,
          proTips: exerciseInfo.proTips,
          experienceLevel: exerciseInfo.experienceLevel,
          howTo: exerciseInfo.howTo,
          onAdd: () {
            // This callback is required but not used in this context
          },
        ),
      ),
    );
  }
}

class ExerciseFrequency {
  final String name;
  final int frequency;

  ExerciseFrequency({
    required this.name,
    required this.frequency,
  });
} 