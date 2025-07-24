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
              const SizedBox(height: 24),

              // --- NEW: Next optimal training window ---
              _sectionHeader(
                icon: FontAwesomeIcons.clock,
                color: Colors.teal.shade400,
                title: 'Next Optimal Training Window',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _sectionText(
                'For each muscle group, the app shows when you’ll be optimally recovered (usually 80%+). If you’re already ready, you’ll see a green check. Otherwise, you’ll see how long to wait for best results.',
                themeService,
              ),
              const SizedBox(height: 24),

              // --- NEW: Personalization note ---
              _sectionHeader(
                icon: FontAwesomeIcons.userGear,
                color: Colors.indigo.shade400,
                title: 'Personalized Recovery',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _sectionText(
                'Your recovery curve adapts to your training habits and body. If you train a muscle more than usual, recovery slows down. If you train less, it speeds up. The app uses your recent workout history and body weight to personalize your recovery.',
                themeService,
              ),
              const SizedBox(height: 24),

              // --- NEW: Compound/multiple exercises note ---
              _sectionHeader(
                icon: FontAwesomeIcons.dumbbell,
                color: Colors.brown.shade400,
                title: 'Compound & Multiple Exercises',
                themeService: themeService,
              ),
              const SizedBox(height: 8),
              _sectionText(
                'Compound lifts (like squats, bench press) and doing several exercises for the same muscle group in one session cause a bigger drop in recovery. The app combines their effects to reflect real muscle fatigue.',
                themeService,
              ),
              const SizedBox(height: 32),
              Divider(color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
              const SizedBox(height: 16),
              _sectionText(
                'For more details or questions, contact support or check the app documentation.',
                themeService,
                fontSize: 13,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),

              // --- NEW: Read More button ---
              Center(
                child: TextButton(
                  onPressed: () => _showTechnicalDetails(context, themeService),
                  style: TextButton.styleFrom(
                    foregroundColor: themeService.isDarkMode ? Colors.blue[200] : Colors.blue[700],
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Read More',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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

  void _showTechnicalDetails(BuildContext context, ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeService.currentTheme.cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                icon: FontAwesomeIcons.code,
                color: Colors.blueGrey.shade400,
                title: 'Technical Details: Recovery Calculation',
                themeService: themeService,
              ),
              const SizedBox(height: 16),
              _sectionText('• Recovery is calculated using an exponential curve personalized to your habits and body:', themeService),
              const SizedBox(height: 8),
              SelectableText('recovery(t) = initial_recovery + (100 - initial_recovery) × (1 - e^(-k × t))',
                style: TextStyle(fontSize: 15, color: themeService.isDarkMode ? Colors.grey[200] : Colors.grey[800], fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _sectionText('Where k is based on muscle group, exercise type, training load, and is slowed by high fatigue score.', themeService),
              const SizedBox(height: 16),
              _sectionText('• Fatigue Score:', themeService, fontWeight: FontWeight.bold),
              _sectionText('Fatigue Score = (Weekly Volume for Muscle Group) / (Baseline Volume). If >1.5, recovery is slowed by 20%.', themeService),
              const SizedBox(height: 16),
              _sectionText('• Compound Sessions & Multiple Exercises:', themeService, fontWeight: FontWeight.bold),
              _sectionText('Multiple exercises for the same muscle group in a session are combined, and compound lifts cause a larger drop in recovery.', themeService),
              const SizedBox(height: 16),
              _sectionText('• Minimum Recovery Thresholds:', themeService, fontWeight: FontWeight.bold),
              _minRecoveryTable(themeService),
              const SizedBox(height: 16),
              _sectionText('• "Next optimal training window" is calculated by solving the recovery curve for when you reach 80% recovery:', themeService),
              SelectableText('t = -ln(1 - (threshold - current) / (100 - current)) / k',
                style: TextStyle(fontSize: 15, color: themeService.isDarkMode ? Colors.grey[200] : Colors.grey[800], fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              _sectionText('• Muscle Group Recovery Rates:', themeService, fontWeight: FontWeight.bold),
              _recoveryRatesTable(themeService),
              const SizedBox(height: 16),
              _sectionText('• Default Baseline Volumes:', themeService, fontWeight: FontWeight.bold),
              _baselineVolumesTable(themeService),
              const SizedBox(height: 16),
              _sectionText('• Workout Loads per Session:', themeService, fontWeight: FontWeight.bold),
              _workoutLoadsTable(themeService),
              const SizedBox(height: 24),
              _sectionText('Summary:', themeService, fontWeight: FontWeight.bold),
              _sectionText('The app uses your recent workout history (volume, intensity, frequency) and body weight to adjust the speed of your recovery curve for each muscle group, making it unique to your habits and body.', themeService),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: themeService.isDarkMode ? Colors.blue[200] : Colors.blue[700],
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _minRecoveryTable(ThemeService themeService) {
    final isDark = themeService.isDarkMode;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
      },
      border: TableBorder.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.grey[300]),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Exercise Type', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Min Recovery (%)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        _minRecoveryRow('deadlift, squat, clean, snatch', '5', isDark),
        _minRecoveryRow('bench, press, row, pulldown', '10', isDark),
        _minRecoveryRow('curl, extension, fly, raise', '20', isDark),
        _minRecoveryRow('crunch, plank, stretch', '50', isDark),
        _minRecoveryRow('(default)', '15', isDark),
      ],
    );
  }
  TableRow _minRecoveryRow(String type, String min, bool isDark) {
    return TableRow(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF232323) : Colors.white),
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text(type)),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(min)),
      ],
    );
  }
  Widget _recoveryRatesTable(ThemeService themeService) {
    final isDark = themeService.isDarkMode;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
      },
      border: TableBorder.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.grey[300]),
          children: [
            Padding(padding: const EdgeInsets.all(8.0), child: Text('Muscle Group', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('Typical Recovery Time', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        _recoveryRatesRow('Forearms', '0.35', '24–36h (fast)', isDark),
        _recoveryRatesRow('Calves', '0.32', '24–36h (fast)', isDark),
        _recoveryRatesRow('Core', '0.30', '24–48h (fast)', isDark),
        _recoveryRatesRow('Neck', '0.28', '24–48h (fast)', isDark),
        _recoveryRatesRow('Biceps', '0.25', '48–72h (moderate)', isDark),
        _recoveryRatesRow('Triceps', '0.23', '48–72h (moderate)', isDark),
        _recoveryRatesRow('Shoulders', '0.22', '48–72h (moderate)', isDark),
        _recoveryRatesRow('Chest', '0.18', '48–96h (slow)', isDark),
        _recoveryRatesRow('Back', '0.16', '72–96h (slow)', isDark),
        _recoveryRatesRow('Quadriceps', '0.15', '72–96h (slow)', isDark),
        _recoveryRatesRow('Hamstrings', '0.14', '72–96h (slow)', isDark),
        _recoveryRatesRow('Glutes', '0.13', '72–96h (slow)', isDark),
        _recoveryRatesRow('Other', '0.20', 'Default', isDark),
      ],
    );
  }
  TableRow _recoveryRatesRow(String group, String rate, String time, bool isDark) {
    return TableRow(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF232323) : Colors.white),
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text(group)),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(rate)),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(time)),
      ],
    );
  }
  Widget _baselineVolumesTable(ThemeService themeService) {
    final isDark = themeService.isDarkMode;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
      },
      border: TableBorder.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.grey[300]),
          children: [
            Padding(padding: const EdgeInsets.all(8.0), child: Text('Muscle Group', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('Baseline Volume', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        _baselineVolumesRow('Chest', '12,000', isDark),
        _baselineVolumesRow('Back', '15,000', isDark),
        _baselineVolumesRow('Quadriceps', '20,000', isDark),
        _baselineVolumesRow('Hamstrings', '12,000', isDark),
        _baselineVolumesRow('Shoulders', '8,000', isDark),
        _baselineVolumesRow('Biceps', '6,000', isDark),
        _baselineVolumesRow('Triceps', '6,000', isDark),
        _baselineVolumesRow('Calves', '3,000', isDark),
        _baselineVolumesRow('Core', '4,000', isDark),
        _baselineVolumesRow('Glutes', '8,000', isDark),
        _baselineVolumesRow('Forearms', '8,000', isDark),
        _baselineVolumesRow('Neck', '8,000', isDark),
        _baselineVolumesRow('Other', '8,000', isDark),
      ],
    );
  }
  TableRow _baselineVolumesRow(String group, String volume, bool isDark) {
    return TableRow(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF232323) : Colors.white),
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text(group)),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(volume)),
      ],
    );
  }
  Widget _workoutLoadsTable(ThemeService themeService) {
    final isDark = themeService.isDarkMode;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
      },
      border: TableBorder.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.grey[300]),
          children: [
            Padding(padding: const EdgeInsets.all(8.0), child: Text('Muscle Group', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('Workout Load', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        _workoutLoadsRow('Chest', '3,000', isDark),
        _workoutLoadsRow('Back', '4,000', isDark),
        _workoutLoadsRow('Quadriceps', '5,000', isDark),
        _workoutLoadsRow('Hamstrings', '2,800', isDark),
        _workoutLoadsRow('Shoulders', '1,200', isDark),
        _workoutLoadsRow('Biceps', '540', isDark),
        _workoutLoadsRow('Triceps', '720', isDark),
        _workoutLoadsRow('Calves', '2,700', isDark),
        _workoutLoadsRow('Core', '1,200', isDark),
        _workoutLoadsRow('Glutes', '4,000', isDark),
        _workoutLoadsRow('Forearms', '4,000', isDark),
        _workoutLoadsRow('Neck', '2,000', isDark),
        _workoutLoadsRow('Other', '2,500', isDark),
      ],
    );
  }
  TableRow _workoutLoadsRow(String group, String load, bool isDark) {
    return TableRow(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF232323) : Colors.white),
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text(group)),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(load)),
      ],
    );
  }
} 