import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:gymfit/models/exercise_set.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class AddExerciseButton extends StatelessWidget {
  final bool isAnyFieldFocused;
  final bool isEditingWorkoutName;
  final VoidCallback onExercisesAdded;
  final Function(List<QuickStartExercise>) onExercisesLoaded;

  const AddExerciseButton({
    super.key,
    required this.isAnyFieldFocused,
    required this.isEditingWorkoutName,
    required this.onExercisesAdded,
    required this.onExercisesLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutQuart,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        opacity: (isAnyFieldFocused || isEditingWorkoutName) ? 0.0 : 1.0,
        child: (isAnyFieldFocused || isEditingWorkoutName)
            ? const SizedBox.shrink()
            : Column(
                children: [
                  const SizedBox(height: 0),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final buttonFontSize = 14.0;
                      final buttonPadding = const EdgeInsets.symmetric(vertical: 8);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _handleAddExercises(context),
                            icon: FaIcon(
                              FontAwesomeIcons.plus,
                              color: themeService.isDarkMode ? Colors.black : Colors.white,
                              size: buttonFontSize * 0.8,
                            ),
                            label: Text(
                              'Add Exercises',
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w900,
                                color: themeService.isDarkMode ? Colors.black : Colors.white,
                              ),
                            ),
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
                              padding: buttonPadding,
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

  Future<void> _handleAddExercises(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final result = await navigator.push<List<String>>(
      MaterialPageRoute(
        builder: (ctx) => const ExerciseInformationPage(
          isSelectionMode: true,
        ),
      ),
    );

    if (result != null) {
      onExercisesAdded();

      // Create new exercises with prefilled data
      final List<QuickStartExercise> newExercises = [];

      for (final title in result) {
        try {
          // Try to get previous exercise data
          final previousData = await WorkoutService.getLastExerciseData(title);

          List<ExerciseSet> sets;
          if (previousData != null && previousData['sets'] != null) {
            // Create sets based on previous workout data
            final previousSetsData = previousData['sets'] as List<dynamic>;

            sets = previousSetsData.map((setData) {
              final weight = (setData['weight'] as num?)?.toDouble() ?? 0.0;
              final reps = (setData['reps'] as int?) ?? 0;
              return ExerciseSet(
                weight: weight,
                reps: reps,
                isWeightPrefilled: true,
                isRepsPrefilled: true,
                previousWeight: weight,
                previousReps: reps,
              );
            }).toList();
          } else {
            // No previous data, use default
            sets = [ExerciseSet()];
          }

          newExercises.add(
            QuickStartExercise(
              title: title,
              sets: sets,
            ),
          );
        } catch (e) {
          // If there's an error fetching data, use default
          newExercises.add(
            QuickStartExercise(
              title: title,
            ),
          );
        }
      }

      onExercisesLoaded(newExercises);
    }
  }
} 