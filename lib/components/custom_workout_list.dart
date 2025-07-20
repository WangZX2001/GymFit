import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/services/theme_service.dart';

class CustomWorkoutList extends StatelessWidget {
  final List<CustomWorkout> customWorkouts;
  final bool loadingCustomWorkouts;
  final Function(CustomWorkout) onWorkoutSelected;

  const CustomWorkoutList({
    super.key,
    required this.customWorkouts,
    required this.loadingCustomWorkouts,
    required this.onWorkoutSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    if (loadingCustomWorkouts) {
      return const SizedBox(height: 80);
    }

    if (customWorkouts.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 80),
          Divider(
            color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.push_pin_outlined,
                  size: 32,
                  color: themeService.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No pinned workouts',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pin your favorite workouts to see them here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeService.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 80),
        Divider(
          color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.push_pin,
              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Pinned',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeService.currentTheme.textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < customWorkouts.length; i++) ...[
          if (i > 0) ...[
            Divider(
              color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade600,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
              height: 1,
            ),
          ],
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FaIcon(
                  FontAwesomeIcons.dumbbell,
                  color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.black,
                  size: 20,
                ),
              ),
              title: Text(
                customWorkouts[i].name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: themeService.currentTheme.textTheme.titleMedium?.color,
                ),
              ),
              subtitle: Text(
                '${customWorkouts[i].exerciseNames.length} exercises',
                style: TextStyle(
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.play_arrow,
                color: Colors.green,
              ),
              tileColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () => onWorkoutSelected(customWorkouts[i]),
            ),
          ),
        ],
      ],
    );
  }
} 