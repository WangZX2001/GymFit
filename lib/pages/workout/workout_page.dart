import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:gymfit/pages/workout/custom_workout_page.dart';
import 'package:gymfit/pages/workout/recommended_training_page.dart';
import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

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

  /// Handle quick start button press with confirmation dialog if needed
  void _handleQuickStart(BuildContext context) {
    if (_isQuickStartInProgress()) {
      // Show confirmation dialog and handle result in callback
      _showQuickStartConfirmationDialog(context).then((shouldStartNew) {
        if (shouldStartNew) {
          // Add haptic feedback when starting new workout after confirmation
          HapticFeedback.heavyImpact();
          // Clear existing workout
          QuickStartOverlay.selectedExercises.clear();
          QuickStartOverlay.resetTimer();
          
          // Clear any existing custom workout name for fresh start
          QuickStartOverlay.customWorkoutName = null;
          // Open quick start after confirmation with slight delay for more deliberate feel
          Future.delayed(const Duration(milliseconds: 50), () {
            // ignore: use_build_context_synchronously
            QuickStartOverlay.openQuickStart(context);
          });
        }
      });
    } else {
      // Add haptic feedback when starting new workout
      HapticFeedback.heavyImpact();
      // No confirmation needed, start directly with slight delay for more deliberate feel
      QuickStartOverlay.customWorkoutName = null;
      Future.delayed(const Duration(milliseconds: 50), () {
        QuickStartOverlay.openQuickStart(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildWorkoutCard(
                'Quick Start',
                'lib/images/quickStart.jpg',
                () => _handleQuickStart(context),
                alignment: Alignment.bottomCenter,
              ),
              _buildWorkoutCard(
                'Exercise Information',
                'lib/images/exerciseInformation.jpg',
                () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (context) => const ExerciseInformationPage(),
                    ),
                  );
                },
              ),
              Column(
                children: [
                  _buildWorkoutCard(
                    'Recommended Training',
                    'lib/images/reccomendedTraining.jpg',
                    () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => const RecommendedTrainingPage(),
                        ),
                      );
                    },
                    alignment: Alignment.bottomCenter,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'For recommended training, a personalized workout plan automatically generated based on your body info, fitness goals, and experience level.',
                      style: TextStyle(
                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              _buildWorkoutCard(
                'Custom Workout',
                'lib/images/customWorkout.jpg',
                () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (context) => const CustomWorkoutPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(
    String title,
    String imagePath,
    VoidCallback onTap, {
    Alignment alignment = Alignment.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              alignment: alignment,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(77),
                  Colors.black.withAlpha(128),
                ],
              ),
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
