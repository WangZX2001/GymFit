import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:gymfit/pages/workout/workout_name_description_page.dart';
import 'package:gymfit/services/workout_service.dart';

// Model to track individual set data for template
class TemplateExerciseSet {
  final String id;
  int weight;
  int reps;
  
  TemplateExerciseSet({this.weight = 0, this.reps = 0}) 
    : id = '${DateTime.now().millisecondsSinceEpoch}_${weight * 1000 + reps}';
}

// Model to track exercise with multiple sets for template
class TemplateExercise {
  final String title;
  List<TemplateExerciseSet> sets;
  
  TemplateExercise({required this.title, List<TemplateExerciseSet>? sets}) 
    : sets = sets ?? [TemplateExerciseSet()];
}

class CustomWorkoutConfigurationPage extends StatefulWidget {
  final List<String> exerciseNames;
  final CustomWorkout? existingWorkout; // For editing existing workouts
  
  const CustomWorkoutConfigurationPage({
    super.key,
    required this.exerciseNames,
    this.existingWorkout,
  });

  @override
  State<CustomWorkoutConfigurationPage> createState() => _CustomWorkoutConfigurationPageState();
}

class _CustomWorkoutConfigurationPageState extends State<CustomWorkoutConfigurationPage> {
  List<ConfigExercise> _exercises = [];
  bool _preventAutoFocus = false;
  bool _isAnyFieldFocused = false;

  // Add method to check if there are exercises configured
  bool get _hasExercises => _exercises.isNotEmpty;

  // Add method to show confirmation dialog
  Future<bool> _showExitConfirmationDialog() async {
    if (!mounted) return false;
    
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'Custom workout not saved, are you sure you want to leave? All progress will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Add method to handle back navigation
  Future<bool> _handleBackNavigation() async {
    if (_hasExercises) {
      return await _showExitConfirmationDialog();
    }
    return true; // Allow back navigation if no exercises
  }

  @override
  void initState() {
    super.initState();
    
    // If editing an existing workout, pre-populate with its data
    if (widget.existingWorkout != null) {
      _exercises = widget.existingWorkout!.exercises.map((exercise) {
        final configExercise = ConfigExercise(title: exercise.name);
        // Replace the default empty set with the actual sets from the workout
        configExercise.sets.clear();
        for (var set in exercise.sets) {
          final configSet = ConfigSet();
          configSet.weight = set.weight;
          configSet.reps = set.reps;
          configSet.weightController.text = ConfigSet._fmt(set.weight);
          configSet.repsController.text = set.reps.toString();
          configExercise.sets.add(configSet);
        }
        return configExercise;
      }).toList();
    } else {
      // Creating new workout - use exercise names and try to load previous data
      _loadExercisesWithPreviousData();
    }
    
    _setupFocusListeners();
  }

  void _updateFocusState() {
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
    
    if (anyFieldFocused != _isAnyFieldFocused) {
      setState(() {
        _isAnyFieldFocused = anyFieldFocused;
      });
    }
  }

  void _clearFocusAggressively() {
    // Check if widget is still mounted and context is active
    if (!mounted) return;
    
    try {
      // Multiple approaches to ensure focus is completely cleared
      FocusScope.of(context).unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      
      // Clear focus from all exercise focus nodes
      for (var exercise in _exercises) {
        for (var set in exercise.sets) {
          if (set.weightFocusNode.hasFocus) {
            set.weightFocusNode.unfocus();
          }
          if (set.repsFocusNode.hasFocus) {
            set.repsFocusNode.unfocus();
          }
        }
      }
    } catch (e) {
      // Safely handle cases where context is no longer valid
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _loadExercisesWithPreviousData() async {
    List<ConfigExercise> exercises = [];
    
    for (final name in widget.exerciseNames) {
      try {
        // Try to get previous exercise data
        final previousData = await WorkoutService.getLastExerciseData(name);
        
        List<ConfigSet> sets;
        if (previousData != null && previousData['sets'] != null) {
          // Create sets based on previous workout data
          final previousSetsData = previousData['sets'] as List<dynamic>;
          
          sets = previousSetsData.map((setData) {
            final weight = (setData['weight'] as num?)?.toDouble() ?? 0.0;
            final reps = (setData['reps'] as int?) ?? 0;
            return ConfigSet(
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
          sets = [ConfigSet()];
        }
        
        exercises.add(ConfigExercise(title: name, sets: sets));
      } catch (e) {
        // If there's an error fetching data, use default
        exercises.add(ConfigExercise(title: name));
      }
    }
    
    setState(() {
      _exercises = exercises;
      _setupFocusListeners();
    });
  }

  void _setupFocusListeners() {
    for (var exercise in _exercises) {
      for (var set in exercise.sets) {
        set.addFocusListeners(_updateFocusState);
      }
    }
  }

  void _removeFocusListeners() {
    for (var exercise in _exercises) {
      for (var set in exercise.sets) {
        set.removeFocusListeners(_updateFocusState);
      }
    }
  }

  @override
  void dispose() {
    _removeFocusListeners();
    super.dispose();
  }

  void _proceedToNameDescription() async {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise')),
      );
      return;
    }

    // Convert exercises to CustomWorkoutExercise format
    final customExercises = _exercises.map((exercise) {
      final customSets = exercise.sets.map((set) => 
        CustomWorkoutSet(weight: set.weight, reps: set.reps)
      ).toList();
      
      return CustomWorkoutExercise(
        name: exercise.title,
        sets: customSets,
      );
    }).toList();

    // Navigate to name/description page
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutNameDescriptionPage(
          exercises: customExercises,
          existingWorkout: widget.existingWorkout,
        ),
      ),
    );

    // Prevent auto-focus when returning from workout name description page
    if (mounted) {
      setState(() {
        _preventAutoFocus = true;
      });
      
      // Re-enable interaction after build is complete
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _preventAutoFocus = false;
          });
          _clearFocusAggressively();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        final navigator = Navigator.of(context);
        final shouldPop = await _handleBackNavigation();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade200,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final shouldPop = await _handleBackNavigation();
              if (shouldPop && mounted) {
                navigator.pop();
              }
            },
          ),
        title: const Text(
          'Configure Workout',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _proceedToNameDescription,
            icon: const Icon(Icons.done, color: Colors.black, size: 24),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside text fields
          _clearFocusAggressively();
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return Dismissible(
                  key: Key('exercise_${exercise.title}_$index'),
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
                  onDismissed: (direction) {
                    // Immediately clear focus to prevent errors
                    if (mounted) {
                      try {
                        FocusScope.of(context).unfocus();
                      } catch (e) {
                        // Context might be invalid, use fallback
                      }
                    }
                    
                    // Properly dispose of focus nodes and controllers before removing
                    if (index < _exercises.length) {
                      final exerciseToRemove = _exercises[index];
                      for (var set in exerciseToRemove.sets) {
                        set.removeFocusListeners(_updateFocusState);
                        set.dispose();
                      }
                      
                      // Immediately remove from list to prevent tree issues
                      setState(() {
                        _exercises.removeAt(index);
                      });
                    }
                  },
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
                                    return Dismissible(
                                      key: Key('${exercise.title}_${set.id}'),
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
                                      onDismissed: (direction) {
                                        if (exercise.sets.length > 1) {
                                          setState(() {
                                            exercise.sets.remove(set);
                                          });
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(2),
                                        margin: const EdgeInsets.symmetric(vertical: 5),
                                        child: LayoutBuilder(
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
                                                      '${setIndex + 1}',
                                                      style: TextStyle(
                                                        fontSize: isSmallScreen ? 16 : 18,
                                                        fontWeight: FontWeight.bold,
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
                                                      set.previousDataFormatted,
                                                      style: TextStyle(
                                                        fontSize: isSmallScreen ? 14 : 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.grey.shade500,
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
                                                      child: TextFormField(
                                                        controller: set.weightController,
                                                        focusNode: set.weightFocusNode,
                                                        autofocus: false,
                                                        canRequestFocus: !_preventAutoFocus,
                                                        readOnly: _preventAutoFocus,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: isSmallScreen ? 14 : 16,
                                                          color: set.isWeightPrefilled 
                                                              ? Colors.grey.shade500 
                                                              : Colors.black,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                        decoration: InputDecoration(
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide(
                                                              color: Colors.grey.shade400,
                                                              width: 1,
                                                            ),
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide(
                                                              color: Colors.grey.shade400,
                                                              width: 1,
                                                            ),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide(
                                                              color: Colors.blue,
                                                              width: 2,
                                                            ),
                                                          ),
                                                          filled: false,
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.symmetric(
                                                            horizontal: isSmallScreen ? 3 : 4,
                                                            vertical: 0,
                                                          ),
                                                        ),
                                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                        inputFormatters: [_DecimalTextInputFormatter(decimalRange: 2)],
                                                        onTap: () {
                                                          // Mark as manually edited when user taps
                                                          setState(() {
                                                            set.isWeightPrefilled = false;
                                                          });
                                                          
                                                          // Toggle selection state based on our tracking
                                                          if (set._weightSelected) {
                                                            // Clear selection
                                                            set.weightController.selection = TextSelection.collapsed(
                                                              offset: set.weightController.text.length,
                                                            );
                                                            set._weightSelected = false;
                                                          } else {
                                                            // Select all text
                                                            set.weightController.selection = TextSelection(
                                                              baseOffset: 0, 
                                                              extentOffset: set.weightController.text.length,
                                                            );
                                                            set._weightSelected = true;
                                                          }
                                                        },
                                                        onChanged: (value) {
                                                          final newWeight = double.tryParse(value) ?? 0.0;
                                                          setState(() {
                                                            set.updateWeight(newWeight);
                                                            set._weightSelected = false; // Reset selection state when typing
                                                          });
                                                        },
                                                      ),
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
                                                      child: TextFormField(
                                                        controller: set.repsController,
                                                        focusNode: set.repsFocusNode,
                                                        autofocus: false,
                                                        canRequestFocus: !_preventAutoFocus,
                                                        enableInteractiveSelection: true,
                                                        readOnly: _preventAutoFocus,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: isSmallScreen ? 14 : 16,
                                                          color: set.isRepsPrefilled 
                                                              ? Colors.grey.shade500 
                                                              : Colors.black,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                        decoration: InputDecoration(
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide(
                                                              color: Colors.grey.shade400,
                                                              width: 1,
                                                            ),
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide(
                                                              color: Colors.grey.shade400,
                                                              width: 1,
                                                            ),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide(
                                                              color: Colors.blue,
                                                              width: 2,
                                                            ),
                                                          ),
                                                          filled: false,
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.symmetric(
                                                            horizontal: isSmallScreen ? 3 : 4,
                                                            vertical: 0,
                                                          ),
                                                        ),
                                                        keyboardType: TextInputType.number,
                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                        onTap: () {
                                                          // Mark as manually edited when user taps
                                                          setState(() {
                                                            set.isRepsPrefilled = false;
                                                          });
                                                          
                                                          // Toggle selection state based on our tracking
                                                          if (set._repsSelected) {
                                                            // Clear selection
                                                            set.repsController.selection = TextSelection.collapsed(
                                                              offset: set.repsController.text.length,
                                                            );
                                                            set._repsSelected = false;
                                                          } else {
                                                            // Select all text
                                                            set.repsController.selection = TextSelection(
                                                              baseOffset: 0, 
                                                              extentOffset: set.repsController.text.length,
                                                            );
                                                            set._repsSelected = true;
                                                          }
                                                        },
                                                        onChanged: (value) {
                                                          final newReps = int.tryParse(value) ?? 0;
                                                          setState(() {
                                                            set.updateReps(newReps);
                                                            set._repsSelected = false; // Reset selection state when typing
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
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
                            onPressed: () async {
                              
                              // Try to get data from the last set in the current exercise
                              ConfigSet newSet;
                              if (exercise.sets.isNotEmpty) {
                                // Use data from the last set in current exercise
                                final lastSet = exercise.sets.last;
                                newSet = ConfigSet(
                                  weight: lastSet.weight,
                                  reps: lastSet.reps,
                                  isWeightPrefilled: true,
                                  isRepsPrefilled: true,
                                  previousWeight: lastSet.previousWeight,
                                  previousReps: lastSet.previousReps,
                                );
                              } else {
                                // Fallback to previous workout data
                                try {
                                  final previousData = await WorkoutService.getLastExerciseData(exercise.title);
                                  if (previousData != null && previousData['sets'] != null) {
                                    final previousSetsData = previousData['sets'] as List<dynamic>;
                                    if (previousSetsData.isNotEmpty) {
                                      // Use the last set from previous workout
                                      final lastSetData = previousSetsData.last;
                                      final weight = (lastSetData['weight'] as num?)?.toDouble() ?? 0.0;
                                      final reps = (lastSetData['reps'] as int?) ?? 0;
                                      
                                      newSet = ConfigSet(
                                        weight: weight, 
                                        reps: reps, 
                                        isWeightPrefilled: true, 
                                        isRepsPrefilled: true,
                                        previousWeight: weight,
                                        previousReps: reps,
                                      );
                                    } else {
                                      newSet = ConfigSet();
                                    }
                                  } else {
                                    newSet = ConfigSet();
                                  }
                                } catch (e) {
                                  newSet = ConfigSet();
                                }
                              }
                              
                              setState(() {
                                newSet.addFocusListeners(_updateFocusState);
                                exercise.sets.add(newSet);
                              });
                            },
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
                    ),
                  ),
                );
              },
            ),
          ),
          // Add Exercises Button with keyboard-aware visibility
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutQuart,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              opacity: _isAnyFieldFocused ? 0.0 : 1.0,
              child: _isAnyFieldFocused
                  ? const SizedBox.shrink()
                  : Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final buttonFontSize = screenWidth < 350 ? 16.0 : 18.0;
                        final buttonPadding = screenWidth < 350 
                            ? const EdgeInsets.symmetric(vertical: 12) 
                            : const EdgeInsets.symmetric(vertical: 16);
                        
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final navigator = Navigator.of(context, rootNavigator: true);
                              final result = await navigator.push<List<String>>(
                                MaterialPageRoute(
                                  builder: (ctx) => const ExerciseInformationPage(
                                    isSelectionMode: true,
                                  ),
                                ),
                              );
                              if (result != null && mounted) {
                                // Aggressively clear focus from any currently focused input fields
                                _clearFocusAggressively();
                                
                                setState(() {
                                  _preventAutoFocus = true; // Temporarily disable interaction
                                  _isAnyFieldFocused = false; // Ensure button stays visible
                                });
                                
                                // Additional focus clearing after state change
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    _clearFocusAggressively();
                                  }
                                });
                                
                                // Create new exercises with prefilled data
                                final List<ConfigExercise> newExercises = [];
                                
                                for (final title in result) {
                                  try {
                                    // Try to get previous exercise data
                                    final previousData = await WorkoutService.getLastExerciseData(title);
                                    
                                    List<ConfigSet> sets;
                                    if (previousData != null && previousData['sets'] != null) {
                                      // Create sets based on previous workout data
                                      final previousSetsData = previousData['sets'] as List<dynamic>;
                                      
                                      sets = previousSetsData.map((setData) {
                                        final weight = (setData['weight'] as num?)?.toDouble() ?? 0.0;
                                        final reps = (setData['reps'] as int?) ?? 0;
                                        return ConfigSet(
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
                                      sets = [ConfigSet()];
                                    }
                                    
                                    newExercises.add(ConfigExercise(title: title, sets: sets));
                                  } catch (e) {
                                    // If there's an error fetching data, use default
                                    newExercises.add(ConfigExercise(title: title));
                                  }
                                }
                                
                                if (mounted) {
                                  setState(() {
                                    // Add focus listeners to new exercises
                                    for (var exercise in newExercises) {
                                      for (var set in exercise.sets) {
                                        set.addFocusListeners(_updateFocusState);
                                      }
                                    }
                                    _exercises.addAll(newExercises);
                                  });
                                }
                                
                                // Re-enable interaction after ensuring new fields are built
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) {
                                    setState(() {
                                      _preventAutoFocus = false;
                                    });
                                  }
                                });
                              } else if (mounted) {
                                // Clear focus even when no exercises are selected
                                _clearFocusAggressively();
                                
                                // Apply auto-focus prevention even when no exercises are selected
                                setState(() {
                                  _preventAutoFocus = true;
                                  _isAnyFieldFocused = false; // Ensure button stays visible
                                });
                                
                                // Additional focus clearing after state change
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    _clearFocusAggressively();
                                  }
                                });
                                
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) {
                                    setState(() {
                                      _preventAutoFocus = false;
                                    });
                                  }
                                });
                              }
                            },
                            icon: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
                            label: Text(
                              'Add Exercises',
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: buttonFontSize, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: const StadiumBorder(),
                              padding: buttonPadding,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            ),
          ),
        ],
      ),
        ),
      ), // Close PopScope child
    );
  }
}

class ConfigExercise {
  final String title;
  List<ConfigSet> sets;
  
  ConfigExercise({required this.title, List<ConfigSet>? sets}) : sets = sets ?? [ConfigSet()];
}

class ConfigSet {
  final String id;
  double weight = 0.0;
  int reps = 0;
  late final TextEditingController weightController;
  late final TextEditingController repsController;
  late final FocusNode weightFocusNode;
  late final FocusNode repsFocusNode;
  bool _weightSelected = false;
  bool _repsSelected = false;
  bool isWeightPrefilled = false; // Track if weight was prefilled from previous data
  bool isRepsPrefilled = false; // Track if reps was prefilled from previous data
  double? previousWeight; // Previous workout weight for reference
  int? previousReps; // Previous workout reps for reference
  
  static int _counter = 0;
  
  // Helper to format weight display (strip trailing .0)
  static String _fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();
  
  // Helper to format previous data as "20kg x 5"
  String get previousDataFormatted {
    if (previousWeight != null && previousReps != null) {
      return '${_fmt(previousWeight!)}kg x $previousReps';
    }
    return '-';
  }
  
  ConfigSet({this.weight = 0.0, this.reps = 0, this.isWeightPrefilled = false, this.isRepsPrefilled = false, this.previousWeight, this.previousReps}) : id = '${DateTime.now().millisecondsSinceEpoch}_${++_counter}' {
    weightController = TextEditingController(text: _fmt(weight));
    repsController = TextEditingController(text: reps.toString());
    weightFocusNode = FocusNode();
    repsFocusNode = FocusNode();
  }
  
  void addFocusListeners(VoidCallback onFocusChange) {
    weightFocusNode.addListener(onFocusChange);
    repsFocusNode.addListener(onFocusChange);
  }
  
  void removeFocusListeners(VoidCallback onFocusChange) {
    weightFocusNode.removeListener(onFocusChange);
    repsFocusNode.removeListener(onFocusChange);
  }
  
  void updateWeight(double newWeight) {
    // Always mark as manually edited when user types, even if same value
    isWeightPrefilled = false;
    if (weight != newWeight) {
      weight = newWeight;
      final formatted = _fmt(newWeight);
      if (weightController.text != formatted) {
        weightController.text = formatted;
      }
    }
  }
  
  void updateReps(int newReps) {
    // Always mark as manually edited when user types, even if same value
    isRepsPrefilled = false;
    if (reps != newReps) {
      reps = newReps;
      if (repsController.text != newReps.toString()) {
        repsController.text = newReps.toString();
      }
    }
  }
  
  void dispose() {
    weightController.dispose();
    repsController.dispose();
    weightFocusNode.dispose();
    repsFocusNode.dispose();
  }
}

// Formatter to limit decimal places (2 by default)
class _DecimalTextInputFormatter extends TextInputFormatter {
  _DecimalTextInputFormatter({this.decimalRange = 2}) : assert(decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final txt = newValue.text;
    if (txt == '.') {
      return TextEditingValue(text: '0.', selection: const TextSelection.collapsed(offset: 2));
    }
    if (txt.isEmpty) return newValue;
    final reg = RegExp(r'^\d*\.?\d{0,' + decimalRange.toString() + r'}$');
    if (reg.hasMatch(txt)) return newValue;
    return oldValue;
  }
} 