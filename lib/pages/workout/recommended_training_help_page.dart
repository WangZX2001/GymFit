import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';
import 'package:gymfit/pages/me/recovery_help_page.dart';

class RecommendedTrainingHelpPage extends StatelessWidget {
  const RecommendedTrainingHelpPage({super.key});

  Widget _sectionHeader({
    required IconData icon,
    required Color color,
    required String title,
    required ThemeService themeService,
  }) {
    return Row(
      children: [
        FaIcon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: themeService.currentTheme.textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _sectionText(String text, ThemeService themeService, {double fontSize = 15, Color? color, FontWeight fontWeight = FontWeight.w500}) {
    final isDark = themeService.isDarkMode;
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: color ?? (isDark ? Colors.grey[200] : Colors.grey[800]),
        fontWeight: fontWeight,
      ),
    );
  }

  Widget _bulletList(List<String> items, ThemeService themeService) {
    final isDark = themeService.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 7),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.blue.shade400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    return Scaffold(
      backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: themeService.currentTheme.appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Recommended Training Help',
          style: themeService.currentTheme.appBarTheme.titleTextStyle,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                icon: FontAwesomeIcons.dumbbell,
                color: Colors.blue.shade400,
                title: 'How Recommended Training Works',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _sectionText(
                'The Recommended Training feature creates a personalized weekly workout plan just for you. It uses your fitness goals, experience level, body data, and any medical conditions to generate a plan that fits your needs.',
                themeService,
              ),
              const SizedBox(height: 24),
              _sectionHeader(
                icon: FontAwesomeIcons.listCheck,
                color: Colors.green.shade400,
                title: 'How Your Plan is Created',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _bulletList([
                'You answer a short questionnaire about your training days and preferred split (Full Body, Upper/Lower, or Push/Pull/Legs).',
                'The system uses your profile (goal, fitness level, age, BMI, medical conditions) to select the best exercises for you.',
                'Each day is assigned a training split and a set of exercises, with personalized sets, reps, and weights.',
                'You can review your plan, see your profile summary, and tap any day to start your workout.',
                'After finishing a workout, your progress is saved to your history.',
              ], themeService),
              const SizedBox(height: 24),
              _sectionHeader(
                icon: FontAwesomeIcons.userGear,
                color: Colors.purple.shade400,
                title: 'What Factors Are Considered?',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _bulletList([
                'Your fitness goal (e.g., gain muscle, lose weight)',
                'Your experience level (beginner, intermediate, advanced)',
                'Your age, BMI, and any medical conditions',
                'Your preferred training days and split',
                'Your previous workout history (for weights and reps, if available)',
              ], themeService),
              const SizedBox(height: 24),
              _sectionHeader(
                icon: FontAwesomeIcons.chartLine,
                color: Colors.indigo.shade400,
                title: 'How Your Workout History & 1RM Are Used',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _sectionText(
                'The app analyzes your previous workouts to estimate your 1RM (one-rep max) for each exercise. This allows the system to suggest personalized weights and reps for your current fitness level. If you have a workout history, your plan will use your actual performance data to recommend challenging but safe targets. If not, the app uses your body weight and general fitness level to make smart suggestions.',
                themeService,
              ),
              const SizedBox(height: 24),
              _sectionHeader(
                icon: FontAwesomeIcons.circleInfo,
                color: Colors.orange.shade400,
                title: 'How to Use Recommended Training',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _bulletList([
                'Go to the Recommended Training page from the Workout section.',
                'Complete the quick questionnaire.',
                'Review your personalized plan and tap any day to start your workout.',
                'You can switch between a list view and a calendar view.',
                'Your plan is saved and can be updated by retaking the questionnaire.',
              ], themeService),
              const SizedBox(height: 32),
              Divider(color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
              const SizedBox(height: 16),
              _sectionHeader(
                icon: FontAwesomeIcons.heartPulse,
                color: Colors.red.shade400,
                title: 'Want to know about Recovery & Fatigue?',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _sectionText(
                'For details on how recovery and fatigue are calculated, see the Recovery Help page.',
                themeService,
                fontSize: 14,
                color: Colors.blue,
              ),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Go to Recovery Help'),
                  style: TextButton.styleFrom(
                    foregroundColor: themeService.isDarkMode ? Colors.blue[200] : Colors.blue[700],
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RecoveryHelpPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _sectionText(
                'For more technical details, see the Recommended Training System documentation or contact support.',
                themeService,
                fontSize: 13,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 