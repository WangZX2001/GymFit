import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/exercise_set.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/components/exercise_set_row.dart';

class ExerciseCard extends StatefulWidget {
  final QuickStartExercise exercise;
  final int exerciseIndex;
  final bool preventAutoFocus;
  final bool isCollapsed;
  final bool isNewlyAdded;
  final Function(QuickStartExercise) onRemoveExercise;
  final Function(QuickStartExercise, ExerciseSet) onRemoveSet;
  final Function(QuickStartExercise, ExerciseSet, double) onWeightChanged;
  final Function(QuickStartExercise, ExerciseSet, int) onRepsChanged;
  final Function(QuickStartExercise, ExerciseSet, bool) onSetCheckedChanged;
  final Function(QuickStartExercise, bool) onAllSetsCheckedChanged;
  final VoidCallback onAddSet;
  final VoidCallback onRequestReorderMode;

  const ExerciseCard({
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
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard>
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
  void didUpdateWidget(ExerciseCard oldWidget) {
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
      onDismissed: (direction) => widget.onRemoveExercise(widget.exercise),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Card(
          color: widget.isCollapsed ? Colors.grey.shade50 : Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: widget.isCollapsed ? 2 : 1,
          shadowColor:
              widget.isCollapsed ? Colors.grey.shade400 : Colors.grey.shade300,
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
                        // Title row - always visible
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.exercise.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.isCollapsed)
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
                                    widget.onRequestReorderMode();
                                  }
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: Colors.grey[100],
                                elevation: 8,
                                shadowColor: Colors.black.withValues(
                                  alpha: 0.2,
                                ),
                                itemBuilder:
                                    (context) => [
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
                        // Animated content that unfolds/folds
                        if (!widget.isCollapsed || _isAnimatingToCollapsed) ...[
                          if (_contentHeightAnimation != null)
                            SizeTransition(
                              sizeFactor:
                                  _isUnfolding
                                      ? _unfoldContentHeightAnimation!
                                      : _contentHeightAnimation!,
                              child: Column(
                                children: [
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final availableWidth =
                                          constraints.maxWidth;
                                      final isSmallScreen =
                                          availableWidth < 350;
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
                                                  fontSize:
                                                      isSmallScreen ? 14 : 16,
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
                                                  fontSize:
                                                      isSmallScreen ? 14 : 16,
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
                                                  maxWidth:
                                                      isSmallScreen ? 45 : 60,
                                                  minWidth: 40,
                                                ),
                                                child: Text(
                                                  'Kg',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        isSmallScreen ? 14 : 16,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                                  maxWidth:
                                                      isSmallScreen ? 45 : 60,
                                                  minWidth: 40,
                                                ),
                                                child: Text(
                                                  'Reps',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        isSmallScreen ? 14 : 16,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                                value: widget.exercise.sets
                                                    .every(
                                                      (set) => set.isChecked,
                                                    ),
                                                tristate: true,
                                                fillColor:
                                                    WidgetStateProperty.resolveWith<
                                                      Color
                                                    >((
                                                      Set<WidgetState> states,
                                                    ) {
                                                      if (states.contains(
                                                        WidgetState.selected,
                                                      )) {
                                                        return Colors.green;
                                                      }
                                                      return Colors
                                                          .grey
                                                          .shade300;
                                                    }),
                                                onChanged: (val) {
                                                  HapticFeedback.lightImpact();
                                                  widget
                                                      .onAllSetsCheckedChanged(
                                                        widget.exercise,
                                                        val ?? false,
                                                      );
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
                            ),
                          // Exercise sets - also animated
                          if (_contentHeightAnimation != null)
                            SizeTransition(
                              sizeFactor: _contentHeightAnimation!,
                              child: Column(
                                children:
                                    widget.exercise.sets.asMap().entries.map((
                                      entry,
                                    ) {
                                      int setIndex = entry.key;
                                      ExerciseSet exerciseSet = entry.value;
                                      return ExerciseSetRow(
                                        exerciseSet: exerciseSet,
                                        setIndex: setIndex,
                                        preventAutoFocus:
                                            widget.preventAutoFocus,
                                        onWeightChanged:
                                            (weight) => widget.onWeightChanged(
                                              widget.exercise,
                                              exerciseSet,
                                              weight,
                                            ),
                                        onRepsChanged:
                                            (reps) => widget.onRepsChanged(
                                              widget.exercise,
                                              exerciseSet,
                                              reps,
                                            ),
                                        onCheckedChanged:
                                            (checked) =>
                                                widget.onSetCheckedChanged(
                                                  widget.exercise,
                                                  exerciseSet,
                                                  checked,
                                                ),
                                        onDismissed:
                                            () => widget.onRemoveSet(
                                              widget.exercise,
                                              exerciseSet,
                                            ),
                                      );
                                    }).toList(),
                              ),
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              // Add set button - also animated
              if ((!widget.isCollapsed || _isAnimatingToCollapsed) &&
                  _contentHeightAnimation != null)
                SizeTransition(
                  sizeFactor: _contentHeightAnimation!,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onAddSet,
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
