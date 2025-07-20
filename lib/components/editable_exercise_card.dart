import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/models/editable_workout_models.dart';
import 'package:gymfit/services/theme_service.dart';

class EditableExerciseCard extends StatefulWidget {
  final EditableExercise exercise;
  final int exerciseIndex;
  final VoidCallback onAddSet;
  final VoidCallback onRemoveExercise;
  final Function(int) onRemoveSet;
  final Function(bool?) onExerciseCheckChanged;
  final Function(int, bool?) onSetCheckChanged;
  final bool preventAutoFocus;
  final Function(bool)? onFocusChanged;
  final bool isNewlyAdded;
  final bool isCollapsed;
  final VoidCallback onRequestReorderMode;

  const EditableExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.onAddSet,
    required this.onRemoveExercise,
    required this.onRemoveSet,
    required this.onExerciseCheckChanged,
    required this.onSetCheckChanged,
    this.preventAutoFocus = false,
    this.onFocusChanged,
    this.isNewlyAdded = false,
    this.isCollapsed = false,
    required this.onRequestReorderMode,
  });

  @override
  State<EditableExerciseCard> createState() => _EditableExerciseCardState();
}

class _EditableExerciseCardState extends State<EditableExerciseCard>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  AnimationController? _unfoldAnimationController;
  Animation<double>? _opacityAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _contentHeightAnimation;
  Animation<double>? _unfoldContentHeightAnimation;
  bool _isUnfolding = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _unfoldAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
      ),
    );

    _contentHeightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
      ),
    );

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
    final themeService = Provider.of<ThemeService>(context);

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
      onDismissed: (direction) => widget.onRemoveExercise(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Card(
          color: widget.isCollapsed 
              ? (themeService.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade50)
              : themeService.currentTheme.cardTheme.color,
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: widget.isCollapsed ? 2 : 1,
          shadowColor: widget.isCollapsed ? Colors.grey.shade400 : Colors.grey.shade300,
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
                                    shadowColor: Colors.black.withValues(
                                      alpha: 0.2,
                                    ),
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
                        if (!widget.isCollapsed) ...[
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final isSmallScreen = availableWidth < 350;
                              final spacing = isSmallScreen ? 6.0 : 8.0;
                              final minCheckboxSize = 48.0;

                              return Column(
                                children: [
                                  // Animated content that unfolds/folds
                                  if (_contentHeightAnimation != null)
                                    SizeTransition(
                                      sizeFactor: _contentHeightAnimation!,
                                      child: Column(
                                        children: [
                                          Row(
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
                                                    value: widget.exercise.sets.every((set) => set.isChecked),
                                                    tristate: true,
                                                    fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                                      if (states.contains(WidgetState.selected)) {
                                                        return Colors.green;
                                                      }
                                                      return Colors.grey.shade300;
                                                    }),
                                                    onChanged: (val) {
                                                      HapticFeedback.lightImpact();
                                                      widget.onExerciseCheckChanged(val);
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
                                      ),
                                    ),
                                  // Exercise sets - also animated
                                  if (_contentHeightAnimation != null)
                                    SizeTransition(
                                      sizeFactor: _contentHeightAnimation!,
                                      child: Column(
                                        children: widget.exercise.sets.asMap().entries.map((entry) {
                                          int setIndex = entry.key;
                                          EditableExerciseSet exerciseSet = entry.value;
                                          return _buildSetRow(
                                            context,
                                            exerciseSet,
                                            setIndex,
                                            themeService,
                                            isSmallScreen,
                                            spacing,
                                            minCheckboxSize,
                                            widget.preventAutoFocus,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              if (!widget.isCollapsed) _buildAddSetButton(themeService),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildSetRow(
    BuildContext context,
    EditableExerciseSet exerciseSet,
    int setIndex,
    ThemeService themeService,
    bool isSmallScreen,
    double spacing,
    double minCheckboxSize,
    bool preventAutoFocus,
  ) {

    return Dismissible(
      key: Key('set_${exerciseSet.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const FaIcon(
          FontAwesomeIcons.trash,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) => widget.onRemoveSet(setIndex),
      child: Container(
        width: double.infinity,
        color: exerciseSet.isChecked 
            ? (themeService.isDarkMode ? Colors.green.shade900 : Colors.green.shade100) 
            : Colors.transparent,
        padding: const EdgeInsets.all(1),
        margin: const EdgeInsets.symmetric(vertical: 0),
        child: Row(
          children: [
            // Set number - fixed small width
            SizedBox(
              width: isSmallScreen ? 35 : 45,
              child: Center(
                child: Text(
                  '${setIndex + 1}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: themeService.currentTheme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            SizedBox(width: spacing),
            // Previous data - flexible
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  exerciseSet.previousDataFormatted,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(width: spacing),
            // Weight input - flexible
            Expanded(
              flex: 2,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isSmallScreen ? 45 : 60,
                    minWidth: 40,
                    maxHeight: 28,
                  ),
                  child: _buildWeightTextField(exerciseSet, themeService, isSmallScreen, preventAutoFocus),
                ),
              ),
            ),
            SizedBox(width: spacing),
            // Reps input - flexible
            Expanded(
              flex: 2,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isSmallScreen ? 45 : 60,
                    minWidth: 40,
                    maxHeight: 28,
                  ),
                  child: _buildRepsTextField(exerciseSet, themeService, isSmallScreen, preventAutoFocus),
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
                  value: exerciseSet.isChecked,
                  fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.green;
                    }
                    return Colors.grey.shade300;
                  }),
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    widget.onSetCheckChanged(setIndex, val);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightTextField(EditableExerciseSet exerciseSet, ThemeService themeService, bool isSmallScreen, bool preventAutoFocus) {
    return TextFormField(
      controller: exerciseSet.weightController,
      focusNode: exerciseSet.weightFocusNode,
      autofocus: false,
      canRequestFocus: !preventAutoFocus,
      readOnly: preventAutoFocus,
      onTap: () {
        // Toggle selection state based on our tracking
        if (exerciseSet.weightSelected) {
          // Clear selection
          exerciseSet.weightController.selection =
              TextSelection.collapsed(
            offset: exerciseSet.weightController.text.length,
          );
          exerciseSet.weightSelected = false;
        } else {
          // Select all text
          exerciseSet.weightController.selection =
              TextSelection(
            baseOffset: 0,
            extentOffset: exerciseSet.weightController.text.length,
          );
          exerciseSet.weightSelected = true;
        }
        
        // Notify focus change
        widget.onFocusChanged?.call(true);
      },
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: isSmallScreen ? 14 : 16,
        color: exerciseSet.isChecked
            ? (themeService.isDarkMode ? Colors.white : Colors.black)
            : (themeService.isDarkMode ? Colors.white : Colors.black),
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: exerciseSet.isChecked
                ? Colors.green
                : (themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: exerciseSet.isChecked
                ? Colors.green
                : (themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: themeService.isDarkMode ? Colors.blue.shade300 : Colors.blue,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: themeService.isDarkMode ? Colors.grey.shade800 : Colors.white,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 3 : 4,
          vertical: 0,
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
      onChanged: (val) {
        final newWeight = double.tryParse(val) ?? 0.0;
        exerciseSet.weightSelected = false; // Reset selection state when typing
        exerciseSet.updateWeight(newWeight);
      },
    );
  }

  Widget _buildRepsTextField(EditableExerciseSet exerciseSet, ThemeService themeService, bool isSmallScreen, bool preventAutoFocus) {
    return TextFormField(
      controller: exerciseSet.repsController,
      focusNode: exerciseSet.repsFocusNode,
      autofocus: false,
      canRequestFocus: !preventAutoFocus,
      readOnly: preventAutoFocus,
      enableInteractiveSelection: true,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: isSmallScreen ? 14 : 16,
        color: exerciseSet.isChecked
            ? (themeService.isDarkMode ? Colors.white : Colors.black)
            : (themeService.isDarkMode ? Colors.white : Colors.black),
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: exerciseSet.isChecked
                ? Colors.green
                : (themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: exerciseSet.isChecked
                ? Colors.green
                : (themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: themeService.isDarkMode ? Colors.blue.shade300 : Colors.blue,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: themeService.isDarkMode ? Colors.grey.shade800 : Colors.white,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 3 : 4,
          vertical: 0,
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onTap: () {
        // Toggle selection state based on our tracking
        if (exerciseSet.repsSelected) {
          // Clear selection
          exerciseSet.repsController.selection =
              TextSelection.collapsed(
            offset: exerciseSet.repsController.text.length,
          );
          exerciseSet.repsSelected = false;
        } else {
          // Select all text
          exerciseSet.repsController.selection =
              TextSelection(
            baseOffset: 0,
            extentOffset: exerciseSet.repsController.text.length,
          );
          exerciseSet.repsSelected = true;
        }
        
        // Notify focus change
        widget.onFocusChanged?.call(true);
      },
      onChanged: (val) {
        final newReps = int.tryParse(val) ?? 0;
        exerciseSet.repsSelected = false; // Reset selection state when typing
        exerciseSet.updateReps(newReps);
      },
    );
  }

  Widget _buildAddSetButton(ThemeService themeService) {
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
  }
} 