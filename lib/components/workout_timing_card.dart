import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';
import 'package:intl/intl.dart';

class WorkoutTimingCard extends StatelessWidget {
  final DateTime startTime;
  final Duration duration;
  final VoidCallback onStartDateTap;
  final VoidCallback onStartTimeTap;
  final VoidCallback onDurationTap;

  const WorkoutTimingCard({
    super.key,
    required this.startTime,
    required this.duration,
    required this.onStartDateTap,
    required this.onStartTimeTap,
    required this.onDurationTap,
  });

  String _formatDuration(Duration duration) {
    String hours = duration.inHours.toString();
    String minutes = duration.inMinutes.remainder(60).toString();
    
    if (duration.inHours > 0) {
      return '$hours h $minutes min';
    } else {
      return '$minutes min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Column(
      children: [
        // Header
        Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.clock,
              color: Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text(
              'Workout Timing',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Start Date and Time Selection
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start',
              style: TextStyle(
                fontSize: 12,
                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onStartDateTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateFormat.format(startTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          FaIcon(
                            FontAwesomeIcons.calendar,
                            color: Colors.blue.shade400,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: onStartTimeTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              timeFormat.format(startTime),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          FaIcon(
                            FontAwesomeIcons.clock,
                            color: Colors.blue.shade400,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Duration
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duration',
              style: TextStyle(
                fontSize: 12,
                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onDurationTap,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.stopwatch,
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Spacer(),
                    FaIcon(
                      FontAwesomeIcons.pen,
                      color: Colors.blue.shade400,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 