import 'package:flutter/material.dart';
import 'package:gymfit/components/quick_start_overlay.dart';
import 'package:gymfit/pages/exercise_information_page.dart';
// Model to track exercise with sets and reps
class QuickStartExercise {
  final String title;
  int sets;
  int reps;
  bool isChecked;
  QuickStartExercise({required this.title, this.sets = 0, this.reps = 0, this.isChecked = false});
}

class QuickStartPage extends StatefulWidget {
  final List<QuickStartExercise> initialSelectedExercises;
  const QuickStartPage({Key? key, this.initialSelectedExercises = const <QuickStartExercise>[]}) : super(key: key);

  @override
  State<QuickStartPage> createState() => _QuickStartPageState();
}

class _QuickStartPageState extends State<QuickStartPage> {
  List<QuickStartExercise> _selectedExercises = [];

  @override
  void initState() {
    super.initState();
    _selectedExercises = widget.initialSelectedExercises.map((e) => QuickStartExercise(title: e.title, sets: e.sets, reps: e.reps, isChecked: e.isChecked)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
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
                            const Text(
                              'Your Exercises:',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: _selectedExercises
                                  .map(
                                    (e) => Card(
                                      color: Colors.white,
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              color: Colors.grey.shade100,
                                              child: Row(
                                                children: [
                                                  SizedBox(width: 60, child: const Text('Set', style: TextStyle(fontWeight: FontWeight.bold))),
                                                  const SizedBox(width: 16),
                                                  SizedBox(width: 100, child: const Text('Weight (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                                                  const SizedBox(width: 16),
                                                  SizedBox(width: 100, child: const Text('Reps', style: TextStyle(fontWeight: FontWeight.bold))),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              width: double.infinity,
                                              color: e.isChecked ? Colors.green.shade100 : Colors.transparent,
                                              padding: const EdgeInsets.all(4),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 60,
                                                    child: Center(child: Text('1', style: const TextStyle(fontSize: 16))),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  SizedBox(
                                                    width: 100,
                                                    child: TextFormField(
                                                      initialValue: e.sets.toString(),
                                                      decoration: const InputDecoration(),
                                                      keyboardType: TextInputType.number,
                                                      onChanged: (val) {
                                                        setState(() {
                                                          e.sets = int.tryParse(val) ?? 0;
                                                          QuickStartOverlay.selectedExercises = _selectedExercises;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  SizedBox(
                                                    width: 100,
                                                    child: TextFormField(
                                                      initialValue: e.reps.toString(),
                                                      decoration: const InputDecoration(),
                                                      keyboardType: TextInputType.number,
                                                      onChanged: (val) {
                                                        setState(() {
                                                          e.reps = int.tryParse(val) ?? 0;
                                                          QuickStartOverlay.selectedExercises = _selectedExercises;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  SizedBox(
                                                    width: 60,
                                                    child: Checkbox(
                                                      value: e.isChecked,
                                                      onChanged: (val) {
                                                        setState(() {
                                                          e.isChecked = val ?? false;
                                                          QuickStartOverlay.selectedExercises = _selectedExercises;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
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
                  icon: const Icon(Icons.add, color: Colors.white),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        QuickStartOverlay.selectedExercises = [];
                        Navigator.of(context).pop();
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
            ],
          ),
        ),
      ),
    );
  }
} 