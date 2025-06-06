import 'package:flutter/material.dart';
import 'package:gymfit/pages/exercise_information_page.dart';
import 'package:gymfit/pages/quick_start_page.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  OverlayEntry? _minibarEntry;
  void _openQuickStart() {
    // Remove any existing minimized bar
    _minibarEntry?.remove();
    _minibarEntry = null;
    // Open full Quick Start page
    pushScreenWithNavBar(
      context,
      QuickStartPage(onMinimize: () {
        Navigator.of(context).pop();
        _showMinibar();
      }),
    );
  }

  /// Show a non-blocking minimized Quick Start bar via an overlay
  void _showMinibar() {
    // Remove any existing overlay
    _minibarEntry?.remove();
    final overlay = Overlay.of(context);
    final bottomOffset = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight - 50.0;
    _minibarEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16.0,
        right: 16.0,
        bottom: bottomOffset,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onTap: () {
              // Remove minimized bar and reopen full Quick Start
              _minibarEntry?.remove();
              _minibarEntry = null;
              _openQuickStart();
            },
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.keyboard_arrow_up, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'Quick Start',
                    style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_minibarEntry!);
  }

  @override
  void dispose() {
    _minibarEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildWorkoutCard(
                'Quick Start',
                'lib/images/quickStart.jpg',
                _openQuickStart,
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
                  Colors.black.withAlpha(77),
                  Colors.black.withAlpha(128),
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