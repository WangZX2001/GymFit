import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/pages/workout/filter/muscle_group_selection_page.dart';
import 'package:gymfit/pages/workout/filter/experience_level_selection_page.dart';
import 'package:gymfit/pages/workout/filter/equipment_selection_page.dart';
import 'package:gymfit/services/theme_service.dart';

class ExerciseFilterPage extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  
  const ExerciseFilterPage({super.key, this.initialFilters});

  @override
  State<ExerciseFilterPage> createState() => _ExerciseFilterPageState();
}

class _ExerciseFilterPageState extends State<ExerciseFilterPage> {
  Set<String> selectedMainMuscles = {};
  Set<String> selectedExperienceLevels = {};
  Set<String> selectedEquipment = {};

  // Define available filter options
  final List<String> mainMuscles = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
    'Glutes',
    'Cardio',
  ];

  final Map<String, List<String>> muscleSubGroups = {
    'Back': ['Upper Back', 'Lower Back', 'Traps', 'Neck', 'Lats'],
    'Arms': ['Biceps', 'Triceps'],
  };



  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      selectedMainMuscles = Set.from(widget.initialFilters!['mainMuscles'] ?? []);
      selectedExperienceLevels = Set.from(widget.initialFilters!['experienceLevels'] ?? []);
      selectedEquipment = Set.from(widget.initialFilters!['equipment'] ?? []);
    }
  }

  Widget _buildMuscleGroupSection(String title, List<String> options, Set<String> selected, Function(List<String>) onSelectionChanged) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    return Container(
      decoration: BoxDecoration(
        color: themeService.isDarkMode 
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: themeService.currentTheme.textTheme.titleMedium?.color,
          ),
        ),
                    subtitle: selected.isEmpty 
            ? Text(
                'None selected',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              )
            : Text(
                '${selected.length} selected: ${selected.take(2).join(', ')}${selected.length > 2 ? '...' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          size: 16,
          color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        onTap: () async {
          final result = await Navigator.push<List<String>>(
            context,
            MaterialPageRoute(
              builder: (context) => MuscleGroupSelectionPage(
                title: title,
                muscleGroups: options,
                initialSelected: selected,
                subGroups: title == 'Main Muscle' ? muscleSubGroups : null,
              ),
            ),
          );
          
          if (result != null) {
            onSelectionChanged(result);
          }
        },
      ),
    );
  }

  Widget _buildExperienceSection() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    return Container(
      decoration: BoxDecoration(
        color: themeService.isDarkMode 
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(
          'Experience Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: themeService.currentTheme.textTheme.titleMedium?.color,
          ),
        ),
        subtitle: selectedExperienceLevels.isEmpty 
            ? Text(
                'None selected',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              )
            : Text(
                '${selectedExperienceLevels.length} selected: ${selectedExperienceLevels.join(', ')}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          size: 16,
          color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        onTap: () async {
          final result = await Navigator.push<List<String>>(
            context,
            MaterialPageRoute(
              builder: (context) => ExperienceLevelSelectionPage(
                initialSelected: selectedExperienceLevels,
              ),
            ),
          );
          
          if (result != null) {
            setState(() {
              selectedExperienceLevels = Set.from(result);
            });
          }
        },
      ),
    );
  }

  Widget _buildEquipmentSection() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    return Container(
      decoration: BoxDecoration(
        color: themeService.isDarkMode 
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(
          'Equipment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: themeService.currentTheme.textTheme.titleMedium?.color,
          ),
        ),
        subtitle: selectedEquipment.isEmpty 
            ? Text(
                'None selected',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              )
            : Text(
                '${selectedEquipment.length} selected: ${selectedEquipment.take(2).join(', ')}${selectedEquipment.length > 2 ? '...' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          size: 16,
          color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        onTap: () async {
          final result = await Navigator.push<List<String>>(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentSelectionPage(
                initialSelected: selectedEquipment,
              ),
            ),
          );
          
          if (result != null) {
            setState(() {
              selectedEquipment = Set.from(result);
            });
          }
        },
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      selectedMainMuscles.clear();
      selectedExperienceLevels.clear();
      selectedEquipment.clear();
    });
  }

  Map<String, dynamic> _getFilterResults() {
    return {
      'mainMuscles': selectedMainMuscles.toList(),
      'experienceLevels': selectedExperienceLevels.toList(),
      'equipment': selectedEquipment.toList(),
    };
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
            Icons.close, 
            color: themeService.currentTheme.appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Filter Exercises',
          style: themeService.currentTheme.appBarTheme.titleTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              'Clear',
              style: TextStyle(
                color: Colors.red,
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
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMuscleGroupSection(
                      'Main Muscle',
                      mainMuscles,
                      selectedMainMuscles,
                      (selection) {
                        setState(() {
                          selectedMainMuscles = Set.from(selection);
                        });
                      },
                    ),
                    _buildExperienceSection(),
                    _buildEquipmentSection(),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            child: SizedBox(
              width: double.infinity,
                              child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _getFilterResults());
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
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w700,
                      color: themeService.isDarkMode ? Colors.black : Colors.white,
                    ),
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }
} 