import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/services/custom_workout_service.dart';

// Model to track individual set data for template
class TemplateExerciseSet {
  final String id;
  int weight;
  int reps;
  
  TemplateExerciseSet({this.weight = 0, this.reps = 0}) 
    : id = '${DateTime.now().millisecondsSinceEpoch}_${weight * 1000 + reps}';
}

// Model to track exercise with multiple sets for template
class TemplateExercise {
  final String title;
  List<TemplateExerciseSet> sets;
  
  TemplateExercise({required this.title, List<TemplateExerciseSet>? sets}) 
    : sets = sets ?? [TemplateExerciseSet()];
}

class CustomWorkoutConfigurationPage extends StatefulWidget {
  final List<String> exerciseNames;
  
  const CustomWorkoutConfigurationPage({
    super.key,
    required this.exerciseNames,
  });

  @override
  State<CustomWorkoutConfigurationPage> createState() => _CustomWorkoutConfigurationPageState();
}

class _CustomWorkoutConfigurationPageState extends State<CustomWorkoutConfigurationPage> {
  List<ConfigExercise> _exercises = [];
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _exercises = widget.exerciseNames.map((name) => ConfigExercise(title: name)).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomWorkout() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout name')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final customExercises = _exercises.map((exercise) {
        final customSets = exercise.sets.map((set) => 
          CustomWorkoutSet(weight: set.weight, reps: set.reps)
        ).toList();
        
        return CustomWorkoutExercise(
          name: exercise.title,
          sets: customSets,
        );
      }).toList();

      await CustomWorkoutService.saveCustomWorkout(
        name: _nameController.text.trim(),
        exercises: customExercises,
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Configure Workout',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveCustomWorkout,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workout Name',
                hintText: 'Enter workout name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...exercise.sets.asMap().entries.map((entry) {
                          final setIndex = entry.key;
                          final set = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Text('Set ${setIndex + 1}:'),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Weight (kg)',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: (value) {
                                      set.weight = int.tryParse(value) ?? 0;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Reps',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: (value) {
                                      set.reps = int.tryParse(value) ?? 0;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: exercise.sets.length > 1 ? () {
                                    setState(() {
                                      exercise.sets.remove(set);
                                    });
                                  } : null,
                                ),
                              ],
                            ),
                          );
                        }),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              exercise.sets.add(ConfigSet());
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Set'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ConfigExercise {
  final String title;
  List<ConfigSet> sets;
  
  ConfigExercise({required this.title}) : sets = [ConfigSet()];
}

class ConfigSet {
  int weight = 0;
  int reps = 0;
} 