import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/recovery.dart';
import 'package:gymfit/services/recovery_service.dart';
import 'package:gymfit/services/theme_service.dart';

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> with AutomaticKeepAliveClientMixin {
  RecoveryData? recoveryData;
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    RecoveryService.addRecoveryUpdateListener(_onRecoveryUpdate);
    _loadRecoveryData();
  }

  @override
  void dispose() {
    RecoveryService.removeRecoveryUpdateListener(_onRecoveryUpdate);
    super.dispose();
  }

  void _onRecoveryUpdate() {
    if (mounted) {
      _loadRecoveryData();
    }
  }

  Future<void> _loadRecoveryData() async {
    try {
      final data = await RecoveryService.getRecoveryData();
      if (mounted) {
        setState(() {
          recoveryData = data;
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

  Future<void> _refreshData() async {
    setState(() {
      isRefreshing = true;
    });

    try {
      final data = await RecoveryService.refreshRecoveryData();
      if (mounted) {
        setState(() {
          recoveryData = data;
          isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Recovery Status',
          style: themeService.currentTheme.appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : recoveryData == null
                ? _buildEmptyState(themeService)
                : _buildRecoveryContent(themeService),
      ),
    );
  }

  Widget _buildEmptyState(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.bed,
            size: 64,
            color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'No Recovery Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeService.currentTheme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some workouts to see your recovery status',
            style: TextStyle(
              fontSize: 14,
              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryContent(ThemeService themeService) {
    final muscleGroups = recoveryData!.muscleGroups;
    
    // Sort muscle groups by recovery percentage (lowest first)
    muscleGroups.sort((a, b) => a.recoveryPercentage.compareTo(b.recoveryPercentage));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with last updated time
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: themeService.isDarkMode 
                  ? const Color(0xFF2A2A2A)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: themeService.isDarkMode 
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.heartPulse,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recovery Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeService.currentTheme.textTheme.titleLarge?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${_formatDateTime(recoveryData!.lastUpdated)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recovery status legend
          _buildLegend(themeService),

          const SizedBox(height: 24),

          // Recovery rates legend
          _buildRecoveryRatesLegend(themeService),

          const SizedBox(height: 24),

          // Post-workout recovery guide
          _buildPostWorkoutRecoveryGuide(themeService),

          const SizedBox(height: 24),

          // Fatigue score legend
          _buildFatigueLegend(themeService),

          const SizedBox(height: 24),

          // Muscle groups list
          Text(
            'Muscle Groups',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeService.currentTheme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),

                     ...muscleGroups.map((muscleGroup) => 
             _buildMuscleGroupCard(muscleGroup, themeService)
           ),

          const SizedBox(height: 24),

          // Recovery tips
          _buildRecoveryTips(themeService),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeService.isDarkMode 
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recovery Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeService.currentTheme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          _buildLegendItem('Ready (80-100%)', 0xFF4CAF50, themeService),
          _buildLegendItem('Moderate (60-79%)', 0xFFFF9800, themeService),
          _buildLegendItem('Needs Rest (40-59%)', 0xFFFF5722, themeService),
          _buildLegendItem('Rest Required (0-39%)', 0xFFF44336, themeService),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int color, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Color(color),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: themeService.currentTheme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryRatesLegend(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeService.isDarkMode 
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.bolt,
                color: Colors.blue.shade400,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Recovery Rate Guide',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeService.currentTheme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRecoveryRateLegendItem('Fast Recovery (24-48h)', 'Forearms, Calves, Core, Neck', 'High blood flow, endurance fibers', Colors.green, themeService),
          _buildRecoveryRateLegendItem('Moderate Recovery (48-72h)', 'Biceps, Triceps, Shoulders', 'Small muscles, fast-twitch fibers', Colors.blue, themeService),
          _buildRecoveryRateLegendItem('Slow Recovery (72-96h)', 'Chest, Back, Legs, Glutes', 'Large muscles, high fatigue', Colors.orange, themeService),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.lightbulb,
                      color: Colors.blue.shade600,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recovery rates vary by muscle fiber composition and exercise type.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Compound exercises (squats, deadlifts) slow recovery by 15-30%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Post-workout recovery starts at 5-50% based on exercise intensity',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryRateLegendItem(String category, String muscles, String explanation, Color color, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$category - $muscles',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeService.currentTheme.textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  explanation,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostWorkoutRecoveryGuide(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeService.isDarkMode 
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.clock,
                color: Colors.purple.shade400,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Post-Workout Recovery Guide',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeService.currentTheme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPostWorkoutItem('Max Effort (Deadlifts, Squats)', '5-15% recovery', 'Extreme fatigue, heavy loads', Colors.red, themeService),
          _buildPostWorkoutItem('Heavy Compound (Bench, Rows)', '10-25% recovery', 'High fatigue, moderate loads', Colors.orange, themeService),
          _buildPostWorkoutItem('Moderate Isolation (Curls, Extensions)', '20-40% recovery', 'Moderate fatigue, lighter loads', Colors.yellow, themeService),
          _buildPostWorkoutItem('Light Work (Core, Mobility)', '50-80% recovery', 'Minimal fatigue, very light loads', Colors.green, themeService),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.lightbulb,
                  color: Colors.purple.shade600,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recovery starts immediately after training and gradually improves over 48-72 hours based on exercise intensity and muscle group.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostWorkoutItem(String exerciseType, String recovery, String explanation, Color color, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$exerciseType - $recovery',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeService.currentTheme.textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  explanation,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFatigueLegend(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeService.isDarkMode 
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.gaugeHigh,
                color: Colors.orange.shade400,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Fatigue Score Guide',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeService.currentTheme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFatigueLegendItem('0.0 - 1.0', 'Low Volume', 'Normal recovery', Colors.green, themeService),
          _buildFatigueLegendItem('1.0 - 1.5', 'Moderate Volume', 'Normal recovery', Colors.blue, themeService),
          _buildFatigueLegendItem('1.5 - 2.0', 'High Volume', 'Recovery slowed by 20%', Colors.orange, themeService),
          _buildFatigueLegendItem('2.0+', 'Very High Volume', 'Recovery slowed by 20%', Colors.red, themeService),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.lightbulb,
                      color: Colors.orange.shade600,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fatigue scores > 1.5 indicate potential overtraining and will slow recovery rates.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Weekly Baselines: Chest 12k, Back 15k, Legs 20k, Shoulders 8k, Arms 6k',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFatigueLegendItem(String range, String level, String effect, Color color, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$range - $level',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeService.currentTheme.textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  effect,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableBaselineItem(MuscleGroup muscleGroup, ThemeService themeService) {
    final bodyWeight = recoveryData?.bodyWeight;
    
    final currentBaseline = bodyWeight != null && bodyWeight > 0
        ? RecoveryCalculator.getWeightAdjustedBaseline(
            muscleGroup.name, 
            bodyWeight,
            customBaselines: recoveryData?.customBaselines
          )
        : RecoveryCalculator.getBaselineVolume(
            muscleGroup.name, 
            customBaselines: recoveryData?.customBaselines
          );
    
    final isCustom = recoveryData?.customBaselines.containsKey(muscleGroup.name) ?? false;
    final isWeightAdjusted = bodyWeight != null && bodyWeight > 0 && !isCustom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.ruler,
              size: 12,
              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Weekly Baseline',
                style: TextStyle(
                  fontSize: 12,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCustom) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Custom',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else if (isWeightAdjusted) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Weight',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showBaselineEditor(muscleGroup.name, currentBaseline),
          child: Row(
            children: [
              Text(
                currentBaseline.toInt().toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeService.currentTheme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(width: 4),
              FaIcon(
                isCustom ? FontAwesomeIcons.rotateLeft : FontAwesomeIcons.penToSquare,
                size: 10,
                color: isCustom 
                    ? Colors.blue.shade600 
                    : (themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBaselineEditor(String muscleGroup, double currentBaseline) {
    final controller = TextEditingController(text: currentBaseline.toInt().toString());
    
    // Calculate default weight-adjusted baseline
    final bodyWeight = recoveryData?.bodyWeight;
    final defaultBaseline = bodyWeight != null && bodyWeight > 0
        ? RecoveryCalculator.getWeightAdjustedBaseline(muscleGroup, bodyWeight)
        : RecoveryCalculator.getBaselineVolume(muscleGroup);
    
    final isCustom = recoveryData?.customBaselines.containsKey(muscleGroup) ?? false;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $muscleGroup Baseline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly baseline volume affects fatigue score calculation:',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '• Higher baseline = Lower fatigue scores\n'
              '• Lower baseline = Higher fatigue scores\n'
              '• Fatigue score = Weekly volume ÷ Baseline\n'
              '• Baselines represent typical weekly training volumes\n'
              '• Values are automatically adjusted for body weight\n'
              '• Heavier individuals can handle more training volume',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weekly Baseline Volume',
                border: OutlineInputBorder(),
              ),
            ),
            if (isCustom) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.rotateLeft,
                          size: 14,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Default Weight-Adjusted Baseline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${defaultBaseline.toInt()} (based on your body weight)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (isCustom)
            TextButton(
              onPressed: () async {
                await RecoveryService.removeCustomBaseline(muscleGroup);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _refreshData(); // Refresh to show updated values
                }
              },
              child: Text(
                'Reset to Default',
                style: TextStyle(color: Colors.blue.shade600),
              ),
            ),
          TextButton(
            onPressed: () async {
              final newBaseline = double.tryParse(controller.text);
              if (newBaseline != null && newBaseline > 0) {
                await RecoveryService.updateCustomBaseline(muscleGroup, newBaseline);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _refreshData(); // Refresh to show updated values
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGroupCard(MuscleGroup muscleGroup, ThemeService themeService) {
    final recoveryStatus = RecoveryCalculator.getRecoveryStatus(muscleGroup.recoveryPercentage);
    final recoveryColor = RecoveryCalculator.getRecoveryColor(muscleGroup.recoveryPercentage);
    final hoursSinceLastTrained = DateTime.now().difference(muscleGroup.lastTrained).inHours;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeService.isDarkMode 
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: themeService.isDarkMode 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  muscleGroup.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeService.currentTheme.textTheme.titleLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(recoveryColor).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(recoveryColor)),
                ),
                child: Text(
                  recoveryStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(recoveryColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Recovery progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recovery',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${muscleGroup.recoveryPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(recoveryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: muscleGroup.recoveryPercentage / 100,
                backgroundColor: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Color(recoveryColor)),
                minHeight: 8,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Additional info
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Last Trained',
                      _formatTimeAgo(hoursSinceLastTrained),
                      FontAwesomeIcons.clock,
                      themeService,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Fatigue Score',
                      muscleGroup.fatigueScore.toStringAsFixed(1),
                      FontAwesomeIcons.gaugeHigh,
                      themeService,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                                Expanded(
                child: _buildEditableBaselineItem(
                  muscleGroup,
                  themeService,
                ),
              ),
                  Expanded(
                    child: Container(), // Empty space for alignment
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(
              icon,
              size: 12,
              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: themeService.currentTheme.textTheme.bodyMedium?.color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRecoveryTips(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeService.isDarkMode 
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.lightbulb,
                color: Colors.blue.shade400,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Recovery Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeService.currentTheme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Focus on muscle groups with low recovery percentages', themeService),
          _buildTip('Consider rest days for overworked muscle groups', themeService),
          _buildTip('Fatigue scores > 1.5 indicate overtraining and slow recovery', themeService),
          _buildTip('Recovery improves exponentially over time', themeService),
          _buildTip('Monitor fatigue scores to prevent overtraining', themeService),
          _buildTip('Customize baseline volumes to match your training capacity', themeService),
        ],
      ),
    );
  }

  Widget _buildTip(String tip, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: themeService.currentTheme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatTimeAgo(int hours) {
    if (hours < 24) {
      return '${hours}h ago';
    } else {
      final days = hours ~/ 24;
      return '${days}d ago';
    }
  }
} 