import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';
import 'package:intl/intl.dart';

// Input formatter to restrict decimals to a fixed number of places (default 2)
class _DecimalTextInputFormatter extends TextInputFormatter {
  _DecimalTextInputFormatter({this.decimalRange = 2}) : assert(decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    if (text == '.') {
      // Prefix lone decimal with 0
      return TextEditingValue(
        text: '0.',
        selection: const TextSelection.collapsed(offset: 2),
      );
    }

    // Allow empty input
    if (text.isEmpty) {
      return newValue;
    }

    final regExp = RegExp(r'^\d*\.?\d{0,' + decimalRange.toString() + r'}$');
    if (regExp.hasMatch(text)) {
      return newValue;
    }

    // Reject invalid additions by returning old value
    return oldValue;
  }
}

// Model to track individual set data for editing
class EditableExerciseSet {
  final String id;
  double weight;
  int reps;
  bool isChecked;
  late final TextEditingController weightController;
  late final TextEditingController repsController;
  late final FocusNode weightFocusNode;
  late final FocusNode repsFocusNode;
  
  // Helper to format weight: whole number if no decimal part
  static String _formatWeight(double value) {
    if (value % 1 == 0) {
      // Whole number – show without decimal
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
  
  // Get formatted previous data (similar to ExerciseSet)
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

// Model to track exercise with multiple sets for editing
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
  bool _isEditingWorkoutName = false;
  bool _isSaving = false;
  late ScrollController _scrollController;
  bool _showWorkoutNameInAppBar = false;

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

  void _toggleWorkoutNameEditing() {
    setState(() {
      _isEditingWorkoutName = !_isEditingWorkoutName;
    });
  }

  void _onWorkoutNameSubmitted() {
    setState(() {
      _isEditingWorkoutName = false;
    });
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
          
          // Ensure end time is after start time
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
        final newEndTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        if (newEndTime.isAfter(_startTime)) {
          setState(() {
            _endTime = newEndTime;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveWorkout() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Convert editable exercises back to workout format
      final updatedExercises = _exercises.map((exercise) {
        final sets = exercise.sets.map((set) => WorkoutSet(
          weight: set.weight,
          reps: set.reps,
          isCompleted: set.isChecked,
        )).toList();
        
        final completedSets = sets.where((set) => set.isCompleted).length;
        return WorkoutExercise(
          title: exercise.title,
          totalSets: sets.length,
          completedSets: completedSets,
          sets: sets,
        );
      }).toList();

      final totalSets = updatedExercises.fold(0, (total, exercise) => total + exercise.totalSets);
      final completedSets = updatedExercises.fold(0, (total, exercise) => total + exercise.completedSets);

      final updatedWorkout = Workout(
        id: widget.workout.id,
        name: _workoutNameController.text.trim(),
        date: _startTime,
        duration: _endTime.difference(_startTime),
        exercises: updatedExercises,
        totalSets: totalSets,
        completedSets: completedSets,
        userId: widget.workout.userId,
      );

      await WorkoutService.updateWorkout(updatedWorkout);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate successful save
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _onScroll() {
    // Show workout name in app bar when scrolled past the workout name card (approximately 100 pixels)
    const double threshold = 100.0;
    bool shouldShow = _scrollController.offset > threshold;
    
    if (shouldShow != _showWorkoutNameInAppBar) {
      setState(() {
        _showWorkoutNameInAppBar = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final duration = _endTime.difference(_startTime);

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
            FocusScope.of(context).unfocus();
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Workout Name Card with smooth transition
                AnimatedSize(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuart,
                  child: _showWorkoutNameInAppBar
                      ? const SizedBox.shrink()
                      : Card(
                          color: themeService.currentTheme.cardTheme.color,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.tag,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Workout Name',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _isEditingWorkoutName
                                          ? TextField(
                                              controller: _workoutNameController,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(color: Colors.purple),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(color: Colors.purple, width: 2),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                hintText: 'Enter workout name',
                                                hintStyle: TextStyle(
                                                  color: themeService.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                                                ),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.purple,
                                              ),
                                              maxLength: 50,
                                              autofocus: true,
                                              onSubmitted: (_) => _onWorkoutNameSubmitted(),
                                              textInputAction: TextInputAction.done,
                                            )
                                          : GestureDetector(
                                              onTap: _toggleWorkoutNameEditing,
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.transparent, width: 1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _workoutNameController.text.isEmpty 
                                                      ? 'Untitled Workout' 
                                                      : _workoutNameController.text,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.purple,
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _toggleWorkoutNameEditing,
                                  icon: FaIcon(
                                    _isEditingWorkoutName ? FontAwesomeIcons.check : FontAwesomeIcons.pen,
                                    color: _isEditingWorkoutName ? Colors.green : Colors.grey,
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

                // Exercise List with timing card
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _exercises.length + 1, // +1 for timing card
                    itemBuilder: (context, exerciseIndex) {
                      // Show timing card as first item
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
                      
                      // Show exercises (adjust index since timing card is first)
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
                                            // Set number - fixed small width
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
                                            SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                                            // Previous - flexible
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
                                            SizedBox(width: isSmallScreen ? 6.0 : 8.0),
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
                                                      color: themeService.currentTheme.textTheme.titleMedium?.color,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: isSmallScreen ? 6.0 : 8.0),
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
                                                      color: themeService.currentTheme.textTheme.titleMedium?.color,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                                            // Checkbox - fixed minimum size
                                            SizedBox(
                                              width: 48.0,
                                              height: 48.0,
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
                                                  SizedBox(width: isSmallScreen ? 6.0 : 8.0),
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
                                                  SizedBox(width: isSmallScreen ? 6.0 : 8.0),
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
                                                  SizedBox(width: isSmallScreen ? 6.0 : 8.0),
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
                                                  SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                                                  // Checkbox - fixed minimum size
                                                  SizedBox(
                                                    width: 48.0,
                                                    height: 48.0,
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
                        ),
                      );
                    },
                  ),
                ),
                // Add Exercises button at the bottom
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
                              // Add new exercises to the existing list
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
          ),
        ),
      ),
    );
  }
} 