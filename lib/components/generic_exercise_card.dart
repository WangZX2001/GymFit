import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/models/editable_workout_models.dart' hide DecimalTextInputFormatter;
import 'package:gymfit/components/exercise_set_row.dart' show ExerciseSetRow;
import 'package:gymfit/services/theme_service.dart';

// Generic interface for exercise data
abstract class ExerciseData {
  String get title;
  List<dynamic> get sets;
  bool get isChecked;
}

// Adapter for QuickStartExercise
class QuickStartExerciseAdapter implements ExerciseData {
  final QuickStartExercise exercise;
  
  QuickStartExerciseAdapter(this.exercise);
  
  @override
  String get title => exercise.title;
  
  @override
  List<dynamic> get sets => exercise.sets;
  
  @override
  bool get isChecked => exercise.sets.every((set) => set.isChecked);
}

// Adapter for EditableExercise
class EditableExerciseAdapter implements ExerciseData {
  final EditableExercise exercise;
  
  EditableExerciseAdapter(this.exercise);
  
  @override
  String get title => exercise.title;
  
  @override
  List<dynamic> get sets => exercise.sets;
  
  @override
  bool get isChecked => exercise.sets.every((set) => set.isChecked);
}

class GenericExerciseCard extends StatefulWidget {
  final ExerciseData exercise;
  final int exerciseIndex;
  final bool preventAutoFocus;
  final bool isCollapsed;
  final bool isNewlyAdded;
  final Function(ExerciseData) onRemoveExercise;
  final Function(ExerciseData, dynamic) onRemoveSet;
  final Function(ExerciseData, dynamic, double) onWeightChanged;
  final Function(ExerciseData, dynamic, int) onRepsChanged;
  final Function(ExerciseData, dynamic, bool) onSetCheckedChanged;
  final Function(ExerciseData, bool) onAllSetsCheckedChanged;
  final VoidCallback onAddSet;
  final VoidCallback onRequestReorderMode;
  final Function(bool)? onFocusChanged;

  const GenericExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.preventAutoFocus,
    this.isCollapsed = false,
    this.isNewlyAdded = false,
    required this.onRemoveExercise,
    required this.onRemoveSet,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onSetCheckedChanged,
    required this.onAllSetsCheckedChanged,
    required this.onAddSet,
    required this.onRequestReorderMode,
    this.onFocusChanged,
  });

  @override
  State<GenericExerciseCard> createState() => _GenericExerciseCardState();
}

class _GenericExerciseCardState extends State<GenericExerciseCard>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  AnimationController? _unfoldAnimationController;
  Animation<double>? _contentHeightAnimation;
  Animation<double>? _opacityAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _unfoldContentHeightAnimation;
  bool _isAnimatingToCollapsed = false;
  bool _isUnfolding = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animation for the content height (sets and add button)
    _contentHeightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    // Animation for the overall opacity
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Animation for the slide-in effect
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuart),
      ),
    );

    // Separate animation controller for unfolding
    _unfoldAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animation for unfolding content height
    _unfoldContentHeightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _unfoldAnimationController!,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    // Start animation if this is a newly added exercise
    if (widget.isNewlyAdded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animationController?.forward();
      });
    } else {
      // For existing exercises, start fully expanded
      _animationController?.value = 1.0;
      _unfoldAnimationController?.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(GenericExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle transition to reorder mode (folding animation)
    if (!oldWidget.isCollapsed &&
        widget.isCollapsed &&
        !_isAnimatingToCollapsed) {
      _isAnimatingToCollapsed = true;
      // Use a more deliberate reverse animation
      _animationController
          ?.animateTo(
            0.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInQuart,
          )
          .then((_) {
            _isAnimatingToCollapsed = false;
          });
    }

    // Handle transition out of reorder mode
    if (oldWidget.isCollapsed && !widget.isCollapsed) {
      _isAnimatingToCollapsed = false;

      // If this exercise is marked as newly added, use the full entrance animation
      if (widget.isNewlyAdded) {
        _animationController?.value = 0.0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animationController?.forward();
        });
      } else {
        // Otherwise use the unfolding animation
        _isUnfolding = true;
        _unfoldAnimationController?.value = 0.0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _unfoldAnimationController?.forward().then((_) {
            _isUnfolding = false;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _unfoldAnimationController?.dispose();
    super.dispose();
  }

  void _showBottomSheetMenu(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeService.currentTheme.cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Menu items
            ListTile(
              leading: Icon(
                Icons.drag_handle,
                color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey[700],
                size: 24,
              ),
              title: Text(
                'Reorder Exercises',
                style: TextStyle(
                  color: themeService.currentTheme.textTheme.titleMedium?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                widget.onRequestReorderMode();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Return a simple card if animations aren't ready yet
    if (_animationController == null ||
        _contentHeightAnimation == null ||
        _opacityAnimation == null ||
        _slideAnimation == null ||
        _unfoldAnimationController == null ||
        _unfoldContentHeightAnimation == null) {
      return _buildCardContent();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _animationController!,
        _unfoldAnimationController!,
      ]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation!,
          child: FadeTransition(
            opacity: _opacityAnimation!,
            child: _buildCardContent(),
          ),
        );
      },
    );
  }

  Widget _buildCardContent() {
    return Dismissible(
      key: Key('exercise_${widget.exercise.title}_${widget.exerciseIndex}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24), // More space for icon
        // Remove margin and borderRadius for flat look
        color: Colors.red, // Fill full width/height
        child: const FaIcon(
          FontAwesomeIcons.trash,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (direction) => widget.onRemoveExercise(widget.exercise),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: widget.isCollapsed ? const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0) : EdgeInsets.zero,
        child: Builder(
          builder: (context) {
            final themeService = Provider.of<ThemeService>(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row - always visible
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: widget.isCollapsed ? 0 : 8), // Adjust padding for reorder mode
                        child: Text(
                          widget.exercise.title,
                          style: TextStyle(
                            fontSize: widget.isCollapsed ? 16 : 16, // Same font size in reorder mode
                            fontWeight: FontWeight.bold,
                            height: widget.isCollapsed ? 1.05 : 1.0, // Minimal spacing in reorder mode
                          ),
                        ),
                      ),
                    ),
                    if (widget.isCollapsed)
                      Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.drag_handle,
                          color: Colors.grey.shade600,
                          size: 22,
                        ),
                      )
                    else
                      Builder(
                        builder: (context) {
                          final themeService = Provider.of<ThemeService>(context);
                          return GestureDetector(
                            onTap: () {
                              _showBottomSheetMenu(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.more_horiz,
                                color: themeService.currentTheme.textTheme.titleMedium?.color,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                // No SizedBox or Padding here for ultra-tight layout
                // Animated content that unfolds/folds
                if (!widget.isCollapsed || _isAnimatingToCollapsed) ...[
                  if (_contentHeightAnimation != null)
                    SizeTransition(
                      sizeFactor: _isUnfolding ? _unfoldContentHeightAnimation! : _contentHeightAnimation!,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth;
                          final isSmallScreen = availableWidth < 350;
                          final spacing = isSmallScreen ? 6.0 : 8.0;
                          final minCheckboxSize = 40.0;
                          
                          return Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: isSmallScreen ? 35 : 45,
                                    child: Center(
                                      child: Text(
                                        'Set',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 16 : 18,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: spacing),
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
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Center(
                                      child: Checkbox(
                                        value: widget.exercise.isChecked,
                                        tristate: true,
                                        fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Colors.green;
                                          }
                                          return Colors.grey.shade300;
                                        }),
                                        onChanged: (val) {
                                          HapticFeedback.lightImpact();
                                          widget.onAllSetsCheckedChanged(widget.exercise, val ?? false);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  // Exercise sets - also animated
                  if (_contentHeightAnimation != null)
                    SizeTransition(
                      sizeFactor: _contentHeightAnimation!,
                      child: Column(
                        children: widget.exercise.sets.asMap().entries.map((entry) {
                          int setIndex = entry.key;
                          dynamic exerciseSet = entry.value;
                          return _buildSetRow(exerciseSet, setIndex);
                        }).toList(),
                      ),
                    ),
                ],
                // Add set button - also animated
                if ((!widget.isCollapsed || _isAnimatingToCollapsed) && _contentHeightAnimation != null)
                  SizeTransition(
                    sizeFactor: _contentHeightAnimation!,
                    child: Builder(
                      builder: (context) {
                        final themeService = Provider.of<ThemeService>(context);
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onAddSet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeService.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                              foregroundColor: themeService.isDarkMode ? Colors.white : Colors.grey.shade600,
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
                            child: FaIcon(
                              FontAwesomeIcons.plus,
                              color: themeService.isDarkMode ? Colors.white : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSetRow(dynamic exerciseSet, int setIndex) {
    // Use the unified ExerciseSetRow component for both types
    return ExerciseSetRow(
      exerciseSet: exerciseSet,
      setIndex: setIndex,
      preventAutoFocus: widget.preventAutoFocus,
      onWeightChanged: (weight) => widget.onWeightChanged(widget.exercise, exerciseSet, weight),
      onRepsChanged: (reps) => widget.onRepsChanged(widget.exercise, exerciseSet, reps),
      onCheckedChanged: (checked) => widget.onSetCheckedChanged(widget.exercise, exerciseSet, checked),
      onDismissed: () => widget.onRemoveSet(widget.exercise, exerciseSet),
    );
  }


} 