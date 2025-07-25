import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class WaterTab extends StatefulWidget {
  const WaterTab({super.key});

  @override
  State<WaterTab> createState() => _WaterTabState();
}

class _WaterTabState extends State<WaterTab> {
  int targetVolume = 1000;
  int bottleVolume = 500;
  List<Map<String, dynamic>> waterLog = [];

  int get totalDrank =>
      waterLog.fold(0, (sum, log) => sum + log['volume'] as int);
  double get progressPercent => (totalDrank / targetVolume).clamp(0.0, 1.0);

  void _editTargetVolume() {
    _showEditDialog(
      title: "Edit Target Volume",
      initialValue: targetVolume,
      onSubmitted: (value) {
        setState(() {
          targetVolume = value;
        });
      },
    );
  }

  void _editBottleVolume() {
    _showEditDialog(
      title: "Edit Bottle Volume",
      initialValue: bottleVolume,
      onSubmitted: (value) {
        setState(() {
          bottleVolume = value;
        });
      },
    );
  }

  void _showEditDialog({
    required String title,
    required int initialValue,
    required void Function(int) onSubmitted,
  }) {
    final controller = TextEditingController(text: initialValue.toString());

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Enter value in ml"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value != null && value > 0) {
                    onSubmitted(value);
                  }
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  void _addOneBottle() async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    setState(() {
      waterLog.add({
        'volume': bottleVolume,
        'time': DateFormat('HH:mm').format(now),
      });
    });

    final prefs =await SharedPreferences.getInstance();

    // Update today's date for log reset purposes
    await prefs.setString('lastLogDate', todayStr);

    // Prevent showing popup more than once per day
    final goalPopupShownDate = prefs.getString('goalPopupShownDate');
    final hasAlreadyShownToday = goalPopupShownDate == todayStr;

    if (totalDrank >= targetVolume && !hasAlreadyShownToday) {
      _showGoalReachedDialog();
      await prefs.setString('goalPopupShownDate', todayStr); // Mark as shown
    }
  }

  void _showGoalReachedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("🎉 Good Job!", textAlign: TextAlign.center),
            content: const Text(
              "You've reached your daily water target!",
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    
    final textStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: themeService.currentTheme.textTheme.titleMedium?.color,
    );

    final valueStyle = TextStyle(
      fontSize: 16,
      color: const Color(0xFF5BD0EF),
      fontWeight: FontWeight.bold,
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Progress + Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Vertical Progress Bar
              Column(
                children: [
                  Text(
                    '$totalDrank ml',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 16,
                    height: 150,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: progressPercent,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                progressPercent >= 1.0
                                    ? Colors.green
                                    : Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Goal',
                    style: TextStyle(
                      fontSize: 12, 
                      color: themeService.currentTheme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 30),

              // Image + Values
              Column(
                children: [
                  Image.asset('lib/images/water.png', height: 153, width: 153),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text("Target", style: textStyle),
                          Row(
                            children: [
                              Text('$targetVolume ml', style: valueStyle),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _editTargetVolume,
                                child: Icon(
                                  Icons.edit, 
                                  size: 20,
                                  color: themeService.currentTheme.iconTheme.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Column(
                        children: [
                          Text("One Bottle", style: textStyle),
                          Row(
                            children: [
                              Text('$bottleVolume ml', style: valueStyle),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _editBottleVolume,
                                child: Icon(
                                  Icons.edit, 
                                  size: 20,
                                  color: themeService.currentTheme.iconTheme.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Add One Bottle Button
          ElevatedButton(
            onPressed: _addOneBottle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 14.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Add One Bottle',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),

          const SizedBox(height: 60),

          // Record Header
          Container(
            color: isDark ? Colors.grey[700] : Colors.grey[300],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment, 
                  size: 20,
                  color: themeService.currentTheme.iconTheme.color,
                ),
                const SizedBox(width: 8),
                Text(
                  'Record', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeService.currentTheme.textTheme.titleMedium?.color,
                  ),
                ),
              ],
            ),
          ),

          // Record Entries with delete button
          ...waterLog.asMap().entries.toList().reversed.map((entry) {
            final index = entry.key;
            final log = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${log['volume']}ml',
                      style: const TextStyle(color: Colors.blue),
                    ),
                    Row(
                      children: [
                        Text(
                          log['time'],
                          style: TextStyle(
                            color: themeService.currentTheme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              waterLog.removeAt(index);
                            });
                          },
                          child: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
