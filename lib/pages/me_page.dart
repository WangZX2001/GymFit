import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymfit/pages/auth_page.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/pages/statistics_page.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<Workout> workouts = [];
  Set<DateTime> workoutDays = {};
  int currentStreak = 0;
  int longestStreak = 0;
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WorkoutService.addWorkoutUpdateListener(_onWorkoutUpdate);
    _loadWorkouts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WorkoutService.removeWorkoutUpdateListener(_onWorkoutUpdate);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadWorkouts();
    }
  }

  Future<void> _loadWorkouts() async {
    try {
      final fetchedWorkouts = await WorkoutService.getUserWorkouts();
      if (mounted) {
        setState(() {
          workouts = fetchedWorkouts;
          workoutDays = _getWorkoutDays(fetchedWorkouts);
          _calculateStreaks();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Method to manually refresh data (can be called from other parts of the app)
  Future<void> refreshData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
      await _loadWorkouts();
    }
  }

  // Callback for workout updates
  void _onWorkoutUpdate() {
    _loadWorkouts();
  }

  Set<DateTime> _getWorkoutDays(List<Workout> workouts) {
    return workouts.map((workout) {
      return DateTime(workout.date.year, workout.date.month, workout.date.day);
    }).toSet();
  }

  void _calculateStreaks() {
    if (workoutDays.isEmpty) {
      currentStreak = 0;
      longestStreak = 0;
      return;
    }

    final sortedDays = workoutDays.toList()..sort();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Calculate current streak
    currentStreak = 0;
    DateTime checkDate = todayDate;
    
    while (workoutDays.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    // If no workout today, check if there was one yesterday
    if (currentStreak == 0 && workoutDays.contains(todayDate.subtract(const Duration(days: 1)))) {
      checkDate = todayDate.subtract(const Duration(days: 1));
      while (workoutDays.contains(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // Calculate longest streak
    longestStreak = 0;
    int tempStreak = 1;
    
    for (int i = 1; i < sortedDays.length; i++) {
      final previousDay = sortedDays[i - 1];
      final currentDay = sortedDays[i];
      
      if (currentDay.difference(previousDay).inDays == 1) {
        tempStreak++;
      } else {
        longestStreak = longestStreak > tempStreak ? longestStreak : tempStreak;
        tempStreak = 1;
      }
    }
    longestStreak = longestStreak > tempStreak ? longestStreak : tempStreak;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Me', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              final nav = Navigator.of(context, rootNavigator: true);
              FirebaseAuth.instance.signOut().then((_) {
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (c) => const AuthPage()),
                  (route) => false,
                );
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User Profile Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
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
                child: Column(
                  children: [
                    Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? 'No user',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'User ID: ${FirebaseAuth.instance.currentUser?.uid.substring(0, 8) ?? 'N/A'}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Workout Statistics
                if (!isLoading) ...[
                  // Streak Information Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStreakCard(
                          'Current Streak',
                          currentStreak.toString(),
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStreakCard(
                          'Longest Streak',
                          longestStreak.toString(),
                          Icons.military_tech,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Total Workouts Card
                  Row(
                    children: [
                      Expanded(
                        child: _buildStreakCard(
                          'Total Workouts',
                          workouts.length.toString(),
                          Icons.fitness_center,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStreakCard(
                          'Workout Days',
                          workoutDays.length.toString(),
                          Icons.calendar_month,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Statistics Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) => const StatisticsPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Statistics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 40),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildStreakCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 