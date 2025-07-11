import 'package:flutter/material.dart';
import 'package:gymfit/pages/workout/filter/muscle_group_selection_page.dart';
import 'package:gymfit/pages/workout/filter/experience_level_selection_page.dart';
import 'package:gymfit/pages/workout/filter/equipment_selection_page.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: selected.isEmpty 
            ? const Text('None selected')
            : Text('${selected.length} selected: ${selected.take(2).join(', ')}${selected.length > 2 ? '...' : ''}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: const Text(
          'Experience Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: selectedExperienceLevels.isEmpty 
            ? const Text('None selected')
            : Text('${selectedExperienceLevels.length} selected: ${selectedExperienceLevels.join(', ')}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: const Text(
          'Equipment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: selectedEquipment.isEmpty 
            ? const Text('None selected')
            : Text('${selectedEquipment.length} selected: ${selectedEquipment.take(2).join(', ')}${selectedEquipment.length > 2 ? '...' : ''}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Filter Exercises',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: const Text(
              'Clear',
              style: TextStyle(
                color: Colors.red,
                fontSize: 20,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
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
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 