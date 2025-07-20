import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class _DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  _DecimalTextInputFormatter({required this.decimalRange});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    final regExp = RegExp(r'^\d*\.?\d{0,' + decimalRange.toString() + r'}$');
    if (regExp.hasMatch(text)) {
      return newValue;
    }

    return oldValue;
  }
}

class EditableExerciseSet {
  final String id;
  double weight;
  int reps;
  bool isChecked;
  late final TextEditingController weightController;
  late final TextEditingController repsController;
  late final FocusNode weightFocusNode;
  late final FocusNode repsFocusNode;
  
  static String _formatWeight(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }
  
  static int _counter = 0;
  
  EditableExerciseSet({this.weight = 0.0, this.reps = 0, this.isChecked = false}) 
    : id = '${DateTime.now().millisecondsSinceEpoch}_${++_counter}' {
    weightController = TextEditingController(text: _formatWeight(weight));
    repsController = TextEditingController(text: reps.toString());
    weightFocusNode = FocusNode();
    repsFocusNode = FocusNode();
  }
  
  void updateWeight(double newWeight) {
    if (weight != newWeight) {
      weight = newWeight;
      final formatted = _formatWeight(newWeight);
      if (weightController.text != formatted) {
        weightController.text = formatted;
      }
    }
  }
  
  void updateReps(int newReps) {
    if (reps != newReps) {
      reps = newReps;
      if (repsController.text != newReps.toString()) {
        repsController.text = newReps.toString();
      }
    }
  }
  
  String get previousDataFormatted {
    if (weight > 0 && reps > 0) {
      final weightStr = weight % 1 == 0 ? weight.toInt().toString() : weight.toString();
      return '$weightStr × $reps';
    }
    return '—';
  }
  
  void dispose() {
    weightController.dispose();
    repsController.dispose();
    weightFocusNode.dispose();
    repsFocusNode.dispose();
  }
}

class EditableExercise {
  final String title;
  List<EditableExerciseSet> sets;
  EditableExercise({required this.title, List<EditableExerciseSet>? sets}) 
    : sets = sets ?? [EditableExerciseSet()];
}

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
  bool _isSaving = false;
  late ScrollController _scrollController;
  bool _showWorkoutNameInAppBar = false;

  @override
  void initState() {
    super.initState();
    _workoutNameController = TextEditingController(text: widget.workout.name);
    _startTime = widget.workout.date;
    _endTime = widget.workout.date.add(widget.workout.duration);
    
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    _exercises = widget.workout.exercises.map((exercise) {
      final sets = exercise.sets.map((set) => EditableExerciseSet(
        weight: set.weight,
        reps: set.reps,
        isChecked: set.isCompleted,
      )).toList();
      return EditableExercise(title: exercise.title, sets: sets);
    }).toList();
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  Future<void> _selectStartTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime),
      );
      
      if (pickedTime != null && mounted) {
        setState(() {
          _startTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(minutes: 30));
          }
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: _startTime,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime),
      );
      
      if (pickedTime != null && mounted) {
        setState(() {
          _endTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_showWorkoutNameInAppBar) {
      setState(() {
        _showWorkoutNameInAppBar = true;
      });
    } else if (_scrollController.offset <= 100 && _showWorkoutNameInAppBar) {
      setState(() {
        _showWorkoutNameInAppBar = false;
      });
    }
  }

  Future<void> _saveWorkout() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedExercises = _exercises.map((editableExercise) {
        final completedSets = editableExercise.sets.where((set) => set.isChecked).length;
        final sets = editableExercise.sets.map((editableSet) {
          return WorkoutSet(
            weight: editableSet.weight,
            reps: editableSet.reps,
            isCompleted: editableSet.isChecked,
          );
        }).toList();
        
        return WorkoutExercise(
          title: editableExercise.title,
          totalSets: editableExercise.sets.length,
          completedSets: completedSets,
          sets: sets,
        );
      }).toList();

      final duration = _endTime.difference(_startTime);
      final totalSets = updatedExercises.fold(0, (total, exercise) => total + exercise.totalSets);
      final completedSets = updatedExercises.fold(0, (total, exercise) => total + exercise.completedSets);
      
      final updatedWorkout = Workout(
        id: widget.workout.id,
        name: _workoutNameController.text,
        date: _startTime,
        duration: duration,
        exercises: updatedExercises,
        totalSets: totalSets,
        completedSets: completedSets,
        userId: widget.workout.userId,
        calories: widget.workout.calories,
      );

      await WorkoutService.updateWorkout(updatedWorkout);

      if (mounted) {
        Navigator.pop(context, updatedWorkout);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving workout: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final dateFormat = DateFormat('MMM dd');
    final timeFormat = DateFormat('HH:mm');
    final duration = _endTime.difference(_startTime);

    return Scaffold(
      backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
        foregroundColor: themeService.currentTheme.appBarTheme.foregroundColor,
        title: _showWorkoutNameInAppBar
            ? Text(
                _workoutNameController.text,
                style: TextStyle(
                  color: themeService.currentTheme.appBarTheme.titleTextStyle?.color,
                ),
              )
            : const Text('Edit Workout'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveWorkout,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            color: themeService.currentTheme.cardTheme.color,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.dumbbell,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Workout Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _workoutNameController,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeService.currentTheme.textTheme.titleLarge?.color,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _exercises.length + 1,
              itemBuilder: (context, exerciseIndex) {
                if (exerciseIndex == 0) {
                  return Card(
                    color: themeService.currentTheme.cardTheme.color,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.clock,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Workout Timing',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _selectStartTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.blue.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Start',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            FaIcon(
                                              FontAwesomeIcons.pen,
                                              color: Colors.blue.shade400,
                                              size: 10,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${dateFormat.format(_startTime)} ${timeFormat.format(_startTime)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _selectEndTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.blue.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'End',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            FaIcon(
                                              FontAwesomeIcons.pen,
                                              color: Colors.blue.shade400,
                                              size: 10,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${dateFormat.format(_endTime)} ${timeFormat.format(_endTime)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.stopwatch,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Duration: ${_formatDuration(duration)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final exercise = _exercises[exerciseIndex - 1];
                return Dismissible(
                  key: Key('exercise_${exercise.title}_${exerciseIndex - 1}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: themeService.isDarkMode ? Colors.red.shade700 : Colors.red,
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
                      _exercises.removeAt(exerciseIndex - 1);
                    });
                  },
                  child: Card(
                    color: themeService.currentTheme.cardTheme.color,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallScreen = constraints.maxWidth < 350;
                            final cardPadding = isSmallScreen ? 6.0 : 8.0;
                            final spacing = isSmallScreen ? 6.0 : 8.0;
                            final minCheckboxSize = 48.0;
                            
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
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: themeService.currentTheme.textTheme.titleMedium?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: isSmallScreen ? 35 : 45,
                                        child: Center(
                                          child: Text(
                                            'Set',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isSmallScreen ? 14 : 16,
                                              color: themeService.currentTheme.textTheme.titleMedium?.color,
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
                                              color: themeService.currentTheme.textTheme.titleMedium?.color,
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
                                                color: themeService.currentTheme.textTheme.titleMedium?.color,
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
                                                color: themeService.currentTheme.textTheme.titleMedium?.color,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: spacing),
                                      SizedBox(
                                        width: minCheckboxSize,
                                        height: minCheckboxSize,
                                        child: Center(
                                          child: Checkbox(
                                            value: exercise.sets.every((set) => set.isChecked),
                                            tristate: true,
                                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                              if (states.contains(WidgetState.selected)) {
                                                return Colors.green;
                                              }
                                              return themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300;
                                            }),
                                            onChanged: (val) {
                                              HapticFeedback.lightImpact();
                                              setState(() {
                                                bool newValue = val ?? false;
                                                for (var set in exercise.sets) {
                                                  set.isChecked = newValue;
                                                }
                                              });
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
                                  ...exercise.sets.asMap().entries.map((entry) {
                                    int setIndex = entry.key;
                                    EditableExerciseSet exerciseSet = entry.value;
                                    return Dismissible(
                                      key: Key('${exercise.title}_${exerciseSet.id}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        margin: const EdgeInsets.symmetric(vertical: 2),
                                        color: themeService.isDarkMode ? Colors.red.shade700 : Colors.red,
                                        child: const FaIcon(
                                          FontAwesomeIcons.trash,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      onDismissed: (direction) {
                                        setState(() {
                                          exercise.sets.remove(exerciseSet);
                                          exerciseSet.dispose();
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        color: exerciseSet.isChecked 
                                            ? (themeService.isDarkMode ? Colors.green.shade900 : Colors.green.shade100) 
                                            : Colors.transparent,
                                        padding: const EdgeInsets.all(4),
                                        margin: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          children: [
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
                                                    controller: exerciseSet.weightController,
                                                    focusNode: exerciseSet.weightFocusNode,
                                                    autofocus: false,
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
                                                    inputFormatters: [_DecimalTextInputFormatter(decimalRange: 2)],
                                                    onChanged: (val) {
                                                      final newWeight = double.tryParse(val) ?? 0.0;
                                                      setState(() {
                                                        exerciseSet.updateWeight(newWeight);
                                                      });
                                                    },
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
                                                    maxHeight: 28,
                                                  ),
                                                  child: TextFormField(
                                                    controller: exerciseSet.repsController,
                                                    focusNode: exerciseSet.repsFocusNode,
                                                    autofocus: false,
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
                                                    onChanged: (val) {
                                                      final newReps = int.tryParse(val) ?? 0;
                                                      setState(() {
                                                        exerciseSet.updateReps(newReps);
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: spacing),
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
                                                    return themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300;
                                                  }),
                                                  onChanged: (val) {
                                                    HapticFeedback.lightImpact();
                                                    setState(() {
                                                      exerciseSet.isChecked = val ?? false;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
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
                                exercise.sets.add(EditableExerciseSet());
                              });
                            },
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
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
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
                        final newExercises = result.map((title) => EditableExercise(
                          title: title,
                          sets: [EditableExerciseSet()],
                        )).toList();
                        _exercises.addAll(newExercises);
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
        ],
      ),
    );
  }
} 