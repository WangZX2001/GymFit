import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/services/recommended_training_service.dart';
import 'package:gymfit/pages/workout/quick_start_page_refactored.dart';
import 'package:gymfit/models/quick_start_exercise.dart';
import 'package:gymfit/models/exercise_set.dart';
import 'package:gymfit/components/chatbot.dart';

class RecommendedTrainingPage extends StatefulWidget {
  const RecommendedTrainingPage({super.key});

  @override
  State<RecommendedTrainingPage> createState() =>
      _RecommendedTrainingPageState();
}

class _RecommendedTrainingPageState extends State<RecommendedTrainingPage> {
  CustomWorkout? _recommendedWorkout;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _generateRecommendedWorkout();
  }

  Future<void> _generateRecommendedWorkout() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      _userData = await RecommendedTrainingService.getUserBodyData();
      final workout =
          await RecommendedTrainingService.generateRecommendedWorkout();
      if (mounted) {
        setState(() {
          _recommendedWorkout = workout;
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

  void _startWorkout() {
    if (_recommendedWorkout != null) {
      // Add haptic feedback when starting recommended workout
      HapticFeedback.mediumImpact();
      final quickStartExercises =
          _recommendedWorkout!.exercises.map((exercise) {
            return QuickStartExercise(
              title: exercise.name,
              sets:
                  exercise.sets
                      .map(
                        (set) =>
                            ExerciseSet(weight: set.weight, reps: set.reps),
                      )
                      .toList(),
            );
          }).toList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => QuickStartPage(
                initialSelectedExercises: quickStartExercises,
                initialWorkoutName: _recommendedWorkout!.name,
                showMinibarOnMinimize: false,
              ),
        ),
      );
    }
  }

  void _regenerateWorkout() {
    _generateRecommendedWorkout();
  }

  Widget _buildHeroBanner() {
    return Stack(
      children: [
        Container(
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            image: const DecorationImage(
              image: AssetImage('lib/images/reccomendedTraining.jpg'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Recommended Training',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalQuote() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 24),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '“The only bad workout is the one that didn’t happen.”',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontStyle: FontStyle.italic,
                color: Colors.black87,
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
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                    color: Colors.black,
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
                    _userData!['bmi'].toString(),
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
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 16),
      ),
      label: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: 'DMSans',
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }

  Widget _buildWorkoutCard() {
    if (_recommendedWorkout == null) return const SizedBox.shrink();
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.blue, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recommendedWorkout!.name
                            .replaceAll('LoseWeight', 'Lose Weight')
                            .replaceAll('GainMuscle', 'Gain Muscle')
                            .replaceAllMapped(
                              RegExp(
                                r'Recommended (.+) \((.+)\)',
                                caseSensitive: false,
                              ),
                              (m) =>
                                  'Recommended ${m[1]!.replaceAll(RegExp(r'([a-z])([A-Z])'), r'\1 \2')}',
                            ),
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_recommendedWorkout!.name.contains('('))
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            _recommendedWorkout!.name.contains('(')
                                ? _recommendedWorkout!.name
                                    .split('(')
                                    .last
                                    .replaceAll(')', '')
                                : '',
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_recommendedWorkout!.description != null &&
                _recommendedWorkout!.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Text(
                  _recommendedWorkout!.description!,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            const Divider(height: 24),
            Text(
              'Exercises',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            ..._recommendedWorkout!.exercises.map(
              (exercise) => _exerciseTile(exercise),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startWorkout,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Workout'),
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _regenerateWorkout,
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    label: const Text('Regenerate'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseTile(CustomWorkoutExercise exercise) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Show set details
          Row(
            children: [
              const SizedBox(width: 30), // Align with exercise name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${exercise.sets.length} sets',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Show progressive rep scheme
                    if (_hasProgressiveReps(exercise.sets))
                      _buildProgressiveRepsDisplay(exercise.sets)
                    else
                      Text(
                        '${exercise.sets.first.weight > 0 ? '${exercise.sets.first.weight.toStringAsFixed(1)}kg' : 'Bodyweight'} × ${exercise.sets.first.reps} reps each set',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Check if the exercise has progressive reps or weights (different reps/weights per set)
  bool _hasProgressiveReps(List<CustomWorkoutSet> sets) {
    if (sets.length <= 1) return false;
    final firstReps = sets.first.reps;
    final firstWeight = sets.first.weight;
    return sets.any(
      (set) => set.reps != firstReps || set.weight != firstWeight,
    );
  }

  /// Build progressive reps display
  Widget _buildProgressiveRepsDisplay(List<CustomWorkoutSet> sets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progressive scheme:',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children:
              sets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    'Set ${index + 1}: ${set.weight > 0 ? '${set.weight.toStringAsFixed(1)}kg' : 'BW'} × ${set.reps} reps',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Generating your personalized workout...',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              color: Colors.black87,
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Recommended Training'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          fontFamily: 'DMSans',
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
              ? _buildErrorState()
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroBanner(),
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
                    _buildWorkoutCard(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
    );
  }
}
