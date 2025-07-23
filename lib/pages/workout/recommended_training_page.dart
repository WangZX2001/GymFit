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

  Widget _buildWeekPlanView() {
    final weekPlan = _weekPlan;
    if (weekPlan == null || weekPlan.isEmpty) return const SizedBox.shrink();
    final themeService = Provider.of<ThemeService>(context);
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
        return InkWell(
          onTap: () => _startWorkoutForDay(day, exercises),
          borderRadius: BorderRadius.circular(16),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: themeService.currentTheme.cardTheme.color,
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                      const SizedBox(width: 8),
                      Icon(
                        Icons.play_circle_outline,
                        size: 24,
                        color: Colors.blue,
                      ),
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
                            const Icon(Icons.fitness_center, size: 18, color: Colors.blue),
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
                                color: themeService.currentTheme.textTheme.bodyMedium?.color ?? Colors.black87,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
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
      }).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    // Do not generate workout in initState; wait for questionnaire
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
      // Get the workout for legacy compatibility
      // final workout =
      //     await RecommendedTrainingService.generateRecommendedWorkout(
      //       daysPerWeek: _daysPerWeek,
      //       selectedDays: _noPreferenceDays ? [] : _selectedDays,
      //       trainingSplit: _trainingSplit,
      //     );
      if (mounted) {
        setState(() {
          // _recommendedWorkout = workout;
          _weekPlan = weekPlan;
          _isLoading = false;
        });
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
          const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
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

  Widget _buildUserInfoCard() {
    if (_userData == null) return const SizedBox.shrink();
    final themeService = Provider.of<ThemeService>(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: themeService.currentTheme.cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Your Profile',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: themeService.currentTheme.textTheme.titleMedium?.color ?? Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                _infoChip(
                  Icons.flag,
                  'Goal',
                  _userData!['goal'] ?? 'Not set',
                  Colors.green,
                ),
                _infoChip(
                  Icons.fitness_center,
                  'Level',
                  _userData!['fitness level'] ?? 'Not set',
                  Colors.deepPurple,
                ),
                _infoChip(
                  Icons.cake,
                  'Age',
                  '${_userData!['age'] ?? 'Not set'}',
                  Colors.orange,
                ),
                if (_userData!['bmi'] != null)
                  _infoChip(
                    Icons.monitor_weight,
                    'BMI',
                    '${_userData!['bmi']}',
                    Colors.pink,
                  ),
                _infoChip(
                  Icons.healing,
                  'Condition',
                  _userData!['medical condition'] ?? 'None',
                  Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    final themeService = Provider.of<ThemeService>(context);
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 16),
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
      backgroundColor: color.withValues(alpha: 0.07),
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

  Widget _buildQuestionnaire() {
    final themeService = Provider.of<ThemeService>(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: themeService.currentTheme.cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(18),
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
            const SizedBox(height: 18),
            // Days per week
            Row(
              children: [
                Expanded(
                  child: Text(
                    'How many days per week do you want to train?',
                    style: TextStyle(
                      fontFamily: 'DMSans', 
                      fontSize: 15,
                      color: themeService.currentTheme.textTheme.bodyLarge?.color ?? Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _daysPerWeek,
                  items: List.generate(7, (i) => i + 1)
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('$d'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _daysPerWeek = val;
                        if (_selectedDays.length > val) {
                          _selectedDays = _selectedDays.sublist(0, val);
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Which days
            Row(
              children: [
                Checkbox(
                  value: _noPreferenceDays,
                  onChanged: (val) {
                    setState(() {
                      _noPreferenceDays = val ?? true;
                      if (_noPreferenceDays) _selectedDays.clear();
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'No preference for training days', 
                    style: TextStyle(
                      fontFamily: 'DMSans', 
                      fontSize: 15,
                      color: themeService.currentTheme.textTheme.bodyLarge?.color ?? Colors.black,
                    )
                  ),
                ),
              ],
            ),
            if (!_noPreferenceDays)
              Wrap(
                spacing: 8,
                children: _weekDays.map((day) {
                  final selected = _selectedDays.contains(day);
                  final disabled = _selectedDays.length >= _daysPerWeek && !selected;
                  return FilterChip(
                    label: Text(day),
                    selected: selected,
                    onSelected: disabled
                        ? null
                        : (val) {
                            setState(() {
                              if (val) {
                                if (_selectedDays.length < _daysPerWeek) {
                                  _selectedDays.add(day);
                                }
                              } else {
                                _selectedDays.remove(day);
                              }
                            });
                          },
                  );
                }).toList(),
              ),
            const SizedBox(height: 18),
            // Training split
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Preferred training split:', 
                    style: TextStyle(
                      fontFamily: 'DMSans', 
                      fontSize: 15,
                      color: themeService.currentTheme.textTheme.bodyLarge?.color ?? Colors.black,
                    )
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _trainingSplit,
                  items: _trainingSplits
                      .map((split) => DropdownMenuItem(
                            value: split,
                            child: Text(split),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _trainingSplit = val;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _onQuestionnaireSubmit();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
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
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
        title: const Text('Recommended Training'),
        backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor ?? Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: themeService.currentTheme.appBarTheme.iconTheme?.color ?? Colors.black),
        titleTextStyle: TextStyle(
          fontFamily: 'DMSans',
          color: themeService.currentTheme.appBarTheme.titleTextStyle?.color ?? Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: !_questionnaireCompleted
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMotivationalQuote(),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            child: Chatbot(
                              text:
                                  "I've analyzed your body data and created a personalized workout plan with intelligent weight and rep suggestions! Each exercise has optimized sets, weights, and reps based on your fitness level, goals, and exercise type.",
                            ),
                          ),
                          _buildUserInfoCard(),
                          _buildWeekPlanView(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
    );
  }
}
