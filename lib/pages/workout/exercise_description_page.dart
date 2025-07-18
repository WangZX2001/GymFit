import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:gymfit/pages/workout/quick_start_page_refactored.dart';
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

class _ExerciseDescriptionPageState extends State<ExerciseDescriptionPage> {
  YoutubePlayerController? _ytController;
  bool _showTitle = false;
  final ScrollController _customWorkoutScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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

  void _showAddExerciseMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.bolt, color: Colors.orange),
                title: const Text('Add to Quick Start', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Start or add to current quick workout'),
                onTap: () {
                  Navigator.pop(context);
                  _addToQuickStart();
                },
              ),
              const Divider(),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.dumbbell, color: Colors.blue),
                title: const Text('Add to Custom Workouts', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Add to a saved workout plan'),
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
        pageBuilder: (ctx, animation, secondaryAnimation) => QuickStartPage(
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
              color: Colors.grey.shade200,
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.black),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Expanded(
                      child: Text(
                        customWorkouts.isEmpty ? 'Create Custom Workout' : 'Select Custom Workout',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                  title: const Text(
                    'Create New',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Start a new custom workout with this exercise'),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewCustomWorkout();
                  },
                ),
                if (customWorkouts.isNotEmpty) ...[
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey,
                  ),
                                     Flexible(
                     child: ListView.separated(
                       controller: _customWorkoutScrollController,
                       shrinkWrap: true,
                       itemCount: customWorkouts.length,
                       separatorBuilder: (context, index) => const Divider(
                         height: 1,
                         thickness: 1,
                         color: Colors.grey,
                       ),
                       itemBuilder: (context, index) {
                         final workout = customWorkouts[index];
                         return ListTile(
                           leading: const FaIcon(FontAwesomeIcons.dumbbell, color: Colors.black),
                           title: Text(
                             workout.name,
                             style: const TextStyle(fontWeight: FontWeight.bold),
                           ),
                           subtitle: Text('${workout.exercises.length} exercises'),
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
    return Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade200,
          elevation: 0,
          leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.black),
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
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: NotificationListener<ScrollNotification>(
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description Section
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // Video Demonstration
                    const Text(
                      'Video Demonstration',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    const Text(
                      'How to perform',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                              style: const TextStyle(fontSize: 14, height: 1.5),
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
                      children: const [
                        FaIcon(FontAwesomeIcons.lightbulb, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Pro Tips',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                  style: const TextStyle(fontSize: 14, height: 1.5),
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
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            FaIcon(FontAwesomeIcons.plus, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Add This Exercise to Workout Plan',
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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
    );
  }
} 