import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/models/calorie_entry.dart';
import 'package:gymfit/services/calorie_tracking_service.dart';
import 'package:gymfit/services/theme_service.dart';
import 'package:intl/intl.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/models/workout.dart';

class CaloriesTab extends StatefulWidget {
  const CaloriesTab({super.key});

  @override
  State<CaloriesTab> createState() => _CaloriesTabState();
}

class _CaloriesTabState extends State<CaloriesTab> {
  List<CalorieEntry> _todayEntries = [];
  int _todayTotal = 0;
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // For calories burnt
  List<Workout> _todayWorkouts = [];
  double _todayCaloriesBurnt = 0.0;

  // Controllers for manual workout entry
  final TextEditingController _workoutNameController = TextEditingController();
  final TextEditingController _workoutCaloriesController =
      TextEditingController();
  final TextEditingController _workoutDurationController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodayEntries();
    _loadTodayWorkouts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    _workoutNameController.dispose();
    _workoutCaloriesController.dispose();
    _workoutDurationController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await CalorieTrackingService.getCalorieEntriesForDate(
        DateTime.now(),
      );
      final total = await CalorieTrackingService.getTotalCaloriesForDate(
        DateTime.now(),
      );

      setState(() {
        _todayEntries = entries;
        _todayTotal = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading entries: $e')));
      }
    }
  }

  Future<void> _loadTodayWorkouts() async {
    setState(() {
      _todayCaloriesBurnt = 0.0;
      _todayWorkouts = [];
    });
    try {
      final workouts = await WorkoutService.getUserWorkouts();
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final todayWorkouts =
          workouts
              .where(
                (w) => w.date.isAfter(startOfDay) && w.date.isBefore(endOfDay),
              )
              .toList();
      final totalBurnt = todayWorkouts.fold(
        0.0,
        (sum, w) => sum + (w.calories),
      );
      setState(() {
        _todayWorkouts = todayWorkouts;
        _todayCaloriesBurnt = totalBurnt;
      });
    } catch (e) {
      // Optionally show error
    }
  }

  Future<void> _addCalorieEntry() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a food name')));
      return;
    }

    final calories = int.tryParse(_caloriesController.text);
    if (calories == null || calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid calorie amount')),
      );
      return;
    }

    try {
      await CalorieTrackingService.addCalorieEntry(
        name: _nameController.text.trim(),
        calories: calories,
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
      );

      // Clear form
      _nameController.clear();
      _caloriesController.clear();
      _notesController.clear();

      // Reload data
      await _loadTodayEntries();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calorie entry added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding entry: $e')));
      }
    }
  }

  Future<void> _addManualWorkout() async {
    if (_workoutNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout name')),
      );
      return;
    }

    final calories = double.tryParse(_workoutCaloriesController.text);
    if (calories == null || calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid calorie amount')),
      );
      return;
    }

    final durationMinutes = int.tryParse(_workoutDurationController.text);
    if (durationMinutes == null || durationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid duration in minutes'),
        ),
      );
      return;
    }

    try {
      // Create a simple workout with just the essential data

      // Save using WorkoutService
      await WorkoutService.saveWorkout(
        exercises: [], // Empty list for manual workout
        duration: Duration(minutes: durationMinutes),
        customWorkoutName: _workoutNameController.text.trim(),
        calories: calories,
      );

      // Clear form
      _workoutNameController.clear();
      _workoutCaloriesController.clear();
      _workoutDurationController.clear();

      // Reload data
      await _loadTodayWorkouts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding workout: $e')));
      }
    }
  }

  void _showAddWorkoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Manual Workout'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _workoutNameController,
                    decoration: const InputDecoration(
                      labelText: 'Workout Name',
                      hintText: 'e.g., Running, Swimming, Cycling',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _workoutCaloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories Burnt',
                      hintText: 'e.g., 300',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _workoutDurationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      hintText: 'e.g., 45',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _addManualWorkout();
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteEntry(String entryId) async {
    try {
      await CalorieTrackingService.deleteCalorieEntry(entryId);
      await _loadTodayEntries();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting entry: $e')));
      }
    }
  }

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Calorie Entry'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Food/Drink Name',
                      hintText: 'e.g., Apple, Coffee',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _caloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      hintText: 'e.g., 95',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'e.g., Large size, with cream',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _addCalorieEntry();
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calories Intake Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color:
                    isDark
                        ? (Colors.grey[700] ?? Colors.grey)
                        : (Colors.grey[300] ?? Colors.grey),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today\'s Calories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            themeService
                                .currentTheme
                                .textTheme
                                .titleLarge
                                ?.color ??
                            Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Text(
                        '$_todayTotal',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'calories',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Calories Burnt Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color:
                    isDark
                        ? (Colors.grey[700] ?? Colors.grey)
                        : (Colors.grey[300] ?? Colors.grey),
              ),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fitness_center, color: Colors.blue, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Calories Burnt Today",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            themeService
                                .currentTheme
                                .textTheme
                                .titleLarge
                                ?.color ??
                            Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      _todayCaloriesBurnt.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'calories',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List of today's workouts
          if (_todayWorkouts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color:
                      themeService.currentTheme.textTheme.titleMedium?.color ??
                      Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Workouts",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        themeService
                            .currentTheme
                            .textTheme
                            .titleMedium
                            ?.color ??
                        Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayWorkouts.length,
              itemBuilder: (context, index) {
                final workout = _todayWorkouts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isDark
                              ? (Colors.grey[700] ?? Colors.grey)
                              : (Colors.grey[300] ?? Colors.grey),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    themeService
                                        .currentTheme
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Duration: ${_formatDuration(workout.duration)}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${workout.calories.toStringAsFixed(0)} cal",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 20),

          // Add Entry Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddEntryDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Add Food/Drink',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddWorkoutDialog,
                  icon: const Icon(Icons.fitness_center, size: 18),
                  label: const Text(
                    'Add Workout',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Today's Entries
          Row(
            children: [
              Icon(
                Icons.list,
                color:
                    themeService.currentTheme.textTheme.titleMedium?.color ??
                    Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s Entries',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      themeService.currentTheme.textTheme.titleMedium?.color ??
                      Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Entries List
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_todayEntries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(Icons.restaurant, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No entries yet today',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Add Food/Drink" to start tracking',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayEntries.length,
              itemBuilder: (context, index) {
                final entry = _todayEntries[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isDark
                              ? (Colors.grey[700] ?? Colors.grey)
                              : (Colors.grey[300] ?? Colors.grey),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    themeService
                                        .currentTheme
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.black,
                              ),
                            ),
                            if (entry.notes != null &&
                                entry.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                entry.notes!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(entry.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.calories} cal',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteEntry(entry.id),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
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
}
