import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/pages/workout/workout_summary_page.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class FinishWorkoutButton extends StatelessWidget {
  final List<QuickStartExercise> completedExercises;
  final Duration workoutDuration;
  final String? customWorkoutName;

  const FinishWorkoutButton({
    super.key,
    required this.completedExercises,
    required this.workoutDuration,
    this.customWorkoutName,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonFontSize = 14.0;
        final buttonPadding = const EdgeInsets.symmetric(vertical: 8);

        // Define colors based on theme
        final backgroundColor = isDarkMode 
            ? Colors.green.shade600.withValues(alpha: 0.25)
            : Colors.green.withValues(alpha: 0.15);
        final textColor = isDarkMode 
            ? Colors.green.shade300
            : Colors.green.shade700;
        final iconColor = isDarkMode 
            ? Colors.green.shade300
            : Colors.green.shade700;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: OutlinedButton.icon(
                  onPressed: () => _handleFinishWorkout(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: textColor,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: buttonPadding,
                  ),
                  icon: FaIcon(
                    FontAwesomeIcons.flagCheckered,
                    color: iconColor,
                    size: buttonFontSize * 0.8,
                  ),
                  label: Text(
                    'Finish',
                    style: TextStyle(
                      color: textColor,
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleFinishWorkout(BuildContext context) {
    // Add haptic feedback when finish button is pressed
    HapticFeedback.heavyImpact();

    // Navigate to workout summary page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryPage(
          completedExercises: completedExercises,
          workoutDuration: workoutDuration,
          customWorkoutName: customWorkoutName,
        ),
      ),
    );
  }
} 