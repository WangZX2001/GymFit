import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:gymfit/pages/workout/workout_name_description_page.dart';

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
      // Creating new workout - use exercise names with empty sets
      _exercises = widget.exerciseNames.map((name) => ConfigExercise(title: name)).toList();
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
          FocusScope.of(context).unfocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
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
          FocusScope.of(context).unfocus();
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
                    setState(() {
                      _exercises.removeAt(index);
                    });
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
                                            // Weight - flexible
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  'Weight (kg)',
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
                                            // Reps - flexible
                                            Expanded(
                                              flex: 2,
                                              child: Center(
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
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...exercise.sets.asMap().entries.map((entry) {
                                    final setIndex = entry.key;
                                    final set = entry.value;
                                    return Dismissible(
                                      key: Key('${exercise.title}_${set.id}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        margin: const EdgeInsets.symmetric(vertical: 2),
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
                                        padding: const EdgeInsets.all(4),
                                        margin: const EdgeInsets.symmetric(vertical: 2),
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
                                                // Weight input - flexible
                                                Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: ConstrainedBox(
                                                      constraints: BoxConstraints(
                                                        maxWidth: isSmallScreen ? 60 : 80,
                                                        minWidth: 50,
                                                      ),
                                                                                                              child: TextFormField(
                                                          controller: set.weightController,
                                                          focusNode: set.weightFocusNode,
                                                          readOnly: _preventAutoFocus,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: isSmallScreen ? 14 : 16,
                                                          ),
                                                          textAlign: TextAlign.center,
                                                        decoration: InputDecoration(
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide.none,
                                                          ),
                                                          filled: true,
                                                          fillColor: Colors.grey.shade300,
                                                          contentPadding: EdgeInsets.symmetric(
                                                            horizontal: isSmallScreen ? 4 : 6,
                                                            vertical: 4,
                                                          ),
                                                        ),
                                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                        inputFormatters: [_DecimalTextInputFormatter(decimalRange: 2)],
                                                        onTap: () {
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
                                                          set.weight = double.tryParse(value) ?? 0.0;
                                                          set._weightSelected = false; // Reset selection state when typing
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
                                                        maxWidth: isSmallScreen ? 60 : 80,
                                                        minWidth: 50,
                                                      ),
                                                                                                              child: TextFormField(
                                                          controller: set.repsController,
                                                          focusNode: set.repsFocusNode,
                                                          readOnly: _preventAutoFocus,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: isSmallScreen ? 14 : 16,
                                                          ),
                                                          textAlign: TextAlign.center,
                                                        decoration: InputDecoration(
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide.none,
                                                          ),
                                                          filled: true,
                                                          fillColor: Colors.grey.shade300,
                                                          contentPadding: EdgeInsets.symmetric(
                                                            horizontal: isSmallScreen ? 4 : 6,
                                                            vertical: 4,
                                                          ),
                                                        ),
                                                        keyboardType: TextInputType.number,
                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                        onTap: () {
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
                                                          set.reps = int.tryParse(value) ?? 0;
                                                          set._repsSelected = false; // Reset selection state when typing
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
                            onPressed: () {
                              setState(() {
                                final newSet = ConfigSet();
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isAnyFieldFocused ? 0 : null,
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
                                setState(() {
                                  _preventAutoFocus = true; // Temporarily disable interaction
                                  // Append new exercises as ConfigExercise entries
                                  final newExercises = result.map((title) => ConfigExercise(title: title)).toList();
                                  // Add focus listeners to new exercises
                                  for (var exercise in newExercises) {
                                    for (var set in exercise.sets) {
                                      set.addFocusListeners(_updateFocusState);
                                    }
                                  }
                                  _exercises.addAll(newExercises);
                                });
                                
                                // Re-enable interaction after build is complete
                                Future.microtask(() {
                                  if (mounted) {
                                    setState(() {
                                      _preventAutoFocus = false;
                                    });
                                  }
                                });
                              } else if (mounted) {
                                // Apply auto-focus prevention even when no exercises are selected
                                setState(() {
                                  _preventAutoFocus = true;
                                });
                                
                                Future.microtask(() {
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
        ],
      ),
        ),
    );
  }
}

class ConfigExercise {
  final String title;
  List<ConfigSet> sets;
  
  ConfigExercise({required this.title}) : sets = [ConfigSet()];
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
  
  static int _counter = 0;
  
  // Helper to format weight display (strip trailing .0)
  static String _fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();
  
  ConfigSet() : id = '${DateTime.now().millisecondsSinceEpoch}_${++_counter}' {
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