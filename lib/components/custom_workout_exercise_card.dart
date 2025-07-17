import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/components/custom_workout_set_row.dart';
import 'package:gymfit/services/custom_workout_configuration_state_manager.dart';

class CustomWorkoutExerciseCard extends StatelessWidget {
  final ConfigExercise exercise;
  final int index;
  final bool isCollapsed;
  final bool preventAutoFocus;
  final VoidCallback onRequestReorderMode;
  final VoidCallback onAddSet;
  final Function(ConfigSet) onRemoveSet;
  final VoidCallback onWeightChanged;
  final VoidCallback onRepsChanged;

  const CustomWorkoutExerciseCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.isCollapsed,
    required this.preventAutoFocus,
    required this.onRequestReorderMode,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                      if (isCollapsed)
                        // Drag handle for reorder mode
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.drag_handle,
                            color: Colors.grey,
                            size: 20,
                          ),
                        )
                      else
                        // 3-dots menu for normal mode
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          onSelected: (value) {
                            if (value == 'reorder') {
                              onRequestReorderMode();
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.grey[100],
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.2),
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'reorder',
                              height: 48,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.drag_handle,
                                    color: Colors.grey[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Reorder',
                                    style: TextStyle(
                                      color: Colors.grey[900],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            final isSmallScreen = availableWidth < 350;
                            final spacing = isSmallScreen ? 6.0 : 8.0;
                            
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
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...exercise.sets.asMap().entries.map((entry) {
                      final setIndex = entry.key;
                      final set = entry.value;
                      return CustomWorkoutSetRow(
                        key: Key('${exercise.title}_${set.id}'),
                        set: set,
                        setIndex: setIndex,
                        preventAutoFocus: preventAutoFocus,
                        onWeightChanged: onWeightChanged,
                        onRepsChanged: onRepsChanged,
                        onRemoveSet: () => onRemoveSet(set),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        ),
        if (!isCollapsed)
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
              child: const FaIcon(FontAwesomeIcons.plus, color: Colors.grey),
            ),
          ),
      ],
    );
  }
} 