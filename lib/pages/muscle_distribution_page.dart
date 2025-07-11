import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/packages/exercise_information_repository/exercise_information_repository.dart';

class MuscleDistributionPage extends StatefulWidget {
  const MuscleDistributionPage({super.key});

  @override
  State<MuscleDistributionPage> createState() => _MuscleDistributionPageState();
}

class _MuscleDistributionPageState extends State<MuscleDistributionPage> {
  Map<String, int> muscleGroupSets = {
    'Back': 0,
    'Chest': 0,
    'Core': 0,
    'Shoulders': 0,
    'Arms': 0,
    'Legs': 0,
  };
  bool isLoading = true;
  int totalSets = 0;

  @override
  void initState() {
    super.initState();
    _loadMuscleDistribution();
  }

  Future<void> _loadMuscleDistribution() async {
    try {
      // Load both workout data and exercise information
      final futures = await Future.wait([
        WorkoutService.getUserWorkouts(),
        ExerciseInformationRepository().getAllExerciseInformation(),
      ]);
      
      final workouts = futures[0] as List<Workout>;
      final allExerciseInfo = futures[1] as List<ExerciseInformation>;
      
      final muscleCount = <String, int>{
        'Back': 0,
        'Chest': 0,
        'Core': 0,
        'Shoulders': 0,
        'Arms': 0,
        'Legs': 0,
      };
      
      // Count sets for each muscle group
      for (final workout in workouts) {
        for (final exercise in workout.exercises) {
          // Find exercise info to get muscle group
          final exerciseInfo = allExerciseInfo.firstWhere(
            (info) => info.title.toLowerCase() == exercise.title.toLowerCase(),
            orElse: () => const ExerciseInformation(
              title: '',
              icon: '',
              mainMuscle: 'Unknown',
              secondaryMuscle: '',
              experienceLevel: '',
              equipment: '',
              howTo: '',
              description: '',
              proTips: [],
            ),
          );
          
          // Map muscle groups to our categories
          final mappedMuscleGroup = _mapMuscleGroup(exerciseInfo.mainMuscle);
          if (mappedMuscleGroup != null) {
            muscleCount[mappedMuscleGroup] = (muscleCount[mappedMuscleGroup] ?? 0) + exercise.completedSets;
          }
        }
      }
      
      final total = muscleCount.values.fold(0, (sum, count) => sum + count);
      
      if (mounted) {
        setState(() {
          muscleGroupSets = muscleCount;
          totalSets = total;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading muscle distribution data: $e')),
        );
      }
    }
  }

  String? _mapMuscleGroup(String mainMuscle) {
    final muscle = mainMuscle.toLowerCase();
    
    // Map various muscle names to our 6 categories
    if (muscle.contains('back') || muscle.contains('lat') || muscle.contains('rhomboid') || 
        muscle.contains('trap') || muscle.contains('rear delt')) {
      return 'Back';
    } else if (muscle.contains('chest') || muscle.contains('pectoral') || muscle.contains('pec')) {
      return 'Chest';
    } else if (muscle.contains('core') || muscle.contains('abs') || muscle.contains('abdominal') || 
               muscle.contains('oblique') || muscle.contains('lower back')) {
      return 'Core';
    } else if (muscle.contains('shoulder') || muscle.contains('deltoid') || muscle.contains('delt')) {
      return 'Shoulders';
    } else if (muscle.contains('bicep') || muscle.contains('tricep') || muscle.contains('arm') || 
               muscle.contains('forearm')) {
      return 'Arms';
    } else if (muscle.contains('leg') || muscle.contains('quad') || muscle.contains('hamstring') || 
               muscle.contains('glute') || muscle.contains('calf') || muscle.contains('thigh')) {
      return 'Legs';
    }
    
    return null; // Unknown muscle group
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Muscle Distribution', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.black),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : totalSets == 0
                ? _buildEmptyState()
                : _buildMuscleDistribution(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.chartPie,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No muscle data found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some workouts to see your muscle distribution!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleDistribution() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purple.shade200,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                FaIcon(
                  FontAwesomeIcons.chartPie,
                  size: 48,
                  color: Colors.purple.shade600,
                ),
                const SizedBox(height: 12),
                Text(
                  'Muscle Group Distribution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on completed sets',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.purple.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Radar Chart
          Container(
            height: 400,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: RadarChart(
              RadarChartData(
                radarTouchData: RadarTouchData(enabled: false),
                dataSets: [
                  RadarDataSet(
                    fillColor: Colors.purple.withValues(alpha: 0.2),
                    borderColor: Colors.purple.shade600,
                    entryRadius: 3,
                    dataEntries: _getRadarDataEntries(),
                    borderWidth: 2,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(color: Colors.grey.shade300, width: 1),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                getTitle: (index, angle) {
                  final titles = ['Back', 'Chest', 'Core', 'Shoulders', 'Arms', 'Legs'];
                  return RadarChartTitle(text: titles[index]);
                },
                tickCount: 5,
                ticksTextStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
                tickBorderData: BorderSide(color: Colors.grey.shade300, width: 1),
                gridBorderData: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Statistics Cards
          _buildMuscleGroupCards(),
        ],
      ),
    );
  }

  List<RadarEntry> _getRadarDataEntries() {
    final maxSets = muscleGroupSets.values.fold(0, (max, current) => current > max ? current : max);
    if (maxSets == 0) return List.generate(6, (index) => const RadarEntry(value: 0));
    
    return [
      RadarEntry(value: (muscleGroupSets['Back']! / maxSets) * 100),
      RadarEntry(value: (muscleGroupSets['Chest']! / maxSets) * 100),
      RadarEntry(value: (muscleGroupSets['Core']! / maxSets) * 100),
      RadarEntry(value: (muscleGroupSets['Shoulders']! / maxSets) * 100),
      RadarEntry(value: (muscleGroupSets['Arms']! / maxSets) * 100),
      RadarEntry(value: (muscleGroupSets['Legs']! / maxSets) * 100),
    ];
  }

  Widget _buildMuscleGroupCards() {
    final muscleGroups = [
      {'name': 'Back', 'icon': FontAwesomeIcons.arrowUp, 'color': Colors.blue},
      {'name': 'Chest', 'icon': FontAwesomeIcons.expand, 'color': Colors.red},
      {'name': 'Core', 'icon': FontAwesomeIcons.circle, 'color': Colors.orange},
      {'name': 'Shoulders', 'icon': FontAwesomeIcons.mountain, 'color': Colors.green},
      {'name': 'Arms', 'icon': FontAwesomeIcons.dumbbell, 'color': Colors.purple},
      {'name': 'Legs', 'icon': FontAwesomeIcons.walking, 'color': Colors.teal},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: muscleGroups.length,
      itemBuilder: (context, index) {
        final group = muscleGroups[index];
        final sets = muscleGroupSets[group['name'] as String] ?? 0;
        final percentage = totalSets > 0 ? (sets / totalSets * 100).round() : 0;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                group['icon'] as IconData,
                color: group['color'] as Color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                group['name'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$sets sets',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 12,
                  color: group['color'] as Color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 