import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/workout.dart';
import 'package:gymfit/services/workout_service.dart';
import 'package:gymfit/pages/history/workout_details_page.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class WorkoutCalendarPage extends StatefulWidget {
  const WorkoutCalendarPage({super.key});

  @override
  State<WorkoutCalendarPage> createState() => _WorkoutCalendarPageState();
}

class _WorkoutCalendarPageState extends State<WorkoutCalendarPage> {
  late final ValueNotifier<List<DateTime>> _selectedDays;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Workout> workouts = [];
  Set<DateTime> workoutDays = {};
  int currentStreak = 0;
  int longestStreak = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedDays = ValueNotifier(_getWorkoutsForDay(_selectedDay!));
    _loadWorkouts();
  }

  @override
  void dispose() {
    _selectedDays.dispose();
    super.dispose();
  }

  Future<void> _loadWorkouts() async {
    try {
      final fetchedWorkouts = await WorkoutService.getUserWorkouts();
      setState(() {
        workouts = fetchedWorkouts;
        workoutDays = _getWorkoutDays(fetchedWorkouts);
        _calculateStreaks();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Set<DateTime> _getWorkoutDays(List<Workout> workouts) {
    return workouts.map((workout) {
      return DateTime(workout.date.year, workout.date.month, workout.date.day);
    }).toSet();
  }

  List<DateTime> _getWorkoutsForDay(DateTime day) {
    return workouts
        .where((workout) => isSameDay(workout.date, day))
        .map((workout) => workout.date)
        .toList();
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
    if (currentStreak == 0 &&
        workoutDays.contains(todayDate.subtract(const Duration(days: 1)))) {
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
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const Text(
          'Workout Calendar',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calendar
                    Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 12.0,
                        ),
                        child: TableCalendar<DateTime>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          eventLoader: _getWorkoutsForDay,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, day, events) {
                              if (events.isNotEmpty) {
                                return Positioned(
                                  bottom: 1,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.fitness_center,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            weekendTextStyle: const TextStyle(
                              color: Colors.black,
                            ),
                            holidayTextStyle: const TextStyle(
                              color: Colors.black,
                            ),
                            defaultTextStyle: const TextStyle(
                              color: Colors.black,
                            ),
                            todayDecoration: BoxDecoration(
                              color: Colors.blue.shade300,
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 1,
                            canMarkersOverflow: false,
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: true,
                            titleCentered: true,
                            formatButtonShowsNext: false,
                            formatButtonDecoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            formatButtonTextStyle: const TextStyle(
                              color: Colors.white,
                            ),
                            leftChevronPadding: const EdgeInsets.all(0),
                            rightChevronPadding: const EdgeInsets.all(0),
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            weekendStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onDaySelected: _onDaySelected,
                          onFormatChanged: (format) {
                            if (_calendarFormat != format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            }
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Workouts for Selected Day
                    _buildSelectedDayWorkouts(),
                  ],
                ),
              ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedDays.value = _getWorkoutsForDay(selectedDay);
    }
  }

  Widget _buildSelectedDayWorkouts() {
    if (_selectedDay == null) return const SizedBox.shrink();

    final selectedDateWorkouts =
        workouts
            .where((workout) => isSameDay(workout.date, _selectedDay!))
            .toList();

    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(_selectedDay!),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (selectedDateWorkouts.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.self_improvement,
                      color: Colors.grey.shade500,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No workouts on this day',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...selectedDateWorkouts.map((workout) {
                final timeFormat = DateFormat('h:mm a');
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder:
                              (context) => WorkoutDetailsPage(workout: workout),
                        ),
                      );
                    },
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _showWorkoutPreview(context, workout);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Workout Name and Time
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.tag,
                                      color: Colors.purple,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        workout.name.isNotEmpty
                                            ? workout.name
                                            : 'Workout',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                timeFormat.format(workout.date),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildWorkoutStat(
                                Icons.timer,
                                _formatDuration(workout.duration),
                                Colors.blue,
                              ),
                              const SizedBox(width: 16),
                              _buildWorkoutStat(
                                Icons.fitness_center,
                                '${workout.exercises.length} exercises',
                                Colors.green,
                              ),
                              const SizedBox(width: 16),
                              _buildWorkoutStat(
                                Icons.check_circle,
                                '${workout.completedSets} sets',
                                Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildWorkoutStat(
                                FontAwesomeIcons.fire,
                                workout.calories > 0
                                    ? '${workout.calories.round()} cal'
                                    : 'Not calculated',
                                workout.calories > 0 ? Colors.red : Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

  void _showWorkoutPreview(BuildContext context, Workout workout) {
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 1200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (workout.name.isNotEmpty) ...[
                                Text(
                                  workout.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                                const Text(
                                  'Workout Preview',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ] else
                                const Text(
                                  'Workout Preview',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date and Time
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.calendar,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${dateFormat.format(workout.date)} at ${timeFormat.format(workout.date)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Quick Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPreviewStat(
                                FontAwesomeIcons.stopwatch,
                                Colors.blue,
                                _formatDuration(workout.duration),
                                'Duration',
                              ),
                              _buildPreviewStat(
                                FontAwesomeIcons.dumbbell,
                                Colors.green,
                                '${workout.exercises.length}',
                                'Exercises',
                              ),
                              _buildPreviewStat(
                                FontAwesomeIcons.check,
                                Colors.orange,
                                '${workout.completedSets}',
                                'Sets',
                              ),
                              _buildPreviewStat(
                                FontAwesomeIcons.fire,
                                workout.calories > 0 ? Colors.red : Colors.grey,
                                workout.calories > 0
                                    ? '${workout.calories.round()}'
                                    : 'N/A',
                                'Calories',
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Exercise Summary
                          const Text(
                            'Exercises',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          ...workout.exercises.map((exercise) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Exercise Title and Summary
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color:
                                              exercise.completedSets > 0
                                                  ? Colors.green
                                                  : Colors.grey.shade400,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          exercise.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${exercise.completedSets}/${exercise.totalSets}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // All Sets Details
                                  ...exercise.sets.asMap().entries.map((entry) {
                                    final int setIndex = entry.key;
                                    final set = entry.value;

                                    return Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            set.isCompleted
                                                ? Colors.green.shade50
                                                : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color:
                                              set.isCompleted
                                                  ? Colors.green.shade200
                                                  : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Set ${setIndex + 1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  set.isCompleted
                                                      ? Colors.green.shade700
                                                      : Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            '${(set.weight % 1 == 0 ? set.weight.toInt() : set.weight)} kg × ${set.reps} reps',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  set.isCompleted
                                                      ? Colors.green.shade700
                                                      : Colors.grey.shade500,
                                            ),
                                          ),
                                          Icon(
                                            set.isCompleted
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            size: 16,
                                            color:
                                                set.isCompleted
                                                    ? Colors.green
                                                    : Colors.grey.shade400,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 16),

                          // View Details Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => WorkoutDetailsPage(
                                          workout: workout,
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPreviewStat(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Column(
      children: [
        FaIcon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
