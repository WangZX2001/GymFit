import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/components/custom_workout_set_row.dart';
import 'package:gymfit/services/custom_workout_configuration_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class CustomWorkoutExerciseCard extends StatefulWidget {
  final ConfigExercise exercise;
  final int index;
  final bool isCollapsed;
  final bool preventAutoFocus;
  final bool isNewlyAdded;
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
    this.isNewlyAdded = false,
    required this.onRequestReorderMode,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  @override
  State<CustomWorkoutExerciseCard> createState() => _CustomWorkoutExerciseCardState();
}

class _CustomWorkoutExerciseCardState extends State<CustomWorkoutExerciseCard>
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
  void didUpdateWidget(CustomWorkoutExerciseCard oldWidget) {
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
                      Builder(
                        builder: (context) {
                          final themeService = Provider.of<ThemeService>(context);
                          return Text(
                            widget.exercise.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: themeService.currentTheme.textTheme.titleMedium?.color,
                            ),
                          );
                        },
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
                        Builder(
                          builder: (context) {
                            final themeService = Provider.of<ThemeService>(context);
                            return PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz),
                              onSelected: (value) {
                                if (value == 'reorder') {
                                  widget.onRequestReorderMode();
                                }
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: themeService.currentTheme.cardTheme.color,
                              elevation: 8,
                              shadowColor: Colors.black.withValues(alpha: 0.2),
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: 'reorder',
                                  height: 48,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.drag_handle,
                                        color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Reorder',
                                        style: TextStyle(
                                          color: themeService.currentTheme.textTheme.titleMedium?.color,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                  // Animated content that unfolds/folds
                  if (!widget.isCollapsed || _isAnimatingToCollapsed) ...[
                    if (_contentHeightAnimation != null)
                      SizeTransition(
                        sizeFactor: _isUnfolding
                            ? _unfoldContentHeightAnimation!
                            : _contentHeightAnimation!,
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
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
                                        child: Builder(
                                          builder: (context) {
                                            final themeService = Provider.of<ThemeService>(context);
                                            return Text(
                                              'Set',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isSmallScreen ? 14 : 16,
                                                color: themeService.currentTheme.textTheme.titleMedium?.color,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: spacing),
                                    // Previous - flexible
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Builder(
                                          builder: (context) {
                                            final themeService = Provider.of<ThemeService>(context);
                                            return Text(
                                              'Previous',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isSmallScreen ? 14 : 16,
                                                color: themeService.currentTheme.textTheme.titleMedium?.color,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
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
                                          child: Builder(
                                            builder: (context) {
                                              final themeService = Provider.of<ThemeService>(context);
                                              return Text(
                                                'Kg',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isSmallScreen ? 14 : 16,
                                                  color: themeService.currentTheme.textTheme.titleMedium?.color,
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            },
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
                                          child: Builder(
                                            builder: (context) {
                                              final themeService = Provider.of<ThemeService>(context);
                                              return Text(
                                                'Reps',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isSmallScreen ? 14 : 16,
                                                  color: themeService.currentTheme.textTheme.titleMedium?.color,
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final themeService = Provider.of<ThemeService>(context);
                                return Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    // Exercise sets - also animated
                    if (_contentHeightAnimation != null)
                      SizeTransition(
                        sizeFactor: _contentHeightAnimation!,
                        child: Column(
                          children: widget.exercise.sets.asMap().entries.map((entry) {
                            final setIndex = entry.key;
                            final set = entry.value;
                            return CustomWorkoutSetRow(
                              key: Key('${widget.exercise.title}_${set.id}'),
                              set: set,
                              setIndex: setIndex,
                              preventAutoFocus: widget.preventAutoFocus,
                              onWeightChanged: widget.onWeightChanged,
                              onRepsChanged: widget.onRepsChanged,
                              onRemoveSet: () => widget.onRemoveSet(set),
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
              child: Builder(
                builder: (context) {
                  final themeService = Provider.of<ThemeService>(context);
                  return ElevatedButton(
                    onPressed: widget.onAddSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeService.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      foregroundColor: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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
                      color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
} 