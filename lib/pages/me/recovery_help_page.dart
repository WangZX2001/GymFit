import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class RecoveryHelpPage extends StatelessWidget {
  const RecoveryHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
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
          'Recovery Help',
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
                icon: FontAwesomeIcons.heartPulse,
                color: Colors.red.shade400,
                title: 'What is Recovery Status?',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _sectionText(
                'Recovery status represents how well each muscle group has recovered since its last workout. A higher percentage means the muscle is more ready for training, while a lower percentage means it still needs rest.',
                themeService,
              ),
              const SizedBox(height: 16),
              _recoveryStatusTable(themeService, isDark),
              const SizedBox(height: 24),

              _sectionHeader(
                icon: FontAwesomeIcons.calculator,
                color: Colors.blue.shade400,
                title: 'How is Recovery Calculated?',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _sectionText(
                'After each workout, your recovery percentage for each muscle group is recalculated based on the intensity and type of exercise performed. The calculation uses your recent workout history and your estimated 1RM (one-rep max) for relevant lifts.',
                themeService,
              ),
              const SizedBox(height: 8),
              _sectionText(
                'Here’s how it works:',
                themeService,
                fontWeight: FontWeight.bold,
              ),
              _bulletList([
                'Workout intensity: The app estimates how hard you trained a muscle group by comparing the weight you lifted to your 1RM (one-rep max). Lifting closer to your 1RM causes a greater initial reduction in recovery.',
                'Recovery reduction curve: The app analyzes your past workouts to determine how quickly your muscles typically recover. It uses this data to create a personalized recovery curve, so your recovery rate adapts to your training habits.',
                'Time since last trained: Recovery percentage increases gradually over time, following your personal recovery curve.',
                'Compound vs. isolation: Compound exercises (like squats or bench press) cause a larger drop in recovery than isolation exercises (like curls).',
                'Fatigue score: High training volume or intensity slows down recovery.',
              ], themeService),
              const SizedBox(height: 24),

              _sectionHeader(
                icon: FontAwesomeIcons.gaugeHigh,
                color: Colors.orange.shade400,
                title: 'Fatigue & Recovery Rate',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _sectionText(
                'Your fatigue score for each muscle group is calculated by analyzing all the exercises you performed for that muscle in the past week. The app sums up your total training volume and intensity for the last 7 days, then compares it to your baseline for that muscle group.',
                themeService,
              ),
              _sectionText(
                'A higher fatigue score means you have trained that muscle group more than your usual baseline, which slows down your recovery rate. If your fatigue score is above 1.5, recovery is slowed by 20%.',
                themeService,
              ),
              _sectionText(
                'Typical recovery rates:',
                themeService,
              ),
              _fatigueScoreTable(themeService, isDark),
              const SizedBox(height: 8),
              _bulletList([
                'Fast (24-48h): Forearms, calves, core, neck',
                'Moderate (48-72h): Biceps, triceps, shoulders',
                'Slow (72-96h): Chest, back, legs, glutes',
              ], themeService),
              const SizedBox(height: 24),

              _sectionHeader(
                icon: FontAwesomeIcons.ruler,
                color: Colors.green.shade400,
                title: 'Baselines & Customization',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _sectionText(
                'Each muscle group has a weekly baseline volume, which is the expected amount of training (sets, reps, or weight) for optimal recovery. By default, this baseline is automatically adjusted based on your body weight—so heavier users will have higher baselines for larger muscle groups.',
                themeService,
              ),
              _sectionText(
                'You can override the default by setting a custom baseline for any muscle group. When you do, the app will use your custom value instead of the body weight-adjusted default for all recovery and fatigue calculations.',
                themeService,
              ),
              _sectionText(
                'Keeping your baselines accurate helps the app give you the best recovery recommendations for your unique body and training style.',
                themeService,
              ),
              const SizedBox(height: 24),

              _sectionHeader(
                icon: FontAwesomeIcons.lightbulb,
                color: Colors.purple.shade400,
                title: 'Tips for Optimizing Recovery',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _bulletList([
                'Focus on muscle groups with low recovery percentages before training them again.',
                'Allow extra rest for muscle groups with high fatigue scores.',
                'Compound lifts (like squats, deadlifts) require more recovery time.',
                'Monitor your weekly training volume and adjust baselines as needed.',
                'Listen to your body—recovery is individual and can vary.',
              ], themeService),
              const SizedBox(height: 32),
              Divider(color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
              const SizedBox(height: 16),
              _sectionText(
                'For more details or questions, contact support or check the app documentation.',
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

  Widget _recoveryStatusTable(ThemeService themeService, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: IntrinsicColumnWidth(),
          2: FlexColumnWidth(),
          3: IntrinsicColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text('Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text('Meaning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text('Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
              ),
            ],
          ),
          _recoveryStatusRow('Ready', '80-100%', 'Muscle is fully recovered and ready for training.', const Color(0xFF4CAF50), false, isDark),
          _recoveryStatusRow('Moderate', '60-79%', 'Muscle is moderately recovered, can train with caution.', const Color(0xFFFF9800), true, isDark),
          _recoveryStatusRow('Needs Rest', '40-59%', 'Muscle needs more rest before training.', const Color(0xFFFF5722), false, isDark),
          _recoveryStatusRow('Rest Required', '0-39%', 'Muscle is not recovered, avoid training.', const Color(0xFFF44336), true, isDark),
        ],
      ),
    );
  }

  TableRow _recoveryStatusRow(String status, String range, String meaning, Color color, bool alt, bool isDark) {
    return TableRow(
      decoration: BoxDecoration(color: alt ? (isDark ? const Color(0xFF292929) : Colors.grey[50]) : (isDark ? const Color(0xFF232323) : Colors.white)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Text(status, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Text(range, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Text(meaning, softWrap: true, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Container(width: 24, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        ),
      ],
    );
  }

  Widget _fatigueScoreTable(ThemeService themeService, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: IntrinsicColumnWidth(),
          2: FlexColumnWidth(),
          3: IntrinsicColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text('Training Volume', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text('Recovery Effect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text('Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
              ),
            ],
          ),
          _fatigueScoreRow('0.0 - 1.0', 'Low', 'Normal recovery', Colors.green, false, isDark),
          _fatigueScoreRow('1.0 - 1.5', 'Moderate', 'Normal recovery', Colors.blue, true, isDark),
          _fatigueScoreRow('1.5 - 2.0', 'High', 'Recovery slowed by 20%', Colors.orange, false, isDark),
          _fatigueScoreRow('2.0+', 'Very High', 'Recovery slowed by 20%', Colors.red, true, isDark),
        ],
      ),
    );
  }

  TableRow _fatigueScoreRow(String score, String volume, String effect, Color color, bool alt, bool isDark) {
    return TableRow(
      decoration: BoxDecoration(color: alt ? (isDark ? const Color(0xFF292929) : Colors.grey[50]) : (isDark ? const Color(0xFF232323) : Colors.white)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Text(score, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Text(volume, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Text(effect, softWrap: true, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Container(width: 24, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        ),
      ],
    );
  }
} 