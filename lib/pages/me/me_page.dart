import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:gymfit/models/workout.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/services/recovery_service.dart';
import 'package:gymfit/pages/me/statistics_page.dart';
import 'package:gymfit/pages/me/friends_page.dart';
import 'package:gymfit/pages/me/recovery_page.dart';
import 'package:gymfit/pages/me/settings/settings_page.dart';
import 'package:gymfit/services/theme_service.dart';
import 'package:gymfit/services/user_profile_service.dart';

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
  
  // User profile data
  String? userName;
  String? userUsername;
  bool isLoadingProfile = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WorkoutService.addWorkoutUpdateListener(_onWorkoutUpdate);
    UserProfileService().addListener(_onProfileUpdate);
    _loadWorkouts();
    _loadUserProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WorkoutService.removeWorkoutUpdateListener(_onWorkoutUpdate);
    UserProfileService().removeListener(_onProfileUpdate);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadWorkouts();
      _loadUserProfile();
      // Also refresh recovery data when app resumes
      RecoveryService.refreshRecoveryData();
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

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              userName = data['name'] as String?;
              userUsername = data['username'] as String?;
              isLoadingProfile = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              isLoadingProfile = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProfile = false;
        });
      }
    }
  }

  // Method to manually refresh data (can be called from other parts of the app)
  Future<void> refreshData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        isLoadingProfile = true;
      });
      await _loadWorkouts();
      await _loadUserProfile();
      // Also refresh recovery data when manually refreshing
      await RecoveryService.refreshRecoveryData();
    }
  }

  // Callback for workout updates
  void _onWorkoutUpdate() {
    _loadWorkouts();
    _loadUserProfile();
    // Automatically refresh recovery data when workouts are updated/deleted
    RecoveryService.refreshRecoveryData();
  }

  // Callback for profile updates
  void _onProfileUpdate() {
    _loadUserProfile();
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
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Me', 
          style: themeService.currentTheme.appBarTheme.titleTextStyle,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              // User Profile Section
              GestureDetector(
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: themeService.isDarkMode 
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: themeService.isDarkMode 
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.user,
                            size: 80,
                            color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isLoadingProfile 
                                ? 'Loading...'
                                : userName ?? 'No Name',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeService.currentTheme.textTheme.titleLarge?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLoadingProfile
                                ? 'Loading username...'
                                : userUsername != null 
                                    ? '@$userUsername'
                                    : 'No Username',
                            style: TextStyle(
                              fontSize: 12,
                              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Settings icon in top right corner
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.gear,
                          size: 20,
                          color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                        ),
                      ),
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
                          FontAwesomeIcons.fire,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStreakCard(
                          'Longest Streak',
                          longestStreak.toString(),
                          FontAwesomeIcons.trophy,
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
                          FontAwesomeIcons.dumbbell,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStreakCard(
                          'Workout Days',
                          workoutDays.length.toString(),
                          FontAwesomeIcons.calendarDays,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons List
                  Container(
                    decoration: BoxDecoration(
                      color: themeService.isDarkMode 
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: themeService.isDarkMode 
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Statistics Button
                        _buildActionButton(
                          title: 'Statistics',
                          icon: FontAwesomeIcons.chartLine,
                          color: Colors.blue.shade600,
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => const StatisticsPage(),
                              ),
                            );
                          },
                          isFirst: true,
                        ),
                        // Divider
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: themeService.isDarkMode 
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          indent: 16,
                          endIndent: 16,
                        ),
                        // Friends Button
                        _buildActionButton(
                          title: 'Friends',
                          icon: FontAwesomeIcons.users,
                          color: Colors.green.shade600,
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => const FriendsPage(),
                              ),
                            );
                          },
                          isFirst: false,
                        ),
                        // Divider
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: themeService.isDarkMode 
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          indent: 16,
                          endIndent: 16,
                        ),
                        // Recovery Button
                        _buildActionButton(
                          title: 'Recovery',
                          icon: FontAwesomeIcons.heartPulse,
                          color: Colors.red.shade400,
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => const RecoveryPage(),
                              ),
                            );
                          },
                          isFirst: false,
                          isLast: true,
                        ),
                      ],
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
      ),
    );
  }

  Widget _buildStreakCard(String title, String value, IconData icon, Color color) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    return Card(
      color: themeService.isDarkMode 
          ? const Color(0xFF2A2A2A)
          : Colors.grey.shade50,
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
                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isFirst,
    bool isLast = false,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.only(
        topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
        topRight: isFirst ? const Radius.circular(16) : Radius.zero,
        bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
        bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeService.currentTheme.textTheme.titleLarge?.color,
                ),
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 16,
              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
} 