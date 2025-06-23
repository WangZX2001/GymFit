import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:gymfit/pages/workout/workout_name_description_page.dart';

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

  @override
  void initState() {
    super.initState();
    _exercises = widget.exerciseNames.map((name) => ConfigExercise(title: name)).toList();
  }

  void _proceedToNameDescription() {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise')),
      );
      return;
    }

    // Convert exercises to CustomWorkoutExercise format
    final customExercises = _exercises.map((exercise) {
      final customSets = exercise.sets.map((set) => 
        CustomWorkoutSet(weight: set.weight, reps: set.reps)
      ).toList();
      
      return CustomWorkoutExercise(
        name: exercise.title,
        sets: customSets,
      );
    }).toList();

    // Navigate to name/description page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutNameDescriptionPage(
          exercises: customExercises,
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Configure Workout',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _proceedToNameDescription,
            icon: const Icon(Icons.done, color: Colors.black, size: 24),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return Dismissible(
                  key: Key('exercise_${exercise.title}_$index'),
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
                      _exercises.removeAt(index);
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
                                        exercise.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...exercise.sets.asMap().entries.map((entry) {
                                    final setIndex = entry.key;
                                    final set = entry.value;
                                    return Dismissible(
                                      key: Key('${exercise.title}_${set.id}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        margin: const EdgeInsets.symmetric(vertical: 2),
                                        color: Colors.red,
                                        child: const FaIcon(
                                          FontAwesomeIcons.trash,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      onDismissed: (direction) {
                                        if (exercise.sets.length > 1) {
                                          setState(() {
                                            exercise.sets.remove(set);
                                          });
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(4),
                                        margin: const EdgeInsets.symmetric(vertical: 2),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final availableWidth = constraints.maxWidth;
                                            final isSmallScreen = availableWidth < 350;
                                            final spacing = isSmallScreen ? 6.0 : 8.0;
                                            
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
                                                        initialValue: set.weight.toString(),
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
                                                          fillColor: Colors.grey.shade300,
                                                          contentPadding: EdgeInsets.symmetric(
                                                            horizontal: isSmallScreen ? 4 : 6,
                                                            vertical: 4,
                                                          ),
                                                        ),
                                                        keyboardType: TextInputType.number,
                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                        onChanged: (value) {
                                                          set.weight = int.tryParse(value) ?? 0;
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
                                                        initialValue: set.reps.toString(),
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
                                                          fillColor: Colors.grey.shade300,
                                                          contentPadding: EdgeInsets.symmetric(
                                                            horizontal: isSmallScreen ? 4 : 6,
                                                            vertical: 4,
                                                          ),
                                                        ),
                                                        keyboardType: TextInputType.number,
                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                        onChanged: (value) {
                                                          set.reps = int.tryParse(value) ?? 0;
                                                        },
                                                      ),
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
                                exercise.sets.add(ConfigSet());
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
            ),
          ),
          // Add Exercises Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
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
                          // Append new exercises as ConfigExercise entries
                          final newExercises = result.map((title) => ConfigExercise(title: title)).toList();
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
  final String id;
  int weight = 0;
  int reps = 0;
  
  static int _counter = 0;
  
  ConfigSet() : id = '${DateTime.now().millisecondsSinceEpoch}_${++_counter}';
} 