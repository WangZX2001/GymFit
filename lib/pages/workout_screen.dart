import 'package:flutter/material.dart';
import 'package:gymfit/pages/exercise_information_page.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildWorkoutCard(
                'Quick Start',
                'lib/images/quickStart.jpg',
                () {},
                alignment: Alignment.bottomCenter,
              ),
              _buildWorkoutCard(
                'Exercise Information',
                'lib/images/exerciseInformation.jpg',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExerciseInformationPage(),
                    ),
                  );
                },
              ),
              Column(
                children: [
                  _buildWorkoutCard(
                    'Recommended Training',
                    'lib/images/reccomendedTraining.jpg',
                    () {},
                    alignment: Alignment.bottomCenter,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'For recommended training, a personalized workout plan automatically generated based on your body info, fitness goals, and experience level.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              _buildWorkoutCard(
                'Custom Workout',
                'lib/images/customWorkout.jpg',
                () {},
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Workout tab
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(color: Colors.black, fontSize: 10),
        unselectedLabelStyle: const TextStyle(color: Colors.black, fontSize: 10),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            label: 'Workout',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(String title, String imagePath, VoidCallback onTap, {Alignment alignment = Alignment.center}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              alignment: alignment,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 