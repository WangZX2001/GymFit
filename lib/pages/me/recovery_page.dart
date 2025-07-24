import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/recovery.dart';
import 'package:gymfit/services/recovery_service.dart';
import 'package:gymfit/services/theme_service.dart';
import 'package:gymfit/pages/me/recovery_help_page.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> with AutomaticKeepAliveClientMixin, RouteAware {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    RecoveryService.removeRecoveryUpdateListener(_onRecoveryUpdate);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshData();
  }

  @override
  void didPush() {
    _refreshData();
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: themeService.currentTheme.appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Recovery Help',
            onPressed: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => const RecoveryHelpPage(),
                ),
              );
            },
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
    final parentMuscleGroups = [
      'Arms',
      'Back',
      'Cardio',
      'Chest',
      'Core',
      'Glutes',
      'Legs',
      'Shoulders',
    ];
    // Map by name for fast lookup
    final Map<String, MuscleGroup> groupMap = {
      for (final mg in recoveryData!.muscleGroups) mg.name: mg
    };
    // Ensure all parent groups are present
    final now = DateTime.now();
    final muscleGroups = parentMuscleGroups.map((name) {
      if (groupMap.containsKey(name)) {
        return groupMap[name]!;
      } else {
        return MuscleGroup(
          name: name,
          recoveryPercentage: 100.0,
          lastTrained: now.subtract(const Duration(days: 30)),
          trainingLoad: 0.0,
          fatigueScore: 0.0,
        );
      }
    }).toList();
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
                  'Last updated:   ${_formatDateTime(recoveryData!.lastUpdated)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
                    fontWeight: FontWeight.w500,
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
                      fontWeight: FontWeight.w500,
                      color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${muscleGroup.recoveryPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

          // Next optimal training window
          Builder(
            builder: (context) {
              final now = DateTime.now();
              final hoursSinceLastTrained = now.difference(muscleGroup.lastTrained).inHours.toDouble();
              // Use the most recent exercise type for this muscle group if available
              final recentExerciseType = recoveryData?.recentExerciseTypes?[muscleGroup.name] ?? 'Bench Press';
              final hoursTo80 = RecoveryCalculator.estimateHoursToRecoveryThreshold(
                currentRecovery: muscleGroup.recoveryPercentage,
                fatigueScore: muscleGroup.fatigueScore,
                muscleGroup: muscleGroup.name,
                lastTrainedHoursAgo: hoursSinceLastTrained,
                threshold: 80.0,
                exerciseType: recentExerciseType,
              );
              if (hoursTo80 == null) {
                return const SizedBox.shrink();
              } else if (hoursTo80 <= 0 && muscleGroup.recoveryPercentage >= 80) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Ready for optimal training now',
                        style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              } else {
                final hours = hoursTo80.ceil();
                final days = hours ~/ 24;
                final remHours = hours % 24;
                String timeStr = days > 0
                    ? (remHours > 0 ? '$days d $remHours h' : '$days d')
                    : '$remHours h';
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.blue, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Next optimal training window: In $timeStr',
                        style: TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }
            },
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
                  fontWeight: FontWeight.w500,
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
            fontWeight: FontWeight.w500,
            color: themeService.currentTheme.textTheme.bodyMedium?.color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showBaselineEditor(muscleGroup.name, currentBaseline),
                      child: Row(
                        children: [
                          Text(
                            'Weekly Baseline',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: FaIcon(
                              isCustom ? FontAwesomeIcons.rotateLeft : FontAwesomeIcons.penToSquare,
                              size: 16,
                              color: isCustom
                                  ? (themeService.isDarkMode ? Colors.lightBlueAccent : Colors.blue.shade700)
                                  : (themeService.isDarkMode ? Colors.blueGrey[200] : Colors.blueGrey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Remove GestureDetector from value row
        Row(
          children: [
            Text(
              currentBaseline.toInt().toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: themeService.currentTheme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                if (isCustom) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade600,
                        side: BorderSide(color: Colors.blue.shade600, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        await RecoveryService.removeCustomBaseline(muscleGroup);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          _refreshData();
                        }
                      },
                      child: const Text('Reset to Default', textAlign: TextAlign.center),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final newBaseline = double.tryParse(controller.text);
                      if (newBaseline != null && newBaseline > 0) {
                        await RecoveryService.updateCustomBaseline(muscleGroup, newBaseline);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          _refreshData();
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
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