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
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final buttonFontSize = screenWidth < 350 ? 16.0 : 18.0;
                      final buttonPadding = screenWidth < 350
                          ? const EdgeInsets.symmetric(vertical: 12)
                          : const EdgeInsets.symmetric(vertical: 16);

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleAddExercises(context),
                          icon: FaIcon(
                            FontAwesomeIcons.plus,
                            color: themeService.isDarkMode ? Colors.black : Colors.white,
                          ),
                          label: Text(
                            'Add Exercises',
                            style: TextStyle(
                              color: themeService.isDarkMode ? Colors.black : Colors.white,
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeService.isDarkMode ? Colors.white : Colors.black,
                            shape: const StadiumBorder(),
                            padding: buttonPadding,
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