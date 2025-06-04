import 'package:flutter/material.dart';

class ExerciseInformationPage extends StatelessWidget {
  const ExerciseInformationPage({super.key});

  Widget _buildExerciseCard(String title, dynamic icon, {bool isImage = false, double? customPadding}) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isImage)
            Image.asset(
              icon as String,
              height: 100,
              width: 100,
              fit: BoxFit.contain,
            )
          else
            Icon(
              icon as IconData,
              size: 100,
              color: Colors.black,
            ),
          SizedBox(height: customPadding ?? 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Exercise Information',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1, // Make cards slightly taller than wide
              children: [
                _buildExerciseCard('Overhead Press\n(Barbell)', 'lib/images/exercises/overheadPress (barbell).jpeg', isImage: true, customPadding: 4),
                _buildExerciseCard('Side Lateral\nRaise', Icons.fitness_center),
                _buildExerciseCard('Incline\nDumbbell Raise', Icons.fitness_center),
                _buildExerciseCard('Dumbbell\nOverhead', Icons.fitness_center),
                _buildExerciseCard('Standing\nDumbbell Press', Icons.fitness_center),
                _buildExerciseCard('Seated Barbell\nPress', Icons.fitness_center),
                _buildExerciseCard('Linear Jammer', Icons.fitness_center),
                _buildExerciseCard('Car Driver', Icons.fitness_center),
                _buildExerciseCard('External\nRotation', Icons.fitness_center),
                _buildExerciseCard('Shoulder Press', Icons.fitness_center),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Click on any exercise icon to view specific instructions.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 