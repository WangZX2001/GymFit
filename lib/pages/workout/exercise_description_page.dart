import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/models/workout.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:gymfit/pages/workout/quick_start_page_optimized.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/models/exercise_set.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/services/custom_workout_service.dart';
import 'package:gymfit/pages/workout/custom_workout_configuration_page_refactored.dart';

class ExerciseDescriptionPage extends StatefulWidget {
  final String title;
  final String description;
  final String? videoUrl;
  final String mainMuscle;
  final String secondaryMuscle;
  final List<String> proTips;
  final VoidCallback onAdd;
  final String experienceLevel;
  final String howTo;

  const ExerciseDescriptionPage({
    super.key,
    required this.title,
    required this.description,
    this.videoUrl,
    required this.mainMuscle,
    required this.secondaryMuscle,
    required this.proTips,
    required this.onAdd,
    required this.experienceLevel,
    required this.howTo,
  });

  @override
  State<ExerciseDescriptionPage> createState() => _ExerciseDescriptionPageState();
}

class _ExerciseDescriptionPageState extends State<ExerciseDescriptionPage> with SingleTickerProviderStateMixin {
  YoutubePlayerController? _ytController;
  bool _showTitle = false;
  final ScrollController _customWorkoutScrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _showTitle = _tabController.index == 1;
      });
    });

    final url = widget.videoUrl;
    String? vidId;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && uri.queryParameters['v'] != null) {
        vidId = uri.queryParameters['v'];
      } else if (url.contains('youtu.be/')) {
        vidId = url.split('youtu.be/').last.split('?').first;
      }
    }
    if (vidId != null) {
      _ytController = YoutubePlayerController(
        initialVideoId: vidId,
        flags: const YoutubePlayerFlags(autoPlay: false),
      );
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    _customWorkoutScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }



  // Helper to pick color based on experience level
  Color _getExperienceColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Calculate 1RM using Brzycki Formula
  double estimate1RM(double weight, int reps) {
    if (reps == 1) return weight;
    if (reps > 10) reps = 10; // Cap for accuracy
    return weight / (1.0278 - 0.0278 * reps);
  }

  // Format 1RM to show appropriate decimal places
  String _format1RM(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString(); // Whole number
    } else if ((value * 10) == (value * 10).toInt()) {
      return value.toStringAsFixed(1); // 1 decimal place
    } else {
      return value.toStringAsFixed(2); // 2 decimal places
    }
  }

  // Format weight to show appropriate decimal places
  String _formatWeight(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString(); // Whole number
    } else if ((value * 10) == (value * 10).toInt()) {
      return value.toStringAsFixed(1); // 1 decimal place
    } else {
      return value.toStringAsFixed(2); // 2 decimal places
    }
  }

  // Format volume to show appropriate decimal places
  String _formatVolume(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString(); // Whole number
    } else if ((value * 10) == (value * 10).toInt()) {
      return value.toStringAsFixed(1); // 1 decimal place
    } else {
      return value.toStringAsFixed(2); // 2 decimal places
    }
  }

  // Get real 1RM data from workout history
  Future<List<Map<String, dynamic>>> _getReal1RMData() async {
    try {
      final workouts = await WorkoutService.getUserWorkouts();
      final Map<String, Map<String, dynamic>> dailyMax1RM = {};
      
      for (final workout in workouts) {
        for (final exercise in workout.exercises) {
          // Check if this exercise matches the current exercise
          if (exercise.title.toLowerCase() == widget.title.toLowerCase()) {
            for (final set in exercise.sets) {
              if (set.isCompleted && set.weight > 0 && set.reps > 0) {
                final estimated1RM = estimate1RM(set.weight, set.reps);
                final dateKey = '${workout.date.year}-${workout.date.month.toString().padLeft(2, '0')}-${workout.date.day.toString().padLeft(2, '0')}';
                
                // If this date doesn't exist or this 1RM is higher, update it
                if (!dailyMax1RM.containsKey(dateKey) || 
                    estimated1RM > dailyMax1RM[dateKey]!['estimated1RM']) {
                  dailyMax1RM[dateKey] = {
                    'date': workout.date,
                    'weight': set.weight,
                    'reps': set.reps,
                    'estimated1RM': estimated1RM,
                    'exercise': exercise.title,
                    'workoutId': workout.id,
                  };
                }
              }
            }
          }
        }
      }
      
      // Convert to list and sort by date (oldest first for proper graph display)
      final oneRMData = dailyMax1RM.values.toList();
      oneRMData.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      
      return oneRMData;
    } catch (e) {
      print('Error fetching 1RM data: $e');
      return [];
    }
  }

  void _showAddExerciseMenu(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: themeService.currentTheme.cardTheme.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.bolt, color: Colors.orange),
                title: Text(
                  'Add to Quick Start', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeService.currentTheme.textTheme.titleMedium?.color,
                  )
                ),
                subtitle: Text(
                  'Start or add to current quick workout',
                  style: TextStyle(
                    color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addToQuickStart();
                },
              ),
              Divider(
                color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.dumbbell, color: Colors.blue),
                title: Text(
                  'Add to Custom Workouts', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeService.currentTheme.textTheme.titleMedium?.color,
                  )
                ),
                subtitle: Text(
                  'Add to a saved workout plan',
                  style: TextStyle(
                    color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCustomWorkoutSelection(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _addToQuickStart() {
    // Add haptic feedback when adding exercise to quick start
    HapticFeedback.mediumImpact();
    
    // Create a new QuickStartExercise with this exercise
    final newExercise = QuickStartExercise(
      title: widget.title,
      sets: [ExerciseSet()], // Start with one empty set
    );

    // Check if there's an existing quick start
    if (QuickStartOverlay.selectedExercises.isNotEmpty) {
      // Add to existing quick start
      QuickStartOverlay.selectedExercises.add(newExercise);
    } else {
      // Start a new quick start
      QuickStartOverlay.selectedExercises = [newExercise];
      QuickStartOverlay.startTimer();
    }

    // Navigate to the Quick Start page with sliding animation
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) => QuickStartPageOptimized(
          initialSelectedExercises: QuickStartOverlay.selectedExercises,
          showMinibarOnMinimize: true, // Show integrated minibar when minimizing
        ),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (ctx, animation, secAnim, child) {
          final tween = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero);
          return SlideTransition(
            position: tween.animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  void _showCustomWorkoutSelection(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    CustomWorkoutService.getSavedCustomWorkouts().then((customWorkouts) {
      if (!mounted) return;

      showModalBottomSheet(
        // ignore: use_build_context_synchronously
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: themeService.currentTheme.cardTheme.color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: FaIcon(
                        FontAwesomeIcons.xmark, 
                        color: themeService.currentTheme.textTheme.titleMedium?.color,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Expanded(
                      child: Text(
                        customWorkouts.isEmpty ? 'Create Custom Workout' : 'Select Custom Workout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeService.currentTheme.textTheme.titleMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40), // Balance the X button width
                  ],
                ),
                const SizedBox(height: 8),
                // Create New option - always shown first
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.plus, color: Colors.green),
                  title: Text(
                    'Create New',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeService.currentTheme.textTheme.titleMedium?.color,
                    ),
                  ),
                  subtitle: Text(
                    'Start a new custom workout with this exercise',
                    style: TextStyle(
                      color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewCustomWorkout();
                  },
                ),
                if (customWorkouts.isNotEmpty) ...[
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey,
                  ),
                                     Flexible(
                     child: ListView.separated(
                       controller: _customWorkoutScrollController,
                       shrinkWrap: true,
                       itemCount: customWorkouts.length,
                       separatorBuilder: (context, index) => Divider(
                         height: 1,
                         thickness: 1,
                         color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey,
                       ),
                       itemBuilder: (context, index) {
                         final workout = customWorkouts[index];
                         return ListTile(
                           leading: FaIcon(
                             FontAwesomeIcons.dumbbell, 
                             color: themeService.currentTheme.textTheme.titleMedium?.color,
                           ),
                           title: Text(
                             workout.name,
                             style: TextStyle(
                               fontWeight: FontWeight.bold,
                               color: themeService.currentTheme.textTheme.titleMedium?.color,
                             ),
                           ),
                           subtitle: Text(
                             '${workout.exercises.length} exercises',
                             style: TextStyle(
                               color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                             ),
                           ),
                           onTap: () {
                             Navigator.pop(context);
                             _addToCustomWorkout(workout);
                           },
                         );
                       },
                     ),
                   ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    }).catchError((e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error loading custom workouts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _addToCustomWorkout(CustomWorkout workout) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Create a new exercise to add
      final newExercise = CustomWorkoutExercise(
        name: widget.title,
        sets: [CustomWorkoutSet(weight: 0.0, reps: 0)], // Default set
      );

      // Add the exercise to the workout
      final updatedExercises = [...workout.exercises, newExercise];

      // Save the updated workout
      await CustomWorkoutService.deleteCustomWorkout(workout.id);
      await CustomWorkoutService.saveCustomWorkout(
        name: workout.name,
        exercises: updatedExercises,
        description: workout.description,
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleCheck,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Exercise Added',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${widget.title} → ${workout.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error adding exercise to workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createNewCustomWorkout() async {
    // Navigate to custom workout configuration page with this exercise pre-loaded
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => CustomWorkoutConfigurationPage(
          exerciseNames: [widget.title], // Pass current exercise as a list
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
        backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: FaIcon(FontAwesomeIcons.arrowLeft, color: themeService.currentTheme.appBarTheme.foregroundColor),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          title: AnimatedOpacity(
            opacity: _showTitle ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              widget.title,
              style: themeService.currentTheme.appBarTheme.titleTextStyle,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.purple,
            labelColor: Colors.purple,
            unselectedLabelColor: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            onTap: (index) {
              _showTitle = index == 1; // Show title for Records tab
              setState(() {});
            },
            tabs: const [
              Tab(text: 'Details'),
              Tab(text: 'Records'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Details Tab
            NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.axis == Axis.vertical) {
                  final show = scrollInfo.metrics.pixels > 80;
                  if (show != _showTitle) {
                    setState(() => _showTitle = show);
                  }
                }
                return false;
              },
              child: Scrollbar(
                thickness: 6,
                radius: const Radius.circular(10),
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: themeService.currentTheme.cardTheme.color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                          ),
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeService.currentTheme.textTheme.titleLarge?.color,
                            ),
                          ),
                        ),
                        // Main Muscle and Experience Level
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Primary: ${widget.mainMuscle}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: _getExperienceColor(widget.experienceLevel),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.experienceLevel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Secondary Muscle Label
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Secondary: ${widget.secondaryMuscle}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description Section
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: themeService.currentTheme.textTheme.titleMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 14, 
                            height: 1.5,
                            color: themeService.currentTheme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Video Demonstration
                        Text(
                          'Video Demonstration',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: themeService.currentTheme.textTheme.titleMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Video player or placeholder image
                        if (_ytController != null)
                          YoutubePlayerBuilder(
                            player: YoutubePlayer(
                              controller: _ytController!,
                              showVideoProgressIndicator: true,
                              bottomActions: [
                                CurrentPosition(),
                                ProgressBar(isExpanded: true),
                                RemainingDuration(),
                                IconButton(
                                  icon: const Icon(Icons.replay_10, color: Colors.white),
                                  onPressed: () => _ytController!.seekTo(_ytController!.value.position - const Duration(seconds: 10)),
                                ),
                                IconButton(
                                  icon: Icon(_ytController!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                                  onPressed: () {
                                    if (_ytController!.value.isPlaying) {
                                      _ytController!.pause();
                                    } else {
                                      _ytController!.play();
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.forward_10, color: Colors.white),
                                  onPressed: () => _ytController!.seekTo(_ytController!.value.position + const Duration(seconds: 10)),
                                ),
                                FullScreenButton(),
                              ],
                            ),
                            builder: (context, player) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: player,
                              );
                            },
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'lib/images/exerciseInformation.jpg',
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 16),
                        // How to do it section
                        Text(
                          'How to perform',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: themeService.currentTheme.textTheme.titleMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Numbered steps for howTo
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.howTo.split('\n').asMap().entries.map((entry) {
                            final idx = entry.key + 1;
                            final text = entry.value.trim();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 14, 
                                    height: 1.5,
                                    color: themeService.currentTheme.textTheme.bodyLarge?.color,
                                  ),
                                  children: [
                                    TextSpan(text: '$idx. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: text),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Safety and Precautions
                        Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.lightbulb, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'Pro Tips',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: themeService.currentTheme.textTheme.titleMedium?.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Pro Tips list with bolded numbered lines
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.proTips
                              .expand((tip) => tip.split('\n'))
                              .map((line) => line.trim())
                              .where((line) => line.isNotEmpty)
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                                final idx = entry.key + 1;
                                final text = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text.rich(
                                    TextSpan(
                                      style: TextStyle(
                                        fontSize: 14, 
                                        height: 1.5,
                                        color: themeService.currentTheme.textTheme.bodyLarge?.color,
                                      ),
                                      children: [
                                        TextSpan(text: '$idx. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: text),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // Add Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showAddExerciseMenu(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeService.isDarkMode ? Colors.white : Colors.black,
                              foregroundColor: themeService.isDarkMode ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.plus, 
                                  color: themeService.isDarkMode ? Colors.black : Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add This Exercise to Workout Plan',
                                  style: TextStyle(
                                    fontSize: 16, 
                                    color: themeService.isDarkMode ? Colors.black : Colors.white, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Records Tab
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getReal1RMData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.triangleExclamation,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading records',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeService.currentTheme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final oneRMData = snapshot.data ?? [];

                if (oneRMData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.trophy,
                          size: 64,
                          color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Records Yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: themeService.currentTheme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete workouts with ${widget.title}\nto see your 1RM progress here',
                          style: TextStyle(
                            fontSize: 16,
                            color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  primary: false,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Estimated 1 Rep Max
                      Text(
                        'Estimated 1 Rep Max',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeService.currentTheme.textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_format1RM(oneRMData.map((e) => e['estimated1RM'] as double).reduce((a, b) => a > b ? a : b))} kg',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: themeService.currentTheme.textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 1RM Progress Graph
                      Text(
                        '1RM Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeService.currentTheme.textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 1RM Progress Chart
                      SizedBox(
                        height: 300,
                        child: oneRMData.length < 2
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.chartLine,
                                      size: 48,
                                      color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Need more data',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: themeService.currentTheme.textTheme.titleMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Complete more workouts\nto see your progress',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: 20,
                                    verticalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: oneRMData.length > 10 ? (oneRMData.length / 5).ceil().toDouble() : 1,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          if (value.toInt() >= 0 && value.toInt() < oneRMData.length) {
                                            final date = oneRMData[value.toInt()]['date'] as DateTime;
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(
                                                '${date.day}/${date.month}',
                                                style: TextStyle(
                                                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SideTitleWidget(
                                            axisSide: AxisSide.bottom,
                                            child: Text(''),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: oneRMData.map((e) => e['estimated1RM'] as double).reduce((a, b) => a > b ? a : b) / 5,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text(
                                              '${value.toInt()}',
                                              style: TextStyle(
                                                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          );
                                        },
                                        reservedSize: 50,
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                      color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                    ),
                                  ),
                                  minX: 0,
                                  maxX: (oneRMData.length - 1).toDouble(),
                                  minY: 0,
                                  maxY: oneRMData.map((e) => e['estimated1RM'] as double).reduce((a, b) => a > b ? a : b) * 1.1,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: oneRMData.asMap().entries.map((entry) {
                                        return FlSpot(entry.key.toDouble(), entry.value['estimated1RM'] as double);
                                      }).toList(),
                                      isCurved: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.purple.shade400,
                                          Colors.purple.shade600,
                                        ],
                                      ),
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 4,
                                            color: Colors.purple.shade600,
                                            strokeWidth: 2,
                                            strokeColor: themeService.currentTheme.cardTheme.color!,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.purple.shade400.withOpacity(0.3),
                                            Colors.purple.shade600.withOpacity(0.1),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Divider(
                        color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        thickness: 1,
                      ),
                      const SizedBox(height: 24),

                      // Heaviest Weight Stat
                      Text(
                        'Heaviest Weight',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeService.currentTheme.textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatWeight(oneRMData.map((e) => e['weight'] as double).reduce((a, b) => a > b ? a : b))} kg (x${oneRMData.reduce((a, b) => (a['weight'] as double) > (b['weight'] as double) ? a : b)['reps']})',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: themeService.currentTheme.textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Heaviest Weight Progress Graph
                      Text(
                        'Heaviest Weight Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeService.currentTheme.textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Heaviest Weight Progress Chart
                      SizedBox(
                        height: 300,
                        child: oneRMData.length < 2
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.chartLine,
                                      size: 48,
                                      color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Need more data',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: themeService.currentTheme.textTheme.titleMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Complete more workouts\nto see your progress',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: 20,
                                    verticalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: oneRMData.length > 10 ? (oneRMData.length / 5).ceil().toDouble() : 1,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          if (value.toInt() >= 0 && value.toInt() < oneRMData.length) {
                                            final date = oneRMData[value.toInt()]['date'] as DateTime;
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(
                                                '${date.day}/${date.month}',
                                                style: TextStyle(
                                                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SideTitleWidget(
                                            axisSide: AxisSide.bottom,
                                            child: Text(''),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: oneRMData.map((e) => e['weight'] as double).reduce((a, b) => a > b ? a : b) / 5,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text(
                                              '${value.toInt()}',
                                              style: TextStyle(
                                                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          );
                                        },
                                        reservedSize: 50,
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                      color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                    ),
                                  ),
                                  minX: 0,
                                  maxX: (oneRMData.length - 1).toDouble(),
                                  minY: 0,
                                  maxY: oneRMData.map((e) => e['weight'] as double).reduce((a, b) => a > b ? a : b) * 1.1,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: oneRMData.asMap().entries.map((entry) {
                                        return FlSpot(entry.key.toDouble(), entry.value['weight'] as double);
                                      }).toList(),
                                      isCurved: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange.shade400,
                                          Colors.orange.shade600,
                                        ],
                                      ),
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 4,
                                            color: Colors.orange.shade600,
                                            strokeWidth: 2,
                                            strokeColor: themeService.currentTheme.cardTheme.color!,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange.shade400.withOpacity(0.3),
                                            Colors.orange.shade600.withOpacity(0.1),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 32),

                      // Divider
                      Divider(
                        color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        thickness: 1,
                      ),
                      const SizedBox(height: 24),

                      // Best Set Volume Stat
                      Text(
                        'Best Set Volume',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeService.currentTheme.textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatVolume(oneRMData.map((e) => (e['weight'] as double) * (e['reps'] as int)).reduce((a, b) => a > b ? a : b))} kg (${_formatWeight(oneRMData.reduce((a, b) => ((a['weight'] as double) * (a['reps'] as int)) > ((b['weight'] as double) * (b['reps'] as int)) ? a : b)['weight'])} kg × ${oneRMData.reduce((a, b) => ((a['weight'] as double) * (a['reps'] as int)) > ((b['weight'] as double) * (b['reps'] as int)) ? a : b)['reps']})',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: themeService.currentTheme.textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Best Set Volume Progress Graph
                      Text(
                        'Best Set Volume Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeService.currentTheme.textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Best Set Volume Progress Chart
                      SizedBox(
                        height: 300,
                        child: oneRMData.length < 2
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.chartLine,
                                      size: 48,
                                      color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Need more data',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: themeService.currentTheme.textTheme.titleMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Complete more workouts\nto see your progress',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: 20,
                                    verticalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: oneRMData.length > 10 ? (oneRMData.length / 5).ceil().toDouble() : 1,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          if (value.toInt() >= 0 && value.toInt() < oneRMData.length) {
                                            final date = oneRMData[value.toInt()]['date'] as DateTime;
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(
                                                '${date.day}/${date.month}',
                                                style: TextStyle(
                                                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SideTitleWidget(
                                            axisSide: AxisSide.bottom,
                                            child: Text(''),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: oneRMData.map((e) => (e['weight'] as double) * (e['reps'] as int)).reduce((a, b) => a > b ? a : b) / 5,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text(
                                              '${value.toInt()}',
                                              style: TextStyle(
                                                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          );
                                        },
                                        reservedSize: 50,
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                      color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                    ),
                                  ),
                                  minX: 0,
                                  maxX: (oneRMData.length - 1).toDouble(),
                                  minY: 0,
                                  maxY: oneRMData.map((e) => (e['weight'] as double) * (e['reps'] as int)).reduce((a, b) => a > b ? a : b) * 1.1,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: oneRMData.asMap().entries.map((entry) {
                                        return FlSpot(entry.key.toDouble(), (entry.value['weight'] as double) * (entry.value['reps'] as int));
                                      }).toList(),
                                      isCurved: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade400,
                                          Colors.green.shade600,
                                        ],
                                      ),
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 4,
                                            color: Colors.green.shade600,
                                            strokeWidth: 2,
                                            strokeColor: themeService.currentTheme.cardTheme.color!,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade400.withOpacity(0.3),
                                            Colors.green.shade600.withOpacity(0.1),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),


                    ],
                  ),
                );
              },
            ),
          ],
        ),
    );
  }
} 