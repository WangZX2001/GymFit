import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class ExperienceLevelSelectionPage extends StatefulWidget {
  final Set<String> initialSelected;
  
  const ExperienceLevelSelectionPage({
    super.key,
    required this.initialSelected,
  });

  @override
  State<ExperienceLevelSelectionPage> createState() => _ExperienceLevelSelectionPageState();
}

class _ExperienceLevelSelectionPageState extends State<ExperienceLevelSelectionPage> {
  late Set<String> selectedLevels;

  final List<String> experienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  final Map<String, String> levelDescriptions = {
    'Beginner': 'New to fitness or this exercise type',
    'Intermediate': 'Some experience with fitness and exercises',
    'Advanced': 'Experienced with complex movements and high intensity',
  };

  final Map<String, IconData> levelIcons = {
    'Beginner': FontAwesomeIcons.seedling,
    'Intermediate': FontAwesomeIcons.chartLine,
    'Advanced': FontAwesomeIcons.trophy,
  };

  @override
  void initState() {
    super.initState();
    selectedLevels = Set.from(widget.initialSelected);
  }

  void _toggleSelection(String level) {
    setState(() {
      if (selectedLevels.contains(level)) {
        selectedLevels.remove(level);
      } else {
        selectedLevels.add(level);
      }
    });
  }

  void _selectAll() {
    setState(() {
      selectedLevels = Set.from(experienceLevels);
    });
  }

  void _clearAll() {
    setState(() {
      selectedLevels.clear();
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
          'Experience Level',
          style: themeService.currentTheme.appBarTheme.titleTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: selectedLevels.isEmpty ? null : _clearAll,
            child: Text(
              'Clear',
              style: TextStyle(
                color: selectedLevels.isEmpty ? Colors.grey : Colors.red,
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
                'All Levels',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: themeService.currentTheme.textTheme.titleMedium?.color,
                ),
              ),
              subtitle: Text(
                'Include exercises for all experience levels',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              value: selectedLevels.length == experienceLevels.length,
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
          // Individual experience levels
          Expanded(
            child: ListView.separated(
              itemCount: experienceLevels.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final level = experienceLevels[index];
                final isSelected = selectedLevels.contains(level);
                
                return Container(
                  color: themeService.isDarkMode 
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade50,
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                    title: Row(
                      children: [
                        FaIcon(
                          levelIcons[level],
                          color: isSelected ? Colors.blue : (themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            level,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: themeService.currentTheme.textTheme.titleMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      levelDescriptions[level] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      _toggleSelection(level);
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
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            child: Column(
              children: [
                if (selectedLevels.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      '${selectedLevels.length} level${selectedLevels.length == 1 ? '' : 's'} selected',
                      style: TextStyle(
                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, selectedLevels.toList());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeService.isDarkMode ? Colors.white : Colors.black,
                      foregroundColor: themeService.isDarkMode ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Apply Selection',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w700,
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