import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/exercise_set.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/components/exercise_set_row.dart';

class ExerciseCard extends StatelessWidget {
  final QuickStartExercise exercise;
  final int exerciseIndex;
  final bool preventAutoFocus;
  final Function(QuickStartExercise) onRemoveExercise;
  final Function(QuickStartExercise, ExerciseSet) onRemoveSet;
  final Function(QuickStartExercise, ExerciseSet, double) onWeightChanged;
  final Function(QuickStartExercise, ExerciseSet, int) onRepsChanged;
  final Function(QuickStartExercise, ExerciseSet, bool) onSetCheckedChanged;
  final Function(QuickStartExercise, bool) onAllSetsCheckedChanged;
  final VoidCallback onAddSet;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.preventAutoFocus,
    required this.onRemoveExercise,
    required this.onRemoveSet,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onSetCheckedChanged,
    required this.onAllSetsCheckedChanged,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('exercise_${exercise.title}_$exerciseIndex'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const FaIcon(
          FontAwesomeIcons.trash,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) => onRemoveExercise(exercise),
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 350;
                final cardPadding = isSmallScreen ? 6.0 : 8.0;

                return Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            exercise.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final isSmallScreen = availableWidth < 350;
                              final spacing = isSmallScreen ? 6.0 : 8.0;
                              final minCheckboxSize = 48.0;

                              return Row(
                                children: [
                                  // Set number - fixed small width
                                  SizedBox(
                                    width: isSmallScreen ? 35 : 45,
                                    child: Center(
                                      child: Text(
                                        'Set',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 14 : 16,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: spacing),
                                  // Previous - flexible
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: Text(
                                        'Previous',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 14 : 16,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: spacing),
                                  // Weight - flexible
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: isSmallScreen ? 45 : 60,
                                          minWidth: 40,
                                        ),
                                        child: Text(
                                          'Kg',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 14 : 16,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: spacing),
                                  // Reps - flexible
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: isSmallScreen ? 45 : 60,
                                          minWidth: 40,
                                        ),
                                        child: Text(
                                          'Reps',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 14 : 16,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: spacing),
                                  // Checkbox - fixed minimum size
                                  SizedBox(
                                    width: minCheckboxSize,
                                    height: minCheckboxSize,
                                    child: Center(
                                      child: Checkbox(
                                        value: exercise.sets.every((set) => set.isChecked),
                                        tristate: true,
                                        fillColor: WidgetStateProperty.resolveWith<Color>(
                                          (Set<WidgetState> states) {
                                            if (states.contains(WidgetState.selected)) {
                                              return Colors.green;
                                            }
                                            return Colors.grey.shade300;
                                          },
                                        ),
                                        onChanged: (val) {
                                          HapticFeedback.lightImpact();
                                          onAllSetsCheckedChanged(exercise, val ?? false);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                      ...exercise.sets.asMap().entries.map((entry) {
                        int setIndex = entry.key;
                        ExerciseSet exerciseSet = entry.value;
                        return ExerciseSetRow(
                          exerciseSet: exerciseSet,
                          setIndex: setIndex,
                          preventAutoFocus: preventAutoFocus,
                          onWeightChanged: (weight) => onWeightChanged(exercise, exerciseSet, weight),
                          onRepsChanged: (reps) => onRepsChanged(exercise, exerciseSet, reps),
                          onCheckedChanged: (checked) => onSetCheckedChanged(exercise, exerciseSet, checked),
                          onDismissed: () => onRemoveSet(exercise, exerciseSet),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAddSet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade600,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide.none,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    side: BorderSide.none,
                  ),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.plus,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 