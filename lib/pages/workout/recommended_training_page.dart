import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/models/exercise_set.dart';
import 'package:gymfit/services/recommended_training_service.dart';
import 'package:gymfit/pages/workout/quick_start_page_optimized.dart';
import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';
import 'package:gymfit/components/chatbot.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:gymfit/pages/workout/recommended_training_help_page.dart';

class RecommendedTrainingPage extends StatefulWidget {
  const RecommendedTrainingPage({super.key});

  @override
  State<RecommendedTrainingPage> createState() =>
      _RecommendedTrainingPageState();
}

class _RecommendedTrainingPageState extends State<RecommendedTrainingPage> {
  // CustomWorkout? _recommendedWorkout;
  Map<String, List<CustomWorkoutExercise>>? _weekPlan;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  // Questionnaire state
  bool _questionnaireCompleted = false;
  int _daysPerWeek = 3;
  List<String> _selectedDays = [];
  bool _noPreferenceDays = true;
  String _trainingSplit = 'Full Body';

  // View toggle state
  bool _showCalendarView = false;
  DateTime _focusedDay = DateTime.now();
  String? _selectedPlanDay;
  DateTime? _calendarSelectedDate;

  final List<String> _weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  final List<String> _trainingSplits = [
    'Full Body', 'Upper/Lower', 'Push/Pull/Legs'
  ];

  // /// Helper to create a mock week plan from the generated workout
  // Map<String, List<CustomWorkoutExercise>> _getWeekPlan() {
  //   if (_recommendedWorkout == null) return {};
  //   // Parse the week plan from the workout description
  //   // The backend now includes the week plan in the description
  //   final description = _recommendedWorkout!.description ?? '';
  //   final plan = <String, List<CustomWorkoutExercise>>{};
    
  //   // For now, let's use the backend's week plan logic directly
  //   // We'll need to modify the backend to return the week plan structure
  //   // For debugging, let's show what we have
  //   // print('Workout description: $description');
  //   // print('Total exercises: ${_recommendedWorkout!.exercises.length}');
    
  //   // Temporary: Use the exercises as they are (they should be in the correct order)
  //   final days = _noPreferenceDays
  //       ? _weekDays.sublist(0, _daysPerWeek)
  //       : _selectedDays;
    
  //   // Group exercises by day based on the split logic
  //   int exerciseIndex = 0;
  //   for (int dayIndex = 0; dayIndex < days.length; dayIndex++) {
  //     final day = days[dayIndex];
  //     plan[day] = [];
      
  //     // Add exercises for this day (assuming they're in the correct order from backend)
  //     final exercisesPerDay = (_recommendedWorkout!.exercises.length / days.length).ceil();
  //     for (int i = 0; i < exercisesPerDay && exerciseIndex < _recommendedWorkout!.exercises.length; i++) {
  //       plan[day]!.add(_recommendedWorkout!.exercises[exerciseIndex]);
  //       exerciseIndex++;
  //     }
  //   }
    
  //   return plan;
  // }

  /// Helper to get the split label for a given day
  String _getDaySplitLabel(int dayIndex) {
    if (_trainingSplit == 'Full Body') {
      return 'Full Body';
    } else if (_trainingSplit == 'Upper/Lower') {
      return dayIndex % 2 == 0 ? 'Upper' : 'Lower';
    } else if (_trainingSplit == 'Push/Pull/Legs') {
      if (dayIndex % 3 == 0) return 'Push';
      if (dayIndex % 3 == 1) return 'Pull';
      return 'Legs';
    }
    return '';
  }

  // Shared card widget for a day's plan
  Widget _buildPlanDayCard({
    required String day,
    required String splitLabel,
    required List<CustomWorkoutExercise> exercises,
    bool showPlayIcon = true,
    VoidCallback? onTap,
  }) {
    final themeService = Provider.of<ThemeService>(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: themeService.currentTheme.cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                      ),
                    ),
                  ),
                  if (splitLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '($splitLabel)',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: themeService.isDarkMode ? Colors.blueGrey[300] : Colors.blueGrey,
                      ),
                    ),
                  ],
                  if (showPlayIcon) ...[
                    const SizedBox(width: 8),
                    FaIcon(
                      FontAwesomeIcons.circlePlay,
                      size: 24,
                      color: Colors.blue,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (exercises.isEmpty)
                Text(
                  'No exercises found for this split',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    color: Colors.redAccent,
                  ),
                ),
              ...exercises.map((exercise) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.dumbbell, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          exercise.name,
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: themeService.currentTheme.textTheme.titleMedium?.color ?? Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...exercise.sets.asMap().entries.map((setEntry) {
                      final setIdx = setEntry.key + 1;
                      final set = setEntry.value;
                      return Padding(
                        padding: const EdgeInsets.only(left: 32, bottom: 2),
                        child: Text(
                          'Set $setIdx: '
                          '${set.weight > 0 ? '${set.weight.toStringAsFixed(1)}kg' : 'Bodyweight'} × ${set.reps} reps',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            color: themeService.currentTheme.textTheme.bodyMedium?.color ?? Colors.grey[700],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              )),
              if (showPlayIcon)
                const SizedBox(height: 12),
              if (showPlayIcon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.handPointer,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to start workout',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekPlanView() {
    final weekPlan = _weekPlan;
    if (weekPlan == null || weekPlan.isEmpty) return const SizedBox.shrink();
    final days = _noPreferenceDays
        ? _weekDays.sublist(0, _daysPerWeek)
        : _selectedDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: weekPlan.entries.map((entry) {
        final day = entry.key;
        final exercises = entry.value;
        final i = days.indexOf(day);
        final splitLabel = _getDaySplitLabel(i);
        return _buildPlanDayCard(
          day: day,
          splitLabel: splitLabel,
          exercises: exercises,
          showPlayIcon: true,
          onTap: () => _startWorkoutForDay(day, exercises),
        );
      }).toList(),
    );
  }

  Widget _buildViewToggle() {
    final themeService = Provider.of<ThemeService>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: themeService.currentTheme.colorScheme.surface,
          ),
          icon: FaIcon(
            _showCalendarView ? FontAwesomeIcons.calendarDays : FontAwesomeIcons.list,
            size: 18,
            color: themeService.currentTheme.colorScheme.primary,
          ),
          label: Text(
            _showCalendarView ? 'Calendar View' : 'List View',
            style: TextStyle(
              fontSize: 14,
              color: themeService.currentTheme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () {
            setState(() {
              _showCalendarView = !_showCalendarView;
            });
          },
        ),
      ),
    );
  }

  Widget _buildRecommendedPlanCalendar() {
    if (_weekPlan == null || _weekPlan!.isEmpty) return const SizedBox.shrink();
    final days = _noPreferenceDays ? _weekDays.sublist(0, _daysPerWeek) : _selectedDays;
    // Map each plan day to the correct weekday in the current week
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1)); // Monday
    Map<String, DateTime> dayNameToDate = {};
    Map<DateTime, String> dateToDayName = {};
    for (var weekDayName in days) {
      // Find the weekday index (Monday=1, ..., Sunday=7)
      int weekDayIndex = _weekDays.indexOf(weekDayName);
      if (weekDayIndex != -1) {
        DateTime date = weekStart.add(Duration(days: weekDayIndex));
        dayNameToDate[weekDayName] = date;
        dateToDayName[date] = weekDayName;
      }
    }
    List<DateTime> planDates = dayNameToDate.values.toList();

    // Track selected calendar day (default to today if in week, else first plan day)
    if (_calendarSelectedDate == null) {
      if (today.isAfter(weekStart.subtract(const Duration(days: 1))) && today.isBefore(weekStart.add(const Duration(days: 7)))) {
        _calendarSelectedDate = today;
      } else {
        _calendarSelectedDate = planDates.isNotEmpty ? planDates.first : weekStart;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TableCalendar<DateTime>(
          firstDay: weekStart,
          lastDay: weekStart.add(const Duration(days: 6)),
          focusedDay: _calendarSelectedDate!,
          calendarFormat: CalendarFormat.week,
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableGestures: AvailableGestures.horizontalSwipe,
          selectedDayPredicate: (day) => isSameDay(day, _calendarSelectedDate!),
          eventLoader: (day) => planDates.where((d) => isSameDay(d, day)).toList(),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.dumbbell,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          onDaySelected: (selected, focused) {
            setState(() {
              _calendarSelectedDate = selected;
              _focusedDay = focused;
            });
          },
          headerVisible: false,
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (_) {
            // Get the weekday name for the selected date
            String selectedWeekdayName = _weekDays[_calendarSelectedDate!.weekday - 1];
            if (days.contains(selectedWeekdayName) && _weekPlan![selectedWeekdayName] != null) {
              return _buildPlanDayExercises(selectedWeekdayName);
            } else {
              // Show message for days not in plan
              final themeService = Provider.of<ThemeService>(context);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: themeService.currentTheme.cardTheme.color,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No workout planned for this day.',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 16,
                        color: themeService.currentTheme.textTheme.bodyMedium?.color ?? Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPlanDayExercises(String day) {
    final exercises = _weekPlan?[day] ?? [];
    final days = _noPreferenceDays ? _weekDays.sublist(0, _daysPerWeek) : _selectedDays;
    final i = days.indexOf(day);
    final splitLabel = _getDaySplitLabel(i);
    return _buildPlanDayCard(
      day: day,
      splitLabel: splitLabel,
      exercises: exercises,
      showPlayIcon: true,
      onTap: () => _startWorkoutForDay(day, exercises),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkQuestionnaireCompletion();
    // Do not generate workout in initState; wait for questionnaire unless already completed
  }

  Future<void> _checkQuestionnaireCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('recommended_training_questionnaire_completed') ?? false;
    if (completed) {
      // Load previous answers and plan
      final planJson = prefs.getString('recommended_training_week_plan');
      final answersJson = prefs.getString('recommended_training_answers');
      Map<String, List<CustomWorkoutExercise>>? loadedPlan;
      if (planJson != null) {
        final decoded = jsonDecode(planJson) as Map<String, dynamic>;
        loadedPlan = decoded.map((day, exercises) => MapEntry(
          day,
          (exercises as List).map((e) => CustomWorkoutExercise.fromMap(e)).toList(),
        ));
      }
      if (answersJson != null) {
        final answers = jsonDecode(answersJson);
        setState(() {
          _daysPerWeek = answers['daysPerWeek'] ?? 3;
          _selectedDays = List<String>.from(answers['selectedDays'] ?? []);
          _noPreferenceDays = answers['noPreferenceDays'] ?? true;
          _trainingSplit = answers['trainingSplit'] ?? 'Full Body';
        });
      }
      // Fetch user profile data
      final userData = await RecommendedTrainingService.getUserBodyData();
      setState(() {
        _questionnaireCompleted = true;
        _weekPlan = loadedPlan;
        _userData = userData;
      });
    }
  }

  Future<void> _setQuestionnaireCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('recommended_training_questionnaire_completed', true);
    // Save answers
    final answers = {
      'daysPerWeek': _daysPerWeek,
      'selectedDays': _selectedDays,
      'noPreferenceDays': _noPreferenceDays,
      'trainingSplit': _trainingSplit,
    };
    await prefs.setString('recommended_training_answers', jsonEncode(answers));
    // Save plan
    if (_weekPlan != null) {
      final planMap = _weekPlan!.map((day, exercises) => MapEntry(
        day,
        exercises.map((e) => e.toMap()).toList(),
      ));
      await prefs.setString('recommended_training_week_plan', jsonEncode(planMap));
    }
  }

  Future<void> _generateRecommendedWorkout() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      _userData = await RecommendedTrainingService.getUserBodyData();
      // Get the week plan directly
      final weekPlan = await RecommendedTrainingService.generateRecommendedWeekPlan(
        daysPerWeek: _daysPerWeek,
        selectedDays: _noPreferenceDays ? [] : _selectedDays,
        trainingSplit: _trainingSplit,
      );
      if (mounted) {
        setState(() {
          _weekPlan = weekPlan;
          _isLoading = false;
        });
        // Save plan after generation
        final prefs = await SharedPreferences.getInstance();
        final planMap = weekPlan.map((day, exercises) => MapEntry(
          day,
          exercises.map((e) => e.toMap()).toList(),
        ));
        await prefs.setString('recommended_training_week_plan', jsonEncode(planMap));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onQuestionnaireSubmit() {
    setState(() {
      _questionnaireCompleted = true;
      _isLoading = true;
    });
    _setQuestionnaireCompleted();
    _generateRecommendedWorkout();
  }

  void _startWorkoutForDay(String day, List<CustomWorkoutExercise> exercises) {
    // Add haptic feedback when starting recommended workout
    HapticFeedback.heavyImpact();
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Start Workout?',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Do you want to start the $day workout?',
            style: TextStyle(
              fontFamily: 'DMSans',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToQuickStart(day, exercises);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Start Workout',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToQuickStart(String day, List<CustomWorkoutExercise> exercises) {
    // Convert CustomWorkoutExercise to QuickStartExercise
    final quickStartExercises = exercises.map((exercise) {
      return QuickStartExercise(
        title: exercise.name,
        sets: exercise.sets
            .map((set) => ExerciseSet(weight: set.weight, reps: set.reps))
            .toList(),
      );
    }).toList();

    // Set up the QuickStartOverlay data for proper minimization
    QuickStartOverlay.selectedExercises = quickStartExercises;
    QuickStartOverlay.customWorkoutName = '$day Workout';

    // Navigate to quick start page with smooth slide-up animation from bottom and slight delay
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) => QuickStartPageOptimized(
          initialSelectedExercises: quickStartExercises,
          initialWorkoutName: '$day Workout',
          showMinibarOnMinimize: true,
        ),
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (ctx, animation, secAnim, child) {
          // Create a curved animation for smoother motion
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          
          // Slide up animation with subtle scale effect
          final slideTween = Tween<Offset>(
            begin: const Offset(0, 1), 
            end: Offset.zero,
          );
          
          // Subtle scale animation for more visual polish
          final scaleTween = Tween<double>(
            begin: 0.95,
            end: 1.0,
          );
          
          // Fade animation for smoother transition
          final fadeTween = Tween<double>(
            begin: 0.8,
            end: 1.0,
          );
          
          return SlideTransition(
            position: slideTween.animate(curvedAnimation),
            child: ScaleTransition(
              scale: scaleTween.animate(curvedAnimation),
              child: FadeTransition(
                opacity: fadeTween.animate(curvedAnimation),
                child: child,
              ),
            ),
          );
        },
      ),
    );
    });
  }

  void _regenerateWorkout() {
    _generateRecommendedWorkout();
  }

  Widget _buildMotivationalQuote() {
    final themeService = Provider.of<ThemeService>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 24),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.trophy, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '"The only bad workout is the one that didn\'t happen."',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontStyle: FontStyle.italic,
                color: themeService.currentTheme.textTheme.bodyLarge?.color ?? Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    final themeService = Provider.of<ThemeService>(context);
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: FaIcon(icon, color: color, size: 16),
      ),
      label: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: 'DMSans',
          color: themeService.currentTheme.textTheme.bodyMedium?.color ?? Colors.black,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withOpacity(0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }



  // Widget _exerciseTile(CustomWorkoutExercise exercise) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(vertical: 6),
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: Colors.blueGrey[50],
  //       borderRadius: BorderRadius.circular(10),
  //       border: Border.all(color: Colors.blueGrey[100]!),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             const Icon(
  //               Icons.check_circle_outline,
  //               color: Colors.blueAccent,
  //               size: 20,
  //             ),
  //             const SizedBox(width: 10),
  //             Expanded(
  //               child: Text(
  //                 exercise.name,
  //                 style: const TextStyle(
  //                   fontFamily: 'DMSans',
  //                   fontWeight: FontWeight.w600,
  //                   fontSize: 15,
  //                   color: Colors.black,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),

  //         // Show set details
  //         Row(
  //           children: [
  //             const SizedBox(width: 30), // Align with exercise name
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     '${exercise.sets.length} sets',
  //                     style: const TextStyle(
  //                     fontFamily: 'DMSans',
  //                     fontWeight: FontWeight.w500,
  //                     fontSize: 13,
  //                     color: Colors.black87,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 4),

  //                 // Show progressive rep scheme
  //                 if (_hasProgressiveReps(exercise.sets))
  //                   _buildProgressiveRepsDisplay(exercise.sets)
  //                 else
  //                   Text(
  //                     '${exercise.sets.first.weight > 0 ? '${exercise.sets.first.weight.toStringAsFixed(1)}kg' : 'Bodyweight'} × ${exercise.sets.first.reps} reps each set',
  //                     style: const TextStyle(
  //                       fontFamily: 'DMSans',
  //                       fontSize: 12,
  //                       color: Colors.black54,
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // /// Check if the exercise has progressive reps or weights (different reps/weights per set)
  // bool _hasProgressiveReps(List<CustomWorkoutSet> sets) {
  //   if (sets.length <= 1) return false;
  //   final firstReps = sets.first.reps;
  //   final firstWeight = sets.first.weight;
  //   return sets.any(
  //     (set) => set.reps != firstReps || set.weight != firstWeight,
  //   );
  // }

  // /// Build progressive reps display
  // Widget _buildProgressiveRepsDisplay(List<CustomWorkoutSet> sets) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Progressive scheme:',
  //         style: TextStyle(
  //           fontFamily: 'DMSans',
  //           fontSize: 11,
  //           color: Colors.grey[600],
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //       const SizedBox(height: 2),
  //       Wrap(
  //         spacing: 8,
  //         runSpacing: 2,
  //         children:
  //             sets.asMap().entries.map((entry) {
  //               final index = entry.key;
  //               final set = entry.value;
  //               return Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 6,
  //                   vertical: 2,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: Colors.blue[50],
  //                   borderRadius: BorderRadius.circular(4),
  //                   border: Border.all(color: Colors.blue),
  //                 ),
  //                 child: Text(
  //                   'Set ${index + 1}: ${set.weight > 0 ? '${set.weight.toStringAsFixed(1)}kg' : 'BW'} × ${set.reps} reps',
  //                   style: const TextStyle(
  //                     fontFamily: 'DMSans',
  //                     fontSize: 10,
  //                     color: Colors.blue,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //               );
  //             }).toList(),
  //       ),
  //     ],
  //   );
  // }

  // Helper to show a bottom sheet for single selection
  Future<T?> _showBottomSheetPicker<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required T selected,
    required String Function(T) labelBuilder,
    List<IconData>? icons, // Optional: icon for each option
  }) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    return await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: themeService.currentTheme.cardTheme.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: themeService.currentTheme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                ...options.asMap().entries.map((entry) {
                  final i = entry.key;
                  final option = entry.value;
                  return Column(
                    children: [
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey,
                        ),
                      ListTile(
                        leading: icons != null && icons.length > i
                            ? FaIcon(icons[i], color: themeService.currentTheme.iconTheme.color)
                            : null,
                        title: Text(
                          labelBuilder(option),
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: _bodyTextColor(context),
                          ),
                        ),
                        trailing: option == selected
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                        onTap: () => Navigator.of(ctx).pop(option),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper to show a bottom sheet for multi-selection (for days)
  Future<List<String>?> _showMultiSelectDaysSheet({
    required BuildContext context,
    required List<String> weekDays,
    required List<String> selectedDays,
    required int maxSelection,
  }) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    List<String> tempSelected = List.from(selectedDays);
    return await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: themeService.currentTheme.cardTheme.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Select Training Days',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: themeService.currentTheme.textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...weekDays.asMap().entries.map((entry) {
                      final i = entry.key;
                      final day = entry.value;
                      final selected = tempSelected.contains(day);
                      final disabled = tempSelected.length >= maxSelection && !selected;
                      return Column(
                        children: [
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey,
                            ),
                          CheckboxListTile(
                            value: selected,
                            title: Text(
                              day,
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: _bodyTextColor(context),
                              ),
                            ),
                            activeColor: Colors.blue,
                            onChanged: disabled
                                ? null
                                : (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        if (tempSelected.length < maxSelection) {
                                          tempSelected.add(day);
                                        }
                                      } else {
                                        tempSelected.remove(day);
                                      }
                                    });
                                  },
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(tempSelected),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        textStyle: const TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionnaire() {
    final themeService = Provider.of<ThemeService>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Days per week
          ListTile(
            title: Text(
              'How many days per week do you want to train?',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _bodyTextColor(context),
              ),
            ),
            trailing: Text(
              '$_daysPerWeek',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: _bodyTextColor(context),
              ),
            ),
            onTap: () async {
              final picked = await _showBottomSheetPicker<int>(
                context: context,
                title: 'Select Days per Week',
                options: List.generate(7, (i) => i + 1),
                selected: _daysPerWeek,
                labelBuilder: (d) => d.toString(),
              );
              if (picked != null && picked != _daysPerWeek) {
                setState(() {
                  _daysPerWeek = picked;
                  if (_selectedDays.length > picked) {
                    _selectedDays = _selectedDays.sublist(0, picked);
                  }
                });
              }
            },
          ),
          const SizedBox(height: 8),
          // No preference for training days
          SwitchListTile.adaptive(
            value: _noPreferenceDays,
            title: Text(
              'No preference for training days',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _bodyTextColor(context),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _noPreferenceDays = val;
                if (_noPreferenceDays) _selectedDays.clear();
              });
            },
          ),
          if (!_noPreferenceDays)
            ListTile(
              title: Text(
                _selectedDays.isEmpty
                    ? 'Select training days'
                    : 'Selected: ${_selectedDays.join(", ")}',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _bodyTextColor(context),
                ),
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () async {
                final picked = await _showMultiSelectDaysSheet(
                  context: context,
                  weekDays: _weekDays,
                  selectedDays: _selectedDays,
                  maxSelection: _daysPerWeek,
                );
                if (picked != null) {
                  setState(() {
                    _selectedDays = picked;
                  });
                }
              },
            ),
          const SizedBox(height: 8),
          // Training split
          ListTile(
            title: Text(
              'Preferred training split:',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _bodyTextColor(context),
              ),
            ),
            trailing: Text(
              _trainingSplit,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: _bodyTextColor(context),
              ),
            ),
            onTap: () async {
              final picked = await _showBottomSheetPicker<String>(
                context: context,
                title: 'Select Training Split',
                options: _trainingSplits,
                selected: _trainingSplit,
                labelBuilder: (s) => s,
              );
              if (picked != null && picked != _trainingSplit) {
                setState(() {
                  _trainingSplit = picked;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _onQuestionnaireSubmit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: const Text('Generate My Plan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final themeService = Provider.of<ThemeService>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: themeService.currentTheme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Generating your personalized workout...',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 16,
              color: themeService.currentTheme.textTheme.bodyLarge?.color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final themeService = Provider.of<ThemeService>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.triangleExclamation, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error generating workout',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              color: themeService.currentTheme.textTheme.bodyMedium?.color ?? Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _regenerateWorkout,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    return Scaffold(
      backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeService.currentTheme.appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recommended Training'),
        backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor ?? Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'DMSans',
          color: themeService.currentTheme.appBarTheme.titleTextStyle?.color ?? Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Recommended Training Help',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RecommendedTrainingHelpPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: !_questionnaireCompleted
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMotivationalQuote(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalize Your Training Plan',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Answer a few quick questions to generate a training plan tailored to your goals, schedule, and experience.',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _bodyTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  _buildQuestionnaire(),
                ],
              ),
            )
          : _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
                  ? _buildErrorState()
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMotivationalQuote(),
                          // User's choices summary (pressable to edit)
                          if (_userData != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profile',
                                    style: TextStyle(
                                      fontFamily: 'DMSans',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: themeService.currentTheme.textTheme.titleMedium?.color ?? Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 4,
                                    children: [
                                      _infoChip(
                                        FontAwesomeIcons.flag,
                                        'Goal',
                                        _userData!['goal'] ?? 'Not set',
                                        Colors.green,
                                      ),
                                      _infoChip(
                                        FontAwesomeIcons.dumbbell,
                                        'Level',
                                        _userData!['fitness level'] ?? 'Not set',
                                        Colors.deepPurple,
                                      ),
                                      _infoChip(
                                        FontAwesomeIcons.cakeCandles,
                                        'Age',
                                        '${_userData!['age'] ?? 'Not set'}',
                                        Colors.orange,
                                      ),
                                      if (_userData!['bmi'] != null)
                                        _infoChip(
                                          FontAwesomeIcons.weightScale,
                                          'BMI',
                                          '${_userData!['bmi']}',
                                          Colors.pink,
                                        ),
                                      _infoChip(
                                        FontAwesomeIcons.suitcaseMedical,
                                        'Condition',
                                        _userData!['medical condition'] ?? 'None',
                                        Colors.redAccent,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(
                                color: themeService.currentTheme.dividerColor,
                              ),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                splashColor: themeService.currentTheme.colorScheme.primary.withOpacity(0.08),
                                onTap: () {
                                  setState(() {
                                    _questionnaireCompleted = false;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Training Plan',
                                            style: TextStyle(
                                              fontFamily: 'DMSans',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.blue, // Use blue to indicate interactivity
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          FaIcon(
                                            FontAwesomeIcons.penToSquare,
                                            size: 14,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '(Tap to edit)',
                                            style: TextStyle(
                                              fontFamily: 'DMSans',
                                              fontSize: 12,
                                              color: Colors.blueGrey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          FaIcon(FontAwesomeIcons.calendarDays, size: 18, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Days per week: ',
                                            style: TextStyle(
                                              fontFamily: 'DMSans',
                                              fontWeight: FontWeight.w600,
                                              color: themeService.isDarkMode ? Colors.grey[200] : Colors.grey[900],
                                            ),
                                          ),
                                          Text(
                                            '$_daysPerWeek',
                                            style: TextStyle(
                                              fontFamily: 'DMSans',
                                              fontWeight: FontWeight.w600,
                                              color: themeService.isDarkMode ? Colors.grey[200] : Colors.grey[900],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!_noPreferenceDays)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              FaIcon(FontAwesomeIcons.noteSticky, size: 18, color: Colors.deepPurple),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Selected days: ',
                                                style: TextStyle(
                                                  fontFamily: 'DMSans',
                                                  fontWeight: FontWeight.w600,
                                                  color: themeService.isDarkMode ? Colors.grey[200] : Colors.grey[900],
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  _selectedDays.join(', '),
                                                  style: TextStyle(
                                                    fontFamily: 'DMSans',
                                                    fontWeight: FontWeight.w600,
                                                    color: themeService.isDarkMode ? Colors.grey[200] : Colors.grey[900],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          children: [
                                            FaIcon(FontAwesomeIcons.dumbbell, size: 18, color: Colors.green),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Training split: ',
                                              style: TextStyle(
                                                fontFamily: 'DMSans',
                                                fontWeight: FontWeight.w600,
                                                color: themeService.isDarkMode ? Colors.grey[200] : Colors.grey[900],
                                              ),
                                            ),
                                            Text(
                                              _trainingSplit,
                                              style: TextStyle(
                                                fontFamily: 'DMSans',
                                                fontWeight: FontWeight.w600,
                                                color: themeService.isDarkMode ? Colors.grey[200] : Colors.grey[900],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(
                              color: themeService.currentTheme.dividerColor,
                            ),
                          ),
                          // Place the toggle right above the calendar/list view
                          _buildViewToggle(),
                          _showCalendarView ? _buildRecommendedPlanCalendar() : _buildWeekPlanView(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
    );
  }

  // Helper to get dark grey color based on theme
  Color _bodyTextColor(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    return themeService.isDarkMode ? Colors.grey[200]! : Colors.grey[900]!;
  }
}
