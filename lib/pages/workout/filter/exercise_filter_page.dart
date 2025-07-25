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
    'Arms',
    'Back',
    'Cardio',
    'Chest',
    'Core',
    'Glutes',
    'Legs',
    'Shoulders',
  ];

  final Map<String, List<String>> muscleSubGroups = {
    'Back': ['Lats', 'Lower Back', 'Neck', 'Traps', 'Upper Back'],
    'Arms': ['Biceps', 'Forearms', 'Triceps'],
    'Legs': ['Adductors', 'Calves', 'Hamstring', 'Quadriceps'],
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
    
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: themeService.currentTheme.textTheme.titleMedium?.color,
          ),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: selected.isEmpty 
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
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  Widget _buildExperienceSection() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Text(
          'Experience Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: themeService.currentTheme.textTheme.titleMedium?.color,
          ),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: selectedExperienceLevels.isEmpty 
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
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  Widget _buildEquipmentSection() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Text(
          'Equipment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: themeService.currentTheme.textTheme.titleMedium?.color,
          ),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: selectedEquipment.isEmpty 
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
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
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
                  const Divider(height: 1),
                  _buildExperienceSection(),
                  const Divider(height: 1),
                  _buildEquipmentSection(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context, _getFilterResults());
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
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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