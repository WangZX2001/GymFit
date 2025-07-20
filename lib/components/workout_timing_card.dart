import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';
import 'package:intl/intl.dart';

class WorkoutTimingCard extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final VoidCallback onStartTimeTap;
  final VoidCallback onEndTimeTap;

  const WorkoutTimingCard({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeTap,
    required this.onEndTimeTap,
  });

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

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final duration = endTime.difference(startTime);

    return Card(
      color: themeService.currentTheme.cardTheme.color,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onStartTimeTap,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Start',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              FaIcon(
                                FontAwesomeIcons.pen,
                                color: Colors.blue.shade400,
                                size: 10,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dateFormat.format(startTime)} ${timeFormat.format(startTime)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: onEndTimeTap,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'End',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              FaIcon(
                                FontAwesomeIcons.pen,
                                color: Colors.blue.shade400,
                                size: 10,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dateFormat.format(endTime)} ${timeFormat.format(endTime)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
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
                    'Duration: ${_formatDuration(duration)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 