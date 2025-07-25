import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class EquipmentSelectionPage extends StatefulWidget {
  final Set<String> initialSelected;
  
  const EquipmentSelectionPage({
    super.key,
    required this.initialSelected,
  });

  @override
  State<EquipmentSelectionPage> createState() => _EquipmentSelectionPageState();
}

class _EquipmentSelectionPageState extends State<EquipmentSelectionPage> {
  late Set<String> selectedEquipment;

  final List<String> equipmentTypes = [
    'Barbell',
    'Dumbbell',
    'Machine',
    'Cable',
    'Bodyweight',
    'Resistance Band',
    'Kettlebell',
    'Medicine Ball',
    'TRX',
    'Pull-up Bar',
    'Bench',
    'Smith Machine',
  ];

  final Map<String, String> equipmentDescriptions = {
    'Barbell': 'Olympic barbells and standard barbells',
    'Dumbbell': 'Free weights for unilateral training',
    'Machine': 'Weight machines and apparatus',
    'Cable': 'Cable machines and pulley systems',
    'Bodyweight': 'No equipment needed',
    'Resistance Band': 'Elastic resistance bands',
    'Kettlebell': 'Cast iron or steel weights',
    'Medicine Ball': 'Weighted balls for functional training',
    'TRX': 'Suspension training system',
    'Pull-up Bar': 'Fixed or doorway pull-up bars',
    'Bench': 'Flat, incline, or decline benches',
    'Smith Machine': 'Guided barbell system',
  };

  final Map<String, IconData> equipmentIcons = {
    'Barbell': FontAwesomeIcons.dumbbell,
    'Dumbbell': FontAwesomeIcons.dumbbell,
    'Machine': FontAwesomeIcons.gears,
    'Cable': FontAwesomeIcons.link,
    'Bodyweight': FontAwesomeIcons.person,
    'Resistance Band': FontAwesomeIcons.spa,
    'Kettlebell': FontAwesomeIcons.weightScale,
    'Medicine Ball': FontAwesomeIcons.baseball,
    'TRX': FontAwesomeIcons.linkSlash,
    'Pull-up Bar': FontAwesomeIcons.grip,
    'Bench': FontAwesomeIcons.couch,
    'Smith Machine': FontAwesomeIcons.industry,
  };

  @override
  void initState() {
    super.initState();
    selectedEquipment = Set.from(widget.initialSelected);
  }

  void _toggleSelection(String equipment) {
    setState(() {
      if (selectedEquipment.contains(equipment)) {
        selectedEquipment.remove(equipment);
      } else {
        selectedEquipment.add(equipment);
      }
    });
  }

  void _selectAll() {
    setState(() {
      selectedEquipment = Set.from(equipmentTypes);
    });
  }

  void _clearAll() {
    setState(() {
      selectedEquipment.clear();
    });
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Equipment',
          style: themeService.currentTheme.appBarTheme.titleTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: selectedEquipment.isEmpty ? null : _clearAll,
            child: Text(
              'Clear',
              style: TextStyle(
                color: selectedEquipment.isEmpty ? Colors.grey : Colors.red,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          // Select All option
          Container(
            color: themeService.isDarkMode 
                ? const Color(0xFF2A2A2A)
                : Colors.grey.shade50,
            child: CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
              title: Text(
                'All Equipment',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: themeService.currentTheme.textTheme.titleMedium?.color,
                ),
              ),
              subtitle: Text(
                'Include exercises for all equipment types',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              value: selectedEquipment.length == equipmentTypes.length,
              tristate: true,
              onChanged: (bool? value) {
                if (value == true) {
                  _selectAll();
                } else {
                  _clearAll();
                }
              },
              activeColor: Colors.blue,
            ),
          ),
          const Divider(height: 1),
          // Individual equipment types
          Expanded(
            child: ListView.separated(
              itemCount: equipmentTypes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final equipment = equipmentTypes[index];
                final isSelected = selectedEquipment.contains(equipment);
                
                return Container(
                  color: themeService.isDarkMode 
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade50,
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                    title: Row(
                      children: [
                        FaIcon(
                          equipmentIcons[equipment],
                          color: isSelected ? Colors.blue : (themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            equipment,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: themeService.currentTheme.textTheme.titleMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      equipmentDescriptions[equipment] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      _toggleSelection(equipment);
                    },
                    activeColor: Colors.blue,
                  ),
                );
              },
            ),
          ),
          // Selected count and Apply button
          Container(
            color: themeService.isDarkMode 
                ? Colors.black
                : Colors.grey.shade50,
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 32.0),
            child: Column(
              children: [
                if (selectedEquipment.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      '${selectedEquipment.length} equipment type${selectedEquipment.length == 1 ? '' : 's'} selected',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, selectedEquipment.toList());
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: themeService.isDarkMode ? Colors.white : Colors.black,
                      foregroundColor: themeService.isDarkMode ? Colors.black : Colors.white,
                      side: BorderSide(
                        color: themeService.isDarkMode ? Colors.white : Colors.black,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Apply Selection',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: themeService.isDarkMode ? Colors.black : Colors.white,
                      ),
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
} 