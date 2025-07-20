import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/pages/history/workout_details_page.dart';
import 'package:gymfit/pages/history/workout_calendar_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<Map<String, dynamic>?> _getUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    final userInfo = await WorkoutService.getUserInfo(userId);
    if (userInfo != null) {
      _userCache[userId] = userInfo;
    }
    return userInfo;
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Workout History',
          style: themeService.currentTheme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.calendar,
              color: themeService.currentTheme.appBarTheme.foregroundColor,
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (context) => WorkoutCalendarPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          unselectedLabelColor: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Me'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyWorkoutsTab(),
          _buildFriendsWorkoutsTab(),
        ],
      ),
    );
  }

  Widget _buildMyWorkoutsTab() {
    return SafeArea(
      child: StreamBuilder<List<Workout>>(
        stream: WorkoutService.getUserWorkoutsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading workouts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final workouts = snapshot.data ?? [];

          if (workouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.dumbbell,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Workouts Yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your first workout to see it here!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return _buildWorkoutsList(workouts, showUserInfo: false);
        },
      ),
    );
  }

  Widget _buildFriendsWorkoutsTab() {
    return SafeArea(
      child: StreamBuilder<List<Workout>>(
        stream: WorkoutService.getFriendsWorkoutsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading friends\' workouts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final workouts = snapshot.data ?? [];

          if (workouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.userGroup,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Friends\' Activity',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add friends to see their workout activity here!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return _buildWorkoutsList(workouts, showUserInfo: true);
        },
      ),
    );
  }

  Widget _buildWorkoutsList(List<Workout> workouts, {required bool showUserInfo}) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          final dateFormat = DateFormat('MMM dd, yyyy');
          final timeFormat = DateFormat('h:mm a');

          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            color: themeService.currentTheme.cardTheme.color,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _showWorkoutDetails(context, workout, isOwnWorkout: !showUserInfo);
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _showWorkoutPreview(context, workout, isOwnWorkout: !showUserInfo);
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info for friends' workouts
                    if (showUserInfo)
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _getUserInfo(workout.userId),
                        builder: (context, snapshot) {
                          final userInfo = snapshot.data;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.purple.shade100,
                                  child: Text(
                                    userInfo?['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                                    style: TextStyle(
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  userInfo?['name'] ?? 'Unknown User',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    // Workout Name
                    if (workout.name.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          workout.name,
                          style: TextStyle(
                            fontSize: showUserInfo ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: showUserInfo ? themeService.currentTheme.textTheme.titleLarge?.color : Colors.purple,
                          ),
                        ),
                      ),

                    // Date and Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateFormat.format(workout.date),
                          style: TextStyle(
                            fontSize: workout.name.isNotEmpty ? 16 : 18,
                            fontWeight:
                                workout.name.isNotEmpty
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                            color:
                                workout.name.isNotEmpty
                                    ? (themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey[700])
                                    : themeService.currentTheme.textTheme.titleLarge?.color,
                          ),
                        ),
                        Text(
                          timeFormat.format(workout.date),
                          style: TextStyle(
                            fontSize: 14,
                            color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Workout Stats
                    Row(
                      children: [
                        // Duration
                        Expanded(
                          child: Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.stopwatch,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDuration(workout.duration),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Exercises
                        Expanded(
                          child: Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.dumbbell,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${workout.exercises.length} exercises',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sets
                        Expanded(
                          child: Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.check,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${workout.completedSets} sets',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Exercise List Preview
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          workout.exercises
                              .map(
                                (exercise) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 2.0,
                                  ),
                                  child: Text(
                                    '${exercise.completedSets} x ${exercise.title}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),

                    const SizedBox(height: 8),

                    // Tap hint
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Tap for details',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[500],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showWorkoutDetails(BuildContext context, Workout workout, {bool isOwnWorkout = true}) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => WorkoutDetailsPage(
          workout: workout, 
          isOwnWorkout: isOwnWorkout,
        ),
      ),
    );
  }

  void _showWorkoutPreview(BuildContext context, Workout workout, {bool isOwnWorkout = true}) {
    final themeService = Provider.of<ThemeService>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: themeService.currentTheme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              minWidth: 300,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sets and Reps List
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: workout.exercises.map((exercise) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: themeService.currentTheme.textTheme.titleLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...exercise.sets.map((set) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4, left: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${exercise.sets.indexOf(set) + 1}: ${set.weight.toInt() == set.weight ? set.weight.toInt() : set.weight}kg × ${set.reps}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        set.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                        size: 20,
                                        color: set.isCompleted ? Colors.green : (themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // View Details Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showWorkoutDetails(context, workout, isOwnWorkout: isOwnWorkout);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeService.isDarkMode ? Colors.grey.shade800 : Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'View Full Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewStat(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Column(
      children: [
        FaIcon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
          ),
        ),
      ],
    );
  }
}
