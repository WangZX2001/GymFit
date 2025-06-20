import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:gymfit/pages/exercise_information_page.dart';
// Model to track individual set data
class ExerciseSet {
  final String id;
  int weight;
  int reps;
  bool isChecked;
  ExerciseSet({this.weight = 0, this.reps = 0, this.isChecked = false}) 
    : id = DateTime.now().millisecondsSinceEpoch.toString() + '_' + (weight * 1000 + reps).toString();
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
        title: const Text(
          'Quick Start',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
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
                                              child: Row(
                                                children: [
                                                  SizedBox(width: 60, child: Center(child: const Text('Set', style: TextStyle(fontWeight: FontWeight.bold)))),
                                                  const SizedBox(width: 16),
                                                                                                      SizedBox(width: 110, child: Center(child: const Text('Weight (kg)', style: TextStyle(fontWeight: FontWeight.bold)))),
                                                    const SizedBox(width: 16),
                                                    SizedBox(width: 80, child: Center(child: const Text('Reps', style: TextStyle(fontWeight: FontWeight.bold)))),
                                                    const SizedBox(width: 16),
                                                    SizedBox(
                                                      width: 60,
                                                      child: Center(
                                                        child: Checkbox(
                                                          value: e.sets.every((set) => set.isChecked),
                                                          tristate: true,
                                                          fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                                                            if (states.contains(MaterialState.selected)) {
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
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 60,
                                                        child: Center(child: Text('${setIndex + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      SizedBox(
                                                        width: 110,
                                                        child: Center(
                                                          child: SizedBox(
                                                            width: 80,
                                                            child: TextFormField(
                                                              initialValue: exerciseSet.weight.toString(),
                                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                                              textAlign: TextAlign.center,
                                                              decoration: InputDecoration(
                                                                border: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  borderSide: BorderSide.none,
                                                                ),
                                                                filled: true,
                                                                fillColor: exerciseSet.isChecked ? Colors.green.shade200 : Colors.grey.shade300,
                                                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                                      const SizedBox(width: 16),
                                                      SizedBox(
                                                        width: 80,
                                                        child: TextFormField(
                                                          initialValue: exerciseSet.reps.toString(),
                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                          textAlign: TextAlign.center,
                                                          decoration: InputDecoration(
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                              borderSide: BorderSide.none,
                                                            ),
                                                            filled: true,
                                                            fillColor: exerciseSet.isChecked ? Colors.green.shade200 : Colors.grey.shade300,
                                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                                      const SizedBox(width: 16),
                                                                                                              SizedBox(
                                                          width: 60,
                                                          child: Center(
                                                            child: Checkbox(
                                                              value: exerciseSet.isChecked,
                                                              fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                                                                if (states.contains(MaterialState.selected)) {
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
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
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
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final bool? confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('End Workout'),
                                            content: const Text('Are you sure you want to end workout?'),
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
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: const Text(
                                      'Finish',
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<List<String>>(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const ExerciseInformationPage(
                          isSelectionMode: true,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        // Append new picks as QuickStartExercise entries
                        final newExercises = result.map((title) => QuickStartExercise(title: title)).toList();
                        _selectedExercises.addAll(newExercises);
                        QuickStartOverlay.selectedExercises = _selectedExercises;
                      });
                    }
                  },
                  icon: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
                  label: const Text(
                    'Add Exercises',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 