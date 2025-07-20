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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final buttonFontSize = screenWidth < 350 ? 16.0 : 18.0;
        final buttonPadding = screenWidth < 350
            ? const EdgeInsets.symmetric(vertical: 12)
            : const EdgeInsets.symmetric(vertical: 16);

        return SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: OutlinedButton.icon(
                onPressed: () => _handleFinishWorkout(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: themeService.isDarkMode 
                      ? Colors.grey.shade800.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.9),
                  foregroundColor: themeService.isDarkMode ? Colors.white : Colors.black,
                  side: BorderSide(
                    color: themeService.isDarkMode 
                        ? Colors.grey.shade600.withValues(alpha: 0.8)
                        : Colors.grey.shade300.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: buttonPadding,
                ),
                icon: FaIcon(
                  FontAwesomeIcons.flagCheckered,
                  color: themeService.isDarkMode ? Colors.white : Colors.black,
                  size: buttonFontSize * 0.8,
                ),
                label: Text(
                  'Finish',
                  style: TextStyle(
                    color: themeService.isDarkMode ? Colors.white : Colors.black,
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.w900,
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