import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/models/editable_workout_models.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/services/workout_edit_service.dart';
import 'package:gymfit/services/theme_service.dart';
import 'package:gymfit/components/workout_name_editor.dart';
import 'package:gymfit/components/workout_timing_card.dart';
import 'package:gymfit/components/generic_exercise_card.dart';
import 'package:gymfit/components/add_exercise_button.dart';
import 'package:provider/provider.dart';

class WorkoutEditPage extends StatefulWidget {
  final Workout workout;

  const WorkoutEditPage({super.key, required this.workout});

  @override
  State<WorkoutEditPage> createState() => _WorkoutEditPageState();
}

class _WorkoutEditPageState extends State<WorkoutEditPage> {
  List<EditableExercise> _exercises = [];
  late TextEditingController _workoutNameController;
  late DateTime _startTime;
  late DateTime _endTime;
  bool _isEditingWorkoutName = false;
  bool _isSaving = false;
  late ScrollController _scrollController;
  bool _showWorkoutNameInAppBar = false;
  bool _preventAutoFocus = false;
  bool _isAnyFieldFocused = false;
  final Set<EditableExercise> _newlyAddedExercises = {};
  bool _isInReorderMode = false;

  @override
  void initState() {
    super.initState();
    _workoutNameController = TextEditingController(text: widget.workout.name);
    _startTime = widget.workout.date;
    _endTime = widget.workout.date.add(widget.workout.duration);
    
    // Initialize scroll controller
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Convert workout exercises to editable format
    _exercises = WorkoutEditService.convertWorkoutToEditable(widget.workout);
    
    // Add focus listeners to all existing fields
    _addFocusListeners();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _workoutNameController.dispose();
    for (var exercise in _exercises) {
      for (var set in exercise.sets) {
        set.dispose();
      }
    }
    super.dispose();
  }

  void _toggleWorkoutNameEditing() {
    setState(() {
      _isEditingWorkoutName = !_isEditingWorkoutName;
    });
  }

  void _onWorkoutNameSubmitted() {
    setState(() {
      _isEditingWorkoutName = false;
    });
    _preventAutoFocus = true;
    _clearFocusAggressively();

    // Re-enable interaction after a delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _preventAutoFocus = false;
        });
      }
    });
  }

  void _onWorkoutNameChanged(String newName) {
    setState(() {
      // The controller will be updated automatically
    });
  }

  void _clearFocusAggressively() {
    // Check if widget is still mounted and context is active
    if (!mounted) return;

    try {
      // Multiple approaches to ensure focus is completely cleared
      FocusScope.of(context).unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (e) {
      // Safely handle cases where context is no longer valid
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _selectStartTime() async {
    await WorkoutEditService.selectStartTime(
      context,
      _startTime,
      (newStartTime) => setState(() => _startTime = newStartTime),
      (newEndTime) => setState(() => _endTime = newEndTime),
    );
  }

  Future<void> _selectEndTime() async {
    await WorkoutEditService.selectEndTime(
      context,
      _startTime,
      _endTime,
      (newEndTime) => setState(() => _endTime = newEndTime),
    );
  }

  Future<void> _saveWorkout() async {
    try {
      final success = await WorkoutEditService.saveWorkout(
        widget.workout,
        _workoutNameController.text,
        _startTime,
        _endTime,
        _exercises,
        (isSaving) => setState(() => _isSaving = isSaving),
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onScroll() {
    const double threshold = 100.0;
    bool shouldShow = _scrollController.offset > threshold;
    
    if (shouldShow != _showWorkoutNameInAppBar) {
      // Auto-save workout name when it slides into the app bar during editing
      if (shouldShow && _isEditingWorkoutName) {
        setState(() {
          _isEditingWorkoutName = false;
        });
        _clearFocusAggressively();
        _preventAutoFocus = true;

        // Re-enable interaction after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _preventAutoFocus = false;
            });
          }
        });
      }
      
      setState(() {
        _showWorkoutNameInAppBar = shouldShow;
      });
    }
  }

  void _onExercisesAdded() {
    // This method is called when exercises are being added
    // We can add any additional logic here if needed
  }

  void _onExercisesLoaded(List<QuickStartExercise> newExercises) {
    // Convert QuickStartExercise to EditableExercise
    setState(() {
      final editableExercises = newExercises.map((exercise) {
        final title = exercise.title;
        final sets = exercise.sets.map((set) {
          return EditableExerciseSet(
            weight: set.weight,
            reps: set.reps,
            isChecked: set.isChecked,
          );
        }).toList();
        return EditableExercise(title: title, sets: sets);
      }).toList();
      
      _exercises.addAll(editableExercises);
      
      // Mark new exercises as newly added for animation
      _newlyAddedExercises.addAll(editableExercises);
      
      // Add focus listeners to new exercises
      for (var exercise in editableExercises) {
        for (var set in exercise.sets) {
          set.weightFocusNode.addListener(() {
            _checkFocusState();
          });
          set.repsFocusNode.addListener(() {
            _checkFocusState();
          });
        }
      }
    });
  }

  void _onFocusChanged(bool hasFocus) {
    setState(() {
      _isAnyFieldFocused = hasFocus;
    });
  }

  void _checkFocusState() {
    // Check if any field is currently focused
    bool anyFieldFocused = false;
    for (var exercise in _exercises) {
      for (var set in exercise.sets) {
        if (set.weightFocusNode.hasFocus || set.repsFocusNode.hasFocus) {
          anyFieldFocused = true;
          break;
        }
      }
      if (anyFieldFocused) break;
    }
    
    setState(() {
      _isAnyFieldFocused = anyFieldFocused;
    });
  }

  void _addFocusListeners() {
    for (var exercise in _exercises) {
      for (var set in exercise.sets) {
        set.weightFocusNode.addListener(() {
          _checkFocusState();
        });
        set.repsFocusNode.addListener(() {
          _checkFocusState();
        });
      }
    }
  }

  bool _isExerciseNewlyAdded(EditableExercise exercise) {
    return _newlyAddedExercises.contains(exercise);
  }

  void _handleRequestReorderMode() {
    setState(() {
      _isInReorderMode = true;
      // Automatically show workout name in app bar when entering reorder mode
      _showWorkoutNameInAppBar = true;
    });
  }

  void _handleReorderStart(int index) {
    // Provide haptic feedback when starting to reorder
    HapticFeedback.mediumImpact();
  }

  void _handleReorderEnd(int index) {
    // Don't exit reorder mode when drag ends - user must tap "Done"
  }

  void _handleDoneReorder() {
    setState(() {
      _isInReorderMode = false;
      // Mark all exercises as newly added to trigger unfolding animations
      _newlyAddedExercises.addAll(_exercises);
    });
  }

  void _handleReorderExercises(int oldIndex, int newIndex) {
    // Provide haptic feedback when reordering
    HapticFeedback.lightImpact();
    
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final EditableExercise item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
      
      // Clear newly added flags when reordering to prevent animation during reorder
      _newlyAddedExercises.clear();
    });
  }

  void _removeExercise(int exerciseIndex) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      for (var set in exercise.sets) {
        set.dispose();
      }
      _exercises.removeAt(exerciseIndex);
    });
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      final newSet = EditableExerciseSet();
      _exercises[exerciseIndex].sets.add(newSet);
      
      // Add focus listeners to new set
      newSet.weightFocusNode.addListener(() {
        _checkFocusState();
      });
      newSet.repsFocusNode.addListener(() {
        _checkFocusState();
      });
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final set = exercise.sets[setIndex];
      set.dispose();
      exercise.sets.removeAt(setIndex);
    });
  }

  void _onExerciseCheckChanged(int exerciseIndex, bool? value) {
    HapticFeedback.lightImpact();
    setState(() {
      bool newValue = value ?? false;
      for (var set in _exercises[exerciseIndex].sets) {
        set.isChecked = newValue;
      }
    });
  }

  void _onSetCheckChanged(int exerciseIndex, int setIndex, bool? value) {
    HapticFeedback.lightImpact();
    setState(() {
      _exercises[exerciseIndex].sets[setIndex].isChecked = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
        elevation: 0,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutQuart,
          switchOutCurve: Curves.easeInQuart,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutQuart,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: _showWorkoutNameInAppBar
              ? Row(
                  key: const ValueKey('workout-name'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.tag,
                      color: Colors.purple,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _workoutNameController.text.isEmpty 
                            ? 'Untitled Workout' 
                            : _workoutNameController.text,
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Edit Workout',
                  key: const ValueKey('edit-title'),
                  style: themeService.currentTheme.appBarTheme.titleTextStyle,
                ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: themeService.currentTheme.appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveWorkout,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.save, 
                    color: themeService.currentTheme.appBarTheme.foregroundColor,
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            _clearFocusAggressively();
          },
          child: Column(
            children: [
              // Workout Name Card with smooth transition
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuart,
                  child: _showWorkoutNameInAppBar
                      ? const SizedBox.shrink()
                      : WorkoutNameEditor(
                          currentWorkoutName: _workoutNameController.text.isEmpty 
                              ? 'Untitled Workout' 
                              : _workoutNameController.text,
                          isEditing: _isEditingWorkoutName,
                          showInAppBar: _showWorkoutNameInAppBar,
                          onToggleEditing: _toggleWorkoutNameEditing,
                          onNameChanged: _onWorkoutNameChanged,
                          onSubmitted: _onWorkoutNameSubmitted,
                        ),
                ),
              ),

              // Exercise List with timing card - now extends to edge
              Expanded(
                child: _isInReorderMode
                    ? ReorderableListView.builder(
                        itemCount: _exercises.length + 1, // +1 for timing card
                        padding: const EdgeInsets.only(bottom: 100),
                        onReorder: (oldIndex, newIndex) {
                          // Adjust indices since timing card is first
                          if (oldIndex > 0 && newIndex > 0) {
                            _handleReorderExercises(oldIndex - 1, newIndex - 1);
                          }
                        },
                        onReorderStart: (int index) {
                          _handleReorderStart(index);
                        },
                        onReorderEnd: (int index) {
                          _handleReorderEnd(index);
                        },
                        itemBuilder: (context, exerciseIndex) {
                          // Show timing card as first item
                          if (exerciseIndex == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                              child: WorkoutTimingCard(
                                key: const ValueKey('timing_card'),
                                startTime: _startTime,
                                endTime: _endTime,
                                onStartTimeTap: _selectStartTime,
                                onEndTimeTap: _selectEndTime,
                              ),
                            );
                          }
                          
                          // Show exercises (adjust index since timing card is first)
                          final exercise = _exercises[exerciseIndex - 1];
                          final exerciseData = EditableExerciseAdapter(exercise);
                          return GenericExerciseCard(
                            key: ValueKey('exercise_${exercise.title}_${exerciseIndex - 1}'),
                            exercise: exerciseData,
                            exerciseIndex: exerciseIndex - 1,
                            preventAutoFocus: _preventAutoFocus,
                            isNewlyAdded: _isExerciseNewlyAdded(exercise),
                            isCollapsed: _isInReorderMode,
                            onRemoveExercise: (exerciseData) => _removeExercise(exerciseIndex - 1),
                            onRemoveSet: (exerciseData, set) => _removeSet(exerciseIndex - 1, exercise.sets.indexOf(set as EditableExerciseSet)),
                            onWeightChanged: (exerciseData, set, weight) {
                              final editableSet = set as EditableExerciseSet;
                              editableSet.updateWeight(weight);
                            },
                            onRepsChanged: (exerciseData, set, reps) {
                              final editableSet = set as EditableExerciseSet;
                              editableSet.updateReps(reps);
                            },
                            onSetCheckedChanged: (exerciseData, set, checked) {
                              final editableSet = set as EditableExerciseSet;
                              final setIndex = exercise.sets.indexOf(editableSet);
                              _onSetCheckChanged(exerciseIndex - 1, setIndex, checked);
                            },
                            onAllSetsCheckedChanged: (exerciseData, checked) {
                              _onExerciseCheckChanged(exerciseIndex - 1, checked);
                            },
                            onAddSet: () => _addSet(exerciseIndex - 1),
                            onRequestReorderMode: _handleRequestReorderMode,
                            onFocusChanged: _onFocusChanged,
                          );
                        },
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _exercises.length + 1, // +1 for timing card
                        padding: const EdgeInsets.only(bottom: 100),
                        itemBuilder: (context, exerciseIndex) {
                          // Show timing card as first item
                          if (exerciseIndex == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                              child: WorkoutTimingCard(
                                startTime: _startTime,
                                endTime: _endTime,
                                onStartTimeTap: _selectStartTime,
                                onEndTimeTap: _selectEndTime,
                              ),
                            );
                          }
                          
                          // Show exercises (adjust index since timing card is first)
                          final exercise = _exercises[exerciseIndex - 1];
                          final exerciseData = EditableExerciseAdapter(exercise);
                          return GenericExerciseCard(
                            exercise: exerciseData,
                            exerciseIndex: exerciseIndex - 1,
                            preventAutoFocus: _preventAutoFocus,
                            isNewlyAdded: _isExerciseNewlyAdded(exercise),
                            isCollapsed: _isInReorderMode,
                            onRemoveExercise: (exerciseData) => _removeExercise(exerciseIndex - 1),
                            onRemoveSet: (exerciseData, set) => _removeSet(exerciseIndex - 1, exercise.sets.indexOf(set as EditableExerciseSet)),
                            onWeightChanged: (exerciseData, set, weight) {
                              final editableSet = set as EditableExerciseSet;
                              editableSet.updateWeight(weight);
                            },
                            onRepsChanged: (exerciseData, set, reps) {
                              final editableSet = set as EditableExerciseSet;
                              editableSet.updateReps(reps);
                            },
                            onSetCheckedChanged: (exerciseData, set, checked) {
                              final editableSet = set as EditableExerciseSet;
                              final setIndex = exercise.sets.indexOf(editableSet);
                              _onSetCheckChanged(exerciseIndex - 1, setIndex, checked);
                            },
                            onAllSetsCheckedChanged: (exerciseData, checked) {
                              _onExerciseCheckChanged(exerciseIndex - 1, checked);
                            },
                            onAddSet: () => _addSet(exerciseIndex - 1),
                            onRequestReorderMode: _handleRequestReorderMode,
                            onFocusChanged: _onFocusChanged,
                          );
                        },
                      ),
              ),
                
              // Done button for reorder mode
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutQuart,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    opacity: (_isInReorderMode && !_isAnyFieldFocused && !_isEditingWorkoutName) ? 1.0 : 0.0,
                    child: (_isInReorderMode && !_isAnyFieldFocused && !_isEditingWorkoutName)
                        ? Column(
                          children: [
                            const SizedBox(height: 4),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final screenWidth = MediaQuery.of(context).size.width;
                                final buttonFontSize = screenWidth < 350 ? 16.0 : 18.0;
                                final buttonPadding = screenWidth < 350 
                                    ? const EdgeInsets.symmetric(vertical: 12) 
                                    : const EdgeInsets.symmetric(vertical: 16);

                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _handleDoneReorder,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                      padding: buttonPadding,
                                    ),
                                    child: Text(
                                      'Done',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              // Add Exercises button at the bottom
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutQuart,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  opacity: _isInReorderMode ? 0.0 : 1.0,
                  child: _isInReorderMode
                      ? const SizedBox.shrink()
                      : AddExerciseButton(
                        isAnyFieldFocused: _isAnyFieldFocused,
                        isEditingWorkoutName: _isEditingWorkoutName,
                        onExercisesAdded: _onExercisesAdded,
                        onExercisesLoaded: _onExercisesLoaded,
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