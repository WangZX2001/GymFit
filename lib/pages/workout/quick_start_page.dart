import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:gymfit/pages/workout/workout_summary_page.dart';
import 'package:gymfit/models/workout.dart';

// Model to track individual set data
class ExerciseSet {
  final String id;
  int weight;
  int reps;
  bool isChecked;
  ExerciseSet({this.weight = 0, this.reps = 0, this.isChecked = false}) 
    : id = '${DateTime.now().millisecondsSinceEpoch}_${weight * 1000 + reps}';
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
  const QuickStartPage({super.key, this.initialSelectedExercises = const <QuickStartExercise>[]});

  @override
  State<QuickStartPage> createState() => _QuickStartPageState();
}

class _QuickStartPageState extends State<QuickStartPage> {
  List<QuickStartExercise> _selectedExercises = [];
  late ScrollController _scrollController;
  bool _showWorkoutNameInAppBar = false;
  String? _customWorkoutName;

  @override
  void initState() {
    super.initState();
    _selectedExercises = widget.initialSelectedExercises.map((e) => QuickStartExercise(title: e.title, sets: e.sets)).toList();
    
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

  void _showEditWorkoutNameDialog() {
    final TextEditingController controller = TextEditingController(
      text: _customWorkoutName ?? _getWorkoutName(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Workout Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter workout name',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _customWorkoutName = controller.text.trim();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Clear the page update callback
    QuickStartOverlay.setPageUpdateCallback(null);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronDown, color: Colors.black),
          onPressed: () {
            QuickStartOverlay.selectedExercises = _selectedExercises;
            QuickStartOverlay.minimize(context);
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
                        onTap: _showEditWorkoutNameDialog,
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
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.stopwatch,
                      color: Colors.black87,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(QuickStartOverlay.elapsedTime),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: FaIcon(
              QuickStartOverlay.isPaused ? FontAwesomeIcons.play : FontAwesomeIcons.pause,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () {
              QuickStartOverlay.togglePause();
            },
          ),
        ],
      ),
      body: SafeArea(
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
                        : Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
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
                                        Row(
                                          children: [
                                            const Text(
                                              'Workout Name',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (_customWorkoutName != null && _customWorkoutName!.isNotEmpty)
                                              Container(
                                                margin: const EdgeInsets.only(left: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Custom',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.purple,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getWorkoutName(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _showEditWorkoutNameDialog,
                                    icon: const FaIcon(
                                      FontAwesomeIcons.pen,
                                      color: Colors.grey,
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
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                                      .map(
                                        (e) => Card(
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
                                                            IconButton(
                                                              icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red, size: 18),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _selectedExercises.remove(e);
                                                                  QuickStartOverlay.selectedExercises = _selectedExercises;
                                                                });
                                                              },
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
                                                        ),
                                                        const SizedBox(height: 8),
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
                                                              padding: const EdgeInsets.all(4),
                                                              margin: const EdgeInsets.symmetric(vertical: 2),
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
                                                                              initialValue: exerciseSet.weight.toString(),
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
                                                                                fillColor: exerciseSet.isChecked ? Colors.green.shade200 : Colors.grey.shade300,
                                                                                contentPadding: EdgeInsets.symmetric(
                                                                                  horizontal: isSmallScreen ? 4 : 6,
                                                                                  vertical: 4,
                                                                                ),
                                                                              ),
                                                                              keyboardType: TextInputType.number,
                                                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                              onChanged: (val) {
                                                                                setState(() {
                                                                                  exerciseSet.weight = int.tryParse(val) ?? 0;
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
                                                                              maxWidth: isSmallScreen ? 60 : 80,
                                                                              minWidth: 50,
                                                                            ),
                                                                            child: TextFormField(
                                                                              initialValue: exerciseSet.reps.toString(),
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
                                                                                fillColor: exerciseSet.isChecked ? Colors.green.shade200 : Colors.grey.shade300,
                                                                                contentPadding: EdgeInsets.symmetric(
                                                                                  horizontal: isSmallScreen ? 4 : 6,
                                                                                  vertical: 4,
                                                                                ),
                                                                              ),
                                                                              keyboardType: TextInputType.number,
                                                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                              onChanged: (val) {
                                                                                setState(() {
                                                                                  exerciseSet.reps = int.tryParse(val) ?? 0;
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
                                                  onPressed: () {
                                                    setState(() {
                                                      e.sets.add(ExerciseSet());
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
                                    
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final navigator = Navigator.of(context);
                                              final bool? confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text('Delete Workout'),
                                                    content: const Text('Are you sure you want to delete workout?'),
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

                                              if (confirmed == true) {
                                                QuickStartOverlay.selectedExercises = [];
                                                navigator.pop();
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red.shade700,
                                              shape: const StadiumBorder(),
                                              padding: buttonPadding,
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.white, 
                                                fontSize: buttonFontSize, 
                                                fontWeight: FontWeight.bold
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: screenWidth < 350 ? 12 : 16),
                                                                Expanded(
                          child: ElevatedButton(
                            onPressed: () {
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              shape: const StadiumBorder(),
                              padding: buttonPadding,
                            ),
                            child: Text(
                              'Finish',
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: buttonFontSize, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 100),
                              ],
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
                            final navigator = Navigator.of(context);
                            final result = await navigator.push<List<String>>(
                              MaterialPageRoute(
                                builder: (ctx) => const ExerciseInformationPage(
                                  isSelectionMode: true,
                                ),
                              ),
                            );
                            if (result != null && mounted) {
                              setState(() {
                                // Append new picks as QuickStartExercise entries
                                final newExercises = result.map((title) => QuickStartExercise(title: title)).toList();
                                _selectedExercises.addAll(newExercises);
                                QuickStartOverlay.selectedExercises = _selectedExercises;
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
          },
        ),
      ),
    );
  }
} 