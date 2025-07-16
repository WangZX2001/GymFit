import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:gymfit/pages/workout/workout_summary_page.dart';

import 'package:gymfit/models/workout.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/services/custom_workout_service.dart';
import 'package:gymfit/services/workout_service.dart';

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

// Model to track individual set data
class ExerciseSet {
  final String id;
  double weight;
  int reps;
  bool isChecked;
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
  
  // Helper to format weight: whole number if no decimal part
  static String _formatWeight(double value) {
    if (value % 1 == 0) {
      // Whole number – show without decimal
      return value.toInt().toString();
    }
    return value.toString();
  }
  
  // Helper to format previous data as "20kg x 5"
  String get previousDataFormatted {
    if (previousWeight != null && previousReps != null) {
      return '${_formatWeight(previousWeight!)}kg x $previousReps';
    }
    return '-';
  }
  
  static int _counter = 0;
  
  ExerciseSet({this.weight = 0.0, this.reps = 0, this.isChecked = false, this.isWeightPrefilled = false, this.isRepsPrefilled = false, this.previousWeight, this.previousReps}) 
    : id = '${DateTime.now().millisecondsSinceEpoch}_${++_counter}' {
    weightController = TextEditingController(text: _formatWeight(weight));
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
      final formatted = _formatWeight(newWeight);
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

// Model to track exercise with multiple sets
class QuickStartExercise {
  final String title;
  List<ExerciseSet> sets;
  QuickStartExercise({required this.title, List<ExerciseSet>? sets}) 
    : sets = sets ?? [ExerciseSet()];
}

class QuickStartPage extends StatefulWidget {
  final List<QuickStartExercise> initialSelectedExercises;
  final String? initialWorkoutName;
  final bool showMinibarOnMinimize;
  const QuickStartPage({
    super.key, 
    this.initialSelectedExercises = const <QuickStartExercise>[], 
    this.initialWorkoutName,
    this.showMinibarOnMinimize = true,
  });

  @override
  State<QuickStartPage> createState() => _QuickStartPageState();
}

class _QuickStartPageState extends State<QuickStartPage> {
  List<QuickStartExercise> _selectedExercises = [];
  late ScrollController _scrollController;
  bool _showWorkoutNameInAppBar = false;
  String? _customWorkoutName;
  List<CustomWorkout> _customWorkouts = [];
  bool _loadingCustomWorkouts = false;
  bool _isEditingWorkoutName = false;
  late TextEditingController _workoutNameController;
  bool _isAnyFieldFocused = false;
  bool _preventAutoFocus = false;

  @override
  void initState() {
    super.initState();
    _selectedExercises = widget.initialSelectedExercises.map((e) => QuickStartExercise(title: e.title, sets: e.sets)).toList();
    _customWorkoutName = widget.initialWorkoutName; // Set the initial workout name
    
    // Initialize text controller
    _workoutNameController = TextEditingController(text: _customWorkoutName ?? '');
    
    // Initialize scroll controller
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Start the shared timer in overlay if not already started
    QuickStartOverlay.startTimer();
    
    // Register for timer updates
    QuickStartOverlay.setPageUpdateCallback(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Add focus listeners to existing exercises
    _setupFocusListeners();

    // Load custom workouts if no exercises are selected
    if (_selectedExercises.isEmpty) {
      _loadCustomWorkouts();
    }
  }

  void _setupFocusListeners() {
    for (var exercise in _selectedExercises) {
      for (var set in exercise.sets) {
        set.addFocusListeners(_updateFocusState);
      }
    }
  }

  void _removeFocusListeners() {
    for (var exercise in _selectedExercises) {
      for (var set in exercise.sets) {
        set.removeFocusListeners(_updateFocusState);
      }
    }
  }

  Future<void> _loadCustomWorkouts() async {
    setState(() {
      _loadingCustomWorkouts = true;
    });

    try {
      final workouts = await CustomWorkoutService.getPinnedCustomWorkouts();
      setState(() {
        _customWorkouts = workouts;
        _loadingCustomWorkouts = false;
      });
    } catch (e) {
      setState(() {
        _loadingCustomWorkouts = false;
      });
    }
  }

  void _loadCustomWorkout(CustomWorkout workout) {
    // Convert custom workout exercises to QuickStartExercise objects with configured sets
    final exercises = workout.exercises.map((customExercise) {
      final sets = customExercise.sets.map((customSet) => 
        ExerciseSet(weight: customSet.weight, reps: customSet.reps, isWeightPrefilled: false, isRepsPrefilled: false, previousWeight: null, previousReps: null)
      ).toList();
      
      return QuickStartExercise(title: customExercise.name, sets: sets);
    }).toList();

    // Update both local state and overlay, and set the custom workout name
    setState(() {
      _selectedExercises = exercises;
      _customWorkoutName = workout.name; // Use the saved workout name
      // Add focus listeners to loaded exercises
      for (var exercise in _selectedExercises) {
        for (var set in exercise.sets) {
          set.addFocusListeners(_updateFocusState);
        }
      }
      QuickStartOverlay.selectedExercises = _selectedExercises;
    });
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

  void _toggleWorkoutNameEditing() {
    setState(() {
      if (_isEditingWorkoutName) {
        // Save the workout name
        _customWorkoutName = _workoutNameController.text.trim();
        _isEditingWorkoutName = false;
      } else {
        // Start editing
        _workoutNameController.text = _customWorkoutName ?? _getWorkoutName();
        _isEditingWorkoutName = true;
      }
    });
  }

  void _onWorkoutNameSubmitted() {
    setState(() {
      _customWorkoutName = _workoutNameController.text.trim();
      _isEditingWorkoutName = false;
    });
  }

  void _updateFocusState() {
    bool anyFieldFocused = false;
    for (var exercise in _selectedExercises) {
      for (var set in exercise.sets) {
        if (set.weightFocusNode.hasFocus || set.repsFocusNode.hasFocus) {
          anyFieldFocused = true;
          break;
        }
      }
      if (anyFieldFocused) break;
    }
    
    if (_isAnyFieldFocused != anyFieldFocused) {
      setState(() {
        _isAnyFieldFocused = anyFieldFocused;
      });
    }
  }

  @override
  void dispose() {
    // Clear the page update callback
    QuickStartOverlay.setPageUpdateCallback(null);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _workoutNameController.dispose();
    _removeFocusListeners();
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

  String _getWorkoutName() {
    // Return custom name if set
    if (_customWorkoutName != null && _customWorkoutName!.isNotEmpty) {
      return _customWorkoutName!;
    }
    
    final startTime = QuickStartOverlay.startTime ?? DateTime.now().subtract(QuickStartOverlay.elapsedTime);
    
    // If no exercises selected, show a generic name based on time
    if (_selectedExercises.isEmpty) {
      final hour = startTime.hour;
      String timeOfDay;
      
      if (hour >= 5 && hour < 12) {
        timeOfDay = 'Morning';
      } else if (hour >= 12 && hour < 17) {
        timeOfDay = 'Afternoon';
      } else if (hour >= 17 && hour < 21) {
        timeOfDay = 'Evening';
      } else {
        timeOfDay = 'Night';
      }
      
      return '$timeOfDay Workout';
    }
    
    return Workout.generateDefaultName(
      startTime: startTime,
      workoutDuration: QuickStartOverlay.elapsedTime,
      exerciseNames: _selectedExercises.map((e) => e.title).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronDown, color: Colors.black, size: 20),
          onPressed: () {
            QuickStartOverlay.selectedExercises = _selectedExercises;
            if (widget.showMinibarOnMinimize) {
              QuickStartOverlay.minimize(context);
            } else {
              QuickStartOverlay.minimizeWithoutMinibar(context);
            }
          },
        ),
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
                      child: GestureDetector(
                        onTap: _toggleWorkoutNameEditing,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _getWorkoutName(),
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const FaIcon(
                              FontAwesomeIcons.pen,
                              color: Colors.purple,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('timer'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.stopwatch,
                      color: Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(QuickStartOverlay.elapsedTime),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          // Show timer when workout name is in app bar
          if (_showWorkoutNameInAppBar)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.stopwatch,
                    color: Colors.black54,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(QuickStartOverlay.elapsedTime),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    QuickStartOverlay.togglePause();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: FaIcon(
                      QuickStartOverlay.isPaused ? FontAwesomeIcons.play : FontAwesomeIcons.pause,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () async {
                    if (!mounted) return;
                    final navigator = Navigator.of(context);
                    final bool? confirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Cancel Workout'),
                          content: const Text('Are you sure you want to cancel this workout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Yes'),
                            ),
                          ],
                        );
                      },
                    );

                    if (mounted && confirmed == true) {
                      QuickStartOverlay.selectedExercises = [];
                      QuickStartOverlay.resetTimer();
                      navigator.pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const FaIcon(
                      FontAwesomeIcons.xmark,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside of input fields
            FocusScope.of(context).unfocus();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 350;
              final mainPadding = isSmallScreen ? 12.0 : 16.0;
              
              return Padding(
                padding: EdgeInsets.fromLTRB(mainPadding, mainPadding, mainPadding, 0.0),
                child: Column(
                children: [
                  // Workout Name Display at the top with smooth transition
                  AnimatedSize(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutQuart,
                    child: _showWorkoutNameInAppBar
                        ? const SizedBox.shrink()
                        :                           Card(
                            color: Colors.white,
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
                                        const Text(
                                          'Workout Name',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
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
                                                  hintStyle: TextStyle(color: Colors.grey.shade400),
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
                                                    _getWorkoutName(),
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
                  
                  Expanded(
                    child: _selectedExercises.isEmpty
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 120),
                                const FaIcon(
                                  FontAwesomeIcons.dumbbell,
                                  size: 48,
                                  color: Colors.black,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Let\'s get moving!',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add an exercise to get started',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Custom workout suggestions
                                if (_loadingCustomWorkouts) ...[
                                  const SizedBox(height: 80),
                                  const CircularProgressIndicator(),
                                ] else if (_customWorkouts.isNotEmpty) ...[
                                  const SizedBox(height: 80),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.push_pin,
                                        color: Colors.grey.shade700,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Pinned',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  for (int i = 0; i < _customWorkouts.length; i++) ...[
                                                                        if (i > 0) ...[
                                      Divider(
                                        color: Colors.grey.shade600,
                                        thickness: 0.5,
                                        indent: 16,
                                        endIndent: 16,
                                        height: 1,
                                      ),
                                    ],
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 2),
                                      child: ListTile(
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const FaIcon(
                                            FontAwesomeIcons.dumbbell,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          _customWorkouts[i].name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${_customWorkouts[i].exerciseNames.length} exercises',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.play_arrow,
                                          color: Colors.green,
                                        ),
                                        tileColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        onTap: () => _loadCustomWorkout(_customWorkouts[i]),
                                      ),
                                    ),
                                  ],
                                ] else ...[
                                  const SizedBox(height: 80),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.push_pin_outlined,
                                          size: 32,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No pinned workouts',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pin your favorite workouts to see them here',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            controller: _scrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  children: _selectedExercises
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) {
                                          final index = entry.key;
                                          final e = entry.value;
                                          return Dismissible(
                                            key: Key('exercise_${e.title}_$index'),
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
                                                _selectedExercises.remove(e);
                                                QuickStartOverlay.selectedExercises = _selectedExercises;
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
                                                                  e.title,
                                                                  style: const TextStyle(
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Column(
                                                              children: [
                                                                LayoutBuilder(
                                                                builder: (context, constraints) {
                                                                  final availableWidth = constraints.maxWidth;
                                                                  final isSmallScreen = availableWidth < 350;
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
                                                                            value: e.sets.every((set) => set.isChecked),
                                                                            tristate: true,
                                                                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                                                              if (states.contains(WidgetState.selected)) {
                                                                                return Colors.green;
                                                                              }
                                                                              return Colors.grey.shade300;
                                                                            }),
                                                                            onChanged: (val) {
                                                                              HapticFeedback.lightImpact();
                                                                              setState(() {
                                                                                bool newValue = val ?? false;
                                                                                for (var set in e.sets) {
                                                                                  set.isChecked = newValue;
                                                                                }
                                                                                QuickStartOverlay.selectedExercises = _selectedExercises;
                                                                              });
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
                                                            ...e.sets.asMap().entries.map((entry) {
                                                              int setIndex = entry.key;
                                                              ExerciseSet exerciseSet = entry.value;
                                                              return Dismissible(
                                                                key: Key('${e.title}_${exerciseSet.id}'),
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
                                                                  setState(() {
                                                                    e.sets.remove(exerciseSet);
                                                                    QuickStartOverlay.selectedExercises = _selectedExercises;
                                                                  });
                                                                },
                                                                child: Container(
                                                                  width: double.infinity,
                                                                  color: exerciseSet.isChecked ? Colors.green.shade100 : Colors.transparent,
                                                                  padding: const EdgeInsets.all(1),
                                                                  margin: const EdgeInsets.symmetric(vertical: 0),
                                                                  child: LayoutBuilder(
                                                                    builder: (context, constraints) {
                                                                      final availableWidth = constraints.maxWidth;
                                                                      final isSmallScreen = availableWidth < 350;
                                                                      final spacing = isSmallScreen ? 6.0 : 8.0;
                                                                      final minCheckboxSize = 48.0;
                                                                      
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
                                                                exerciseSet.previousDataFormatted,
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
                                                                                  controller: exerciseSet.weightController,
                                                                                  focusNode: exerciseSet.weightFocusNode,
                                                                                  autofocus: false,
                                                                                  readOnly: _preventAutoFocus,
                                                                                  style: TextStyle(
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontSize: isSmallScreen ? 14 : 16,
                                                                                    color: exerciseSet.isChecked 
                                                                                        ? Colors.black 
                                                                                        : (exerciseSet.isWeightPrefilled 
                                                                                            ? Colors.grey.shade500 
                                                                                            : Colors.black),
                                                                                  ),
                                                                                  textAlign: TextAlign.center,
                                                                                  decoration: InputDecoration(
                                                                                    border: OutlineInputBorder(
                                                                                      borderRadius: BorderRadius.circular(8),
                                                                                      borderSide: BorderSide(
                                                                                        color: exerciseSet.isChecked ? Colors.green : Colors.grey.shade400,
                                                                                        width: 1,
                                                                                      ),
                                                                                    ),
                                                                                    enabledBorder: OutlineInputBorder(
                                                                                      borderRadius: BorderRadius.circular(8),
                                                                                      borderSide: BorderSide(
                                                                                        color: exerciseSet.isChecked ? Colors.green : Colors.grey.shade400,
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
                                                                                      exerciseSet.isWeightPrefilled = false;
                                                                                    });
                                                                                    
                                                                                    // Toggle selection state based on our tracking
                                                                                    if (exerciseSet._weightSelected) {
                                                                                      // Clear selection
                                                                                      exerciseSet.weightController.selection = TextSelection.collapsed(
                                                                                        offset: exerciseSet.weightController.text.length,
                                                                                      );
                                                                                      exerciseSet._weightSelected = false;
                                                                                    } else {
                                                                                      // Select all text
                                                                                      exerciseSet.weightController.selection = TextSelection(
                                                                                        baseOffset: 0, 
                                                                                        extentOffset: exerciseSet.weightController.text.length,
                                                                                      );
                                                                                      exerciseSet._weightSelected = true;
                                                                                    }
                                                                                  },
                                                                                  onChanged: (val) {
                                                                                    final newWeight = double.tryParse(val) ?? 0.0;
                                                                                    setState(() {
                                                                                      exerciseSet.updateWeight(newWeight);
                                                                                      exerciseSet._weightSelected = false; // Reset selection state when typing
                                                                                      QuickStartOverlay.selectedExercises = _selectedExercises;
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
                                                                                  controller: exerciseSet.repsController,
                                                                                  focusNode: exerciseSet.repsFocusNode,
                                                                                  autofocus: false,
                                                                                  enableInteractiveSelection: true,
                                                                                  readOnly: _preventAutoFocus,
                                                                                  style: TextStyle(
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontSize: isSmallScreen ? 14 : 16,
                                                                                    color: exerciseSet.isChecked 
                                                                                        ? Colors.black 
                                                                                        : (exerciseSet.isRepsPrefilled 
                                                                                            ? Colors.grey.shade500 
                                                                                            : Colors.black),
                                                                                  ),
                                                                                  textAlign: TextAlign.center,
                                                                                  decoration: InputDecoration(
                                                                                    border: OutlineInputBorder(
                                                                                      borderRadius: BorderRadius.circular(8),
                                                                                      borderSide: BorderSide(
                                                                                        color: exerciseSet.isChecked ? Colors.green : Colors.grey.shade400,
                                                                                        width: 1,
                                                                                      ),
                                                                                    ),
                                                                                    enabledBorder: OutlineInputBorder(
                                                                                      borderRadius: BorderRadius.circular(8),
                                                                                      borderSide: BorderSide(
                                                                                        color: exerciseSet.isChecked ? Colors.green : Colors.grey.shade400,
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
                                                                                      exerciseSet.isRepsPrefilled = false;
                                                                                    });
                                                                                    
                                                                                    // Toggle selection state based on our tracking
                                                                                    if (exerciseSet._repsSelected) {
                                                                                      // Clear selection
                                                                                      exerciseSet.repsController.selection = TextSelection.collapsed(
                                                                                        offset: exerciseSet.repsController.text.length,
                                                                                      );
                                                                                      exerciseSet._repsSelected = false;
                                                                                    } else {
                                                                                      // Select all text
                                                                                      exerciseSet.repsController.selection = TextSelection(
                                                                                        baseOffset: 0, 
                                                                                        extentOffset: exerciseSet.repsController.text.length,
                                                                                      );
                                                                                      exerciseSet._repsSelected = true;
                                                                                    }
                                                                                  },
                                                                                  onChanged: (val) {
                                                                                    final newReps = int.tryParse(val) ?? 0;
                                                                                    setState(() {
                                                                                      exerciseSet.updateReps(newReps);
                                                                                      exerciseSet._repsSelected = false; // Reset selection state when typing
                                                                                      QuickStartOverlay.selectedExercises = _selectedExercises;
                                                                                    });
                                                                                  },
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
                                                                                value: exerciseSet.isChecked,
                                                                                fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                                                                  if (states.contains(WidgetState.selected)) {
                                                                                    return Colors.green;
                                                                                  }
                                                                                  return Colors.grey.shade300;
                                                                                }),
                                                                                onChanged: (val) {
                                                                                  HapticFeedback.lightImpact();
                                                                                  setState(() {
                                                                                    exerciseSet.isChecked = val ?? false;
                                                                                    QuickStartOverlay.selectedExercises = _selectedExercises;
                                                                                  });
                                                                                },
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
                                                        ExerciseSet newSet;
                                                        if (e.sets.isNotEmpty) {
                                                          // Use data from the last set in current exercise
                                                          final lastSet = e.sets.last;
                                                          newSet = ExerciseSet(
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
                                                             final previousData = await WorkoutService.getLastExerciseData(e.title);
                                                             if (previousData != null && previousData['sets'] != null) {
                                                               final previousSetsData = previousData['sets'] as List<dynamic>;
                                                               if (previousSetsData.isNotEmpty) {
                                                                 // Use the last set from previous workout
                                                                 final lastSetData = previousSetsData.last;
                                                                 final weight = (lastSetData['weight'] as num?)?.toDouble() ?? 0.0;
                                                                 final reps = (lastSetData['reps'] as int?) ?? 0;
                                                                                                                                   newSet = ExerciseSet(
                                                                     weight: weight, 
                                                                     reps: reps, 
                                                                     isWeightPrefilled: true, 
                                                                     isRepsPrefilled: true,
                                                                     previousWeight: weight,
                                                                     previousReps: reps,
                                                                   );
                                                               } else {
                                                                 newSet = ExerciseSet();
                                                               }
                                                             } else {
                                                               newSet = ExerciseSet();
                                                             }
                                                           } catch (e) {
                                                             newSet = ExerciseSet();
                                                           }
                                                         }
                                                        
                                                        setState(() {
                                                          newSet.addFocusListeners(_updateFocusState);
                                                          e.sets.add(newSet);
                                                          QuickStartOverlay.selectedExercises = _selectedExercises;
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
                                      ).toList(),
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
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              // Add haptic feedback when finish button is pressed
                                              HapticFeedback.heavyImpact();
                                              
                                              // Navigate to workout summary page
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => WorkoutSummaryPage(
                                                    completedExercises: _selectedExercises,
                                                    workoutDuration: QuickStartOverlay.elapsedTime,
                                                    customWorkoutName: _customWorkoutName,
                                                  ),
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: Colors.white.withValues(alpha: 0.9),
                                              foregroundColor: Colors.black,
                                              side: BorderSide(
                                                color: Colors.grey.shade300.withValues(alpha: 0.8),
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: buttonPadding,
                                            ),
                                            icon: FaIcon(
                                              FontAwesomeIcons.flagCheckered,
                                              color: Colors.black,
                                              size: buttonFontSize * 0.8,
                                            ),
                                            label: Text(
                                              'Finish',
                                              style: TextStyle(
                                                color: Colors.black, 
                                                fontSize: buttonFontSize, 
                                                fontWeight: FontWeight.w900
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                  ),
                  // Add Exercises button with keyboard-aware visibility
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _isAnyFieldFocused ? 0 : null,
                    child: _isAnyFieldFocused 
                        ? const SizedBox.shrink()
                        : Column(
                            children: [
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
                                            _preventAutoFocus = true; // Temporarily disable interaction
                                          });
                                          
                                          // Create new exercises with prefilled data
                                          final List<QuickStartExercise> newExercises = [];
                                          
                                          for (final title in result) {
                                            try {
                                              // Try to get previous exercise data
                                              final previousData = await WorkoutService.getLastExerciseData(title);
                                              
                                              List<ExerciseSet> sets;
                                              if (previousData != null && previousData['sets'] != null) {
                                                // Create sets based on previous workout data
                                                final previousSetsData = previousData['sets'] as List<dynamic>;
                                                
                                                sets = previousSetsData.map((setData) {
                                                  final weight = (setData['weight'] as num?)?.toDouble() ?? 0.0;
                                                  final reps = (setData['reps'] as int?) ?? 0;
                                                  return ExerciseSet(
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
                                                sets = [ExerciseSet()];
                                              }
                                              
                                              newExercises.add(QuickStartExercise(title: title, sets: sets));
                                            } catch (e) {
                                              // If there's an error fetching data, use default
                                              newExercises.add(QuickStartExercise(title: title));
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
                                              _selectedExercises.addAll(newExercises);
                                              QuickStartOverlay.selectedExercises = _selectedExercises;
                                            });
                                          }
                                          
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
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      ),
    );
  }
} 