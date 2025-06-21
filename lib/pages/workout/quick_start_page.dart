import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:gymfit/pages/workout/workout_summary_page.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedExercises = widget.initialSelectedExercises.map((e) => QuickStartExercise(title: e.title, sets: e.sets)).toList();
    
    // Start the shared timer in overlay if not already started
    QuickStartOverlay.startTimer();
    
    // Register for timer updates
    QuickStartOverlay.setPageUpdateCallback(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Clear the page update callback
    QuickStartOverlay.setPageUpdateCallback(null);
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
        title: Row(
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 350;
            final mainPadding = isSmallScreen ? 12.0 : 16.0;
            
            return Padding(
              padding: EdgeInsets.fromLTRB(mainPadding, mainPadding, mainPadding, 0.0),
              child: Column(
                children: [
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